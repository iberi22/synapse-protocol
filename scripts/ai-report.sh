#!/bin/bash
# ai-report.sh - Generate AI analysis reports for PRs
#
# Usage:
#   ./scripts/ai-report.sh [PR_NUMBER] [OPTIONS]
#
# Options:
#   --gemini       Only Gemini report
#   --copilot      Only Copilot report
#   --model MODEL  Copilot model (default: claude-sonnet-4.5)
#   --dry-run      Show report without posting
#
# Models available:
#   claude-sonnet-4.5, claude-opus-4.5, claude-haiku-4.5, gpt-5.1, gpt-5.1-codex
#
# Examples:
#   ./scripts/ai-report.sh              # Current branch PR, full report
#   ./scripts/ai-report.sh 42           # Specific PR
#   ./scripts/ai-report.sh --copilot --model claude-opus-4.5
#   ./scripts/ai-report.sh --dry-run    # Preview only

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${CYAN}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
error() { echo -e "${RED}❌ $*${NC}"; exit 1; }

# Parse arguments
PR_NUMBER=""
REPORT_TYPE="full"
MODEL="claude-sonnet-4.5"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --gemini) REPORT_TYPE="gemini"; shift ;;
        --copilot) REPORT_TYPE="copilot"; shift ;;
        --model) MODEL="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        [0-9]*) PR_NUMBER="$1"; shift ;;
        *) shift ;;
    esac
done

# Check dependencies
check_deps() {
    command -v gh >/dev/null 2>&1 || error "gh (GitHub CLI) not found"

    if [[ "$REPORT_TYPE" == "full" || "$REPORT_TYPE" == "gemini" ]]; then
        command -v gemini >/dev/null 2>&1 || error "gemini CLI not found"
    fi

    if [[ "$REPORT_TYPE" == "full" || "$REPORT_TYPE" == "copilot" ]]; then
        command -v copilot >/dev/null 2>&1 || error "copilot CLI not found (npm install -g @github/copilot)"
    fi
}

# Get current PR number
get_current_pr() {
    gh pr view --json number -q '.number' 2>/dev/null || echo ""
}

# Generate Gemini report
generate_gemini_report() {
    local diff="$1"
    local title="$2"
    local body="$3"

    info "Generating Gemini analysis..."

    local prompt="Analiza este Pull Request y genera un reporte técnico conciso en español.

## PR: $title

### Descripción
$body

### Cambios (Diff)
\`\`\`diff
${diff:0:8000}
\`\`\`

## Formato del Reporte

### 🔍 Resumen de Cambios
(Lista los cambios principales en bullets)

### 📊 Análisis de Impacto
(Evalúa el impacto: Alto/Medio/Bajo y explica por qué)

### ⚠️ Posibles Riesgos
(Lista riesgos potenciales o 'Ninguno identificado')

### ✅ Recomendaciones
(Sugerencias para el reviewer)"

    gemini -p "$prompt" -o text 2>/dev/null || echo "Error generating Gemini report"
}

# Generate Copilot report (new agentic CLI with Claude Sonnet 4.5)
generate_copilot_report() {
    local diff="$1"
    local title="$2"
    local body="$3"
    local model="$4"

    info "Generating Copilot analysis (model: $model)..."

    # Truncate diff if too long
    local truncated_diff="${diff:0:6000}"
    if [[ ${#diff} -gt 6000 ]]; then
        truncated_diff="$truncated_diff
... [diff truncated]"
    fi

    local prompt="Analiza este Pull Request y genera un reporte técnico conciso en español.

## PR: $title

### Descripción
$body

### Cambios (Diff)
$truncated_diff

## Genera un reporte con:
1. **Resumen de Cambios** (bullets concisos)
2. **Análisis de Impacto** (Alto/Medio/Bajo con justificación)
3. **Posibles Riesgos** (o 'Ninguno identificado')
4. **Recomendaciones** para el reviewer
5. **Etiquetas Sugeridas** (bug, enhancement, breaking-change, etc.)

Sé directo y técnico. No uses markdown headers con #."

    copilot -p "$prompt" --model "$model" -s --allow-all-tools 2>/dev/null || echo "Error generating Copilot report"
}

# Main
check_deps

# Determine PR number
if [[ -z "$PR_NUMBER" ]]; then
    PR_NUMBER=$(get_current_pr)
    [[ -z "$PR_NUMBER" ]] && error "No PR found for current branch. Use: $0 <PR_NUMBER>"
fi

info "Analyzing PR #$PR_NUMBER..."

# Get PR data
PR_TITLE=$(gh pr view "$PR_NUMBER" --json title -q '.title')
PR_BODY=$(gh pr view "$PR_NUMBER" --json body -q '.body')
PR_DIFF=$(gh pr diff "$PR_NUMBER")
PR_STATS=$(gh pr view "$PR_NUMBER" --json additions,deletions,changedFiles -q '"\(.changedFiles) files | +\(.additions) -\(.deletions)"')

info "PR: $PR_TITLE"
info "Stats: $PR_STATS"

# Build report
REPORT="## 🤖 AI Analysis Report

> Generado automáticamente por Git-Core Protocol

"

if [[ "$REPORT_TYPE" == "full" || "$REPORT_TYPE" == "gemini" ]]; then
    GEMINI_REPORT=$(generate_gemini_report "$PR_DIFF" "$PR_TITLE" "$PR_BODY")
    REPORT+="### 🔮 Gemini Analysis

$GEMINI_REPORT

"
fi

if [[ "$REPORT_TYPE" == "full" || "$REPORT_TYPE" == "copilot" ]]; then
    COPILOT_REPORT=$(generate_copilot_report "$PR_DIFF" "$PR_TITLE" "$PR_BODY" "$MODEL")
    REPORT+="### 🤖 Copilot Analysis ($MODEL)

$COPILOT_REPORT

"
fi

REPORT+="---
*Report generated at $(date -u '+%Y-%m-%d %H:%M:%S UTC')*"

if [[ "$DRY_RUN" == true ]]; then
    warn "DRY RUN - Report preview:"
    echo ""
    echo "$REPORT"
else
    info "Posting report to PR #$PR_NUMBER..."

    TEMP_FILE=$(mktemp)
    echo "$REPORT" > "$TEMP_FILE"

    gh pr comment "$PR_NUMBER" --body-file "$TEMP_FILE"
    rm -f "$TEMP_FILE"

    success "Report posted to PR #$PR_NUMBER"
fi

success "Analysis complete!"
