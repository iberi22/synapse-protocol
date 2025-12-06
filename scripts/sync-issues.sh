#!/bin/bash
# sync-issues.sh - Sincroniza issues locales (.md) con GitHub Issues
#
# Uso:
#   ./sync-issues.sh           # Sync completo (push + pull)
#   ./sync-issues.sh --push    # Solo crear issues desde .md
#   ./sync-issues.sh --pull    # Solo limpiar issues cerrados
#   ./sync-issues.sh --watch   # Modo watch continuo
#   ./sync-issues.sh --dry-run # No ejecutar, solo mostrar

set -e

ISSUES_DIR=".github/issues"
MAPPING_FILE=".github/issues/.issue-mapping.json"

# Colores
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err() { echo -e "${RED}❌ $1${NC}"; }

# Verificar dependencias
check_deps() {
    if ! command -v gh &> /dev/null; then
        err "GitHub CLI (gh) no está instalado"
        info "Instala con: brew install gh (macOS) o apt install gh (Linux)"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        err "jq no está instalado"
        info "Instala con: brew install jq (macOS) o apt install jq (Linux)"
        exit 1
    fi
}

# Inicializar mapping si no existe
init_mapping() {
    mkdir -p "$ISSUES_DIR"
    if [[ ! -f "$MAPPING_FILE" ]]; then
        echo "{}" > "$MAPPING_FILE"
    fi
}

# Obtener valor del mapping
get_mapping() {
    local key="$1"
    jq -r ".[\"$key\"] // empty" "$MAPPING_FILE"
}

# Establecer valor en el mapping
set_mapping() {
    local key="$1"
    local value="$2"
    local tmp=$(mktemp)
    jq ".[\"$key\"] = $value" "$MAPPING_FILE" > "$tmp" && mv "$tmp" "$MAPPING_FILE"
}

# Eliminar del mapping
del_mapping() {
    local key="$1"
    local tmp=$(mktemp)
    jq "del(.[\"$key\"])" "$MAPPING_FILE" > "$tmp" && mv "$tmp" "$MAPPING_FILE"
}

# Parsear frontmatter del archivo .md
parse_frontmatter() {
    local file="$1"
    local content=$(cat "$file")

    # Extraer título
    TITLE=$(echo "$content" | sed -n '/^---$/,/^---$/p' | grep -E '^title:' | sed 's/title:[[:space:]]*"\?\([^"]*\)"\?/\1/' | head -1)

    # Extraer labels
    LABELS=$(echo "$content" | sed -n '/^---$/,/^---$/p' | sed -n '/^labels:/,/^[a-z]/p' | grep -E '^\s*-' | sed 's/.*-[[:space:]]*"\?\([^"]*\)"\?/\1/' | tr '\n' ',' | sed 's/,$//')

    # Extraer body (todo después del segundo ---)
    BODY=$(echo "$content" | sed '1,/^---$/d' | sed '1,/^---$/d')

    # Si no hay título, usar nombre del archivo
    if [[ -z "$TITLE" ]]; then
        TITLE=$(basename "$file" .md | tr '_' ':' | tr '-' ' ')
    fi
}

# Crear issue desde archivo .md
create_issue_from_file() {
    local file="$1"
    local filename=$(basename "$file")

    parse_frontmatter "$file"

    if [[ -z "$TITLE" ]]; then
        warn "Archivo $filename sin título, saltando..."
        return 1
    fi

    info "Creando issue: $TITLE"

    if [[ "$DRY_RUN" == "true" ]]; then
        warn "[DRY-RUN] Se crearía: $TITLE"
        return 0
    fi

    # Construir comando
    local cmd="gh issue create --title \"$TITLE\""

    # Agregar labels
    if [[ -n "$LABELS" ]]; then
        IFS=',' read -ra LABEL_ARRAY <<< "$LABELS"
        for label in "${LABEL_ARRAY[@]}"; do
            label=$(echo "$label" | xargs)  # trim
            if [[ -n "$label" ]]; then
                cmd="$cmd --label \"$label\""
            fi
        done
    fi

    # Crear archivo temporal para body
    local tmp_body=$(mktemp)
    echo "$BODY" > "$tmp_body"
    cmd="$cmd --body-file \"$tmp_body\""

    # Ejecutar
    local result=$(eval $cmd 2>&1)
    rm -f "$tmp_body"

    # Extraer número del issue
    local issue_num=$(echo "$result" | grep -oE '/issues/[0-9]+' | grep -oE '[0-9]+')

    if [[ -n "$issue_num" ]]; then
        success "Issue #$issue_num creado: $result"
        set_mapping "$filename" "$issue_num"

        # Agregar número al archivo
        if ! grep -q "github_issue:" "$file"; then
            sed -i "s/^---$/---\ngithub_issue: $issue_num/" "$file"
        fi
        return 0
    else
        err "No se pudo crear el issue: $result"
        return 1
    fi
}

# Push: Crear issues desde archivos .md
do_push() {
    info "🔄 Sincronizando archivos .md → GitHub Issues..."

    local created=0

    for file in "$ISSUES_DIR"/*.md; do
        [[ -f "$file" ]] || continue

        local filename=$(basename "$file")

        # Saltar templates y archivos especiales
        [[ "$filename" == _* ]] && continue
        [[ "$filename" == ".gitkeep" ]] && continue

        # Verificar si ya existe en el mapeo
        local existing=$(get_mapping "$filename")
        if [[ -n "$existing" ]]; then
            [[ "$VERBOSE" == "true" ]] && info "  ⏭️  $filename ya mapeado a #$existing"
            continue
        fi

        if create_issue_from_file "$file"; then
            ((created++)) || true
        fi
    done

    success "Push completado: $created issues creados"
}

# Pull: Eliminar archivos de issues cerrados
do_pull() {
    info "🔄 Limpiando archivos de issues cerrados..."

    local deleted=0
    local keys=$(jq -r 'keys[]' "$MAPPING_FILE" 2>/dev/null)

    for filename in $keys; do
        local issue_num=$(get_mapping "$filename")

        # Verificar estado del issue
        local state=$(gh issue view "$issue_num" --json state --jq '.state' 2>/dev/null || echo "CLOSED")

        if [[ "$state" == "CLOSED" ]]; then
            local filepath="$ISSUES_DIR/$filename"

            if [[ "$DRY_RUN" == "true" ]]; then
                warn "[DRY-RUN] Se eliminaría: $filename (issue #$issue_num cerrado)"
            else
                if [[ -f "$filepath" ]]; then
                    rm -f "$filepath"
                    success "Eliminado: $filename (issue #$issue_num cerrado)"
                fi
                del_mapping "$filename"
            fi
            ((deleted++)) || true
        fi
    done

    success "Pull completado: $deleted archivos eliminados"
}

# Modo watch
do_watch() {
    info "👁️  Modo watch activado (Ctrl+C para salir)..."

    while true; do
        do_push
        do_pull
        info "Esperando 60 segundos..."
        sleep 60
    done
}

# Mostrar mapeo
show_mapping() {
    echo -e "\n${CYAN}📋 Mapeo actual:${NC}"
    local keys=$(jq -r 'keys[]' "$MAPPING_FILE" 2>/dev/null)

    if [[ -z "$keys" ]]; then
        info "  (vacío)"
    else
        for key in $keys; do
            local value=$(get_mapping "$key")
            echo -e "  ${key} → #${value}"
        done
    fi
}

# Main
main() {
    local PUSH=false
    local PULL=false
    local WATCH=false
    DRY_RUN=false
    VERBOSE=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --push) PUSH=true; shift ;;
            --pull) PULL=true; shift ;;
            --watch) WATCH=true; shift ;;
            --dry-run) DRY_RUN=true; shift ;;
            --verbose|-v) VERBOSE=true; shift ;;
            *) shift ;;
        esac
    done

    check_deps
    init_mapping

    if [[ "$WATCH" == "true" ]]; then
        do_watch
    elif [[ "$PUSH" == "true" && "$PULL" != "true" ]]; then
        do_push
    elif [[ "$PULL" == "true" && "$PUSH" != "true" ]]; then
        do_pull
    else
        do_push
        do_pull
    fi

    show_mapping
}

main "$@"
