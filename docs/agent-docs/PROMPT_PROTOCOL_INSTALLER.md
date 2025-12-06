---
title: "Git-Core Protocol Installation Prompt"
type: PROMPT
id: "prompt-protocol-installer"
created: 2025-01-21
updated: 2025-01-21
agent: copilot
model: claude-opus-4
requested_by: user
summary: |
  Interactive prompt for installing Git-Core Protocol with three modes:
  Observe (non-invasive), Hybrid (smart merge), Strict (full migration).
keywords: [protocol, installation, migration, modes]
tags: ["#protocol", "#installation", "#automation"]
project: git-core-protocol
module: installer
language: powershell
priority: high
status: approved
complexity: high
---

# 🚀 Git-Core Protocol Installation Prompt

## Para usar con tu agente de código (Copilot CLI, Gemini CLI, etc.)

### Comando sugerido:

```bash
# Con Copilot CLI
gh copilot suggest "Install Git-Core Protocol" -t shell

# Con Gemini CLI
gemini -p "$(cat docs/agent-docs/PROMPT_PROTOCOL_INSTALLER.md)" -o text
```

---

## 📋 PROMPT DE INSTALACIÓN

```markdown
# Git-Core Protocol - Asistente de Instalación Inteligente

Eres un asistente de instalación para el Git-Core Protocol v2.0.0.
Tu tarea es analizar el proyecto actual y guiar al usuario a través de una instalación personalizada.

## FASE 1: Análisis del Proyecto

Primero, ejecuta estos comandos para entender el contexto:

\`\`\`bash
# 1. Estructura del proyecto
tree -L 2 --dirsfirst 2>/dev/null || Get-ChildItem -Recurse -Depth 2 | Select-Object FullName

# 2. Archivos de planificación existentes
ls -la *.md 2>/dev/null || Get-ChildItem -Filter "*.md"

# 3. Estado de Git
git status --short
git remote -v

# 4. Issues existentes (si hay)
gh issue list --limit 10 2>/dev/null || echo "No GitHub CLI disponible"
\`\`\`

## FASE 2: Presentar Opciones

Después de analizar, presenta EXACTAMENTE estas 3 opciones:

---

### 🔍 Opción 1: OBSERVE (Solo Observar)

**Descripción:** El protocolo se ejecuta sin modificar nada existente.

**Qué hace:**
- Crea carpeta `.✨/` con archivos del protocolo
- NO modifica archivos existentes
- NO mueve ni renombra nada
- Coexiste con tu estructura actual

**Ideal para:**
- Probar el protocolo antes de comprometerse
- Proyectos legacy que no pueden cambiar
- Evaluar si el protocolo te conviene

**Archivos que se crearán:**
```
.✨/
├── ARCHITECTURE.md
├── AGENT_INDEX.md
└── protocol.config.json (mode: "observe")
```

---

### 🔀 Opción 2: HYBRID (Integración Inteligente)

**Descripción:** Integra el sistema de contexto preservando archivos útiles.

**Qué hace:**
- Crea estructura `.✨/` completa
- PRESERVA: TASK.md, PLANNING.md, RULES.md
- Crea un **PR con cambios propuestos** para review
- Permite merge selectivo de cambios

**Ideal para:**
- Proyectos activos con planificación existente
- Equipos que quieren transición gradual
- Cuando necesitas aprobar cambios antes

**Proceso:**
1. Analizo tu proyecto
2. Creo branch `protocol/hybrid-install`
3. Genero cambios propuestos
4. Creo PR para tu review
5. Tú decides qué mergear

**Archivos que se preservan:**
```
✅ TASK.md      → Se mantiene, se integra con Issues
✅ PLANNING.md  → Se mantiene, referenciado desde ARCHITECTURE
✅ RULES.md     → Se mantiene, complementa AGENTS.md
```

---

### ⚡ Opción 3: STRICT (Instalación Completa)

**Descripción:** Instalación completa con migración inteligente.

**Qué hace:**
- Análisis profundo del proyecto con IA
- Genera **lista de migraciones necesarias**
- Mueve/renombra archivos según protocolo
- Crea Issues de TODO.md, convierte PLANNING a Issues

**Ideal para:**
- Proyectos nuevos o greenfield
- Cuando quieres adopción completa
- Máxima compatibilidad con agentes AI

**Proceso:**
1. Escaneo completo del proyecto
2. Genero `MIGRATION_PLAN.md` (temporal, solo para review)
3. Presento lista de cambios propuestos
4. Pido confirmación antes de ejecutar
5. Ejecuto migraciones aprobadas
6. Elimino `MIGRATION_PLAN.md` después

**Ejemplo de migración generada:**
```yaml
migrations:
  - action: convert_to_issues
    source: TODO.md
    destination: github_issues
    items_detected: 12
    
  - action: move_file
    source: docs/roadmap.md
    destination: github_project_board
    
  - action: integrate
    source: PLANNING.md
    into: .✨/ARCHITECTURE.md
    section: "Planning Context"
    
  - action: create
    file: AGENTS.md
    content: protocol_default
    
  - action: configure
    file: .github/copilot-instructions.md
    changes: add_protocol_rules
```

---

## FASE 3: Ejecutar Opción Seleccionada

### Si elige Opción 1 (OBSERVE):

\`\`\`bash
# Crear estructura mínima
mkdir -p .✨

cat > .✨/protocol.config.json << 'EOF'
{
  "version": "2.0.0",
  "mode": "observe",
  "allowedRootFiles": {
    "TASK.md": true,
    "PLANNING.md": true,
    "RULES.md": true,
    "TODO.md": true
  },
  "notes": "Protocol running in observe mode - no modifications to existing files"
}
EOF

cat > .✨/ARCHITECTURE.md << 'EOF'
# Architecture (Observe Mode)

Protocol is observing but not modifying project structure.

## To upgrade to Hybrid or Strict mode:
Run the protocol installer again and choose a different option.
EOF

echo "✅ Observe mode installed. Protocol will not modify existing files."
\`\`\`

### Si elige Opción 2 (HYBRID):

\`\`\`bash
# Crear branch para PR
git checkout -b protocol/hybrid-install

# Crear estructura del protocolo
mkdir -p .✨
mkdir -p .github/instructions

# Generar config
cat > .✨/protocol.config.json << 'EOF'
{
  "version": "2.0.0",
  "mode": "hybrid",
  "allowedRootFiles": {
    "TASK.md": true,
    "PLANNING.md": true,
    "RULES.md": true,
    "TODO.md": false
  }
}
EOF

# Crear ARCHITECTURE.md con contenido del proyecto
# [El agente debe analizar el proyecto y generar contenido relevante]

# Commit y PR
git add .✨ .github
git commit -m "feat(protocol): install Git-Core Protocol in hybrid mode"
gh pr create --title "🔧 Install Git-Core Protocol (Hybrid Mode)" \
  --body "## Git-Core Protocol Installation

### Mode: Hybrid

This PR adds the Git-Core Protocol structure while preserving:
- ✅ TASK.md
- ✅ PLANNING.md  
- ✅ RULES.md

### Changes:
- Creates \`.✨/\` protocol directory
- Adds \`protocol.config.json\`
- Adds \`ARCHITECTURE.md\`

### Review:
Please review the proposed structure and merge when ready."
\`\`\`

### Si elige Opción 3 (STRICT):

\`\`\`bash
# IMPORTANTE: Primero generar plan de migración

echo "🔍 Analizando proyecto para migración..."

# El agente debe:
# 1. Listar todos los .md en root
# 2. Analizar contenido de cada uno
# 3. Detectar TODOs, tareas, notas
# 4. Proponer conversión a Issues

# Generar plan (ejemplo de output):
cat > .MIGRATION_PLAN.md << 'EOF'
# Migration Plan (Auto-generated - DELETE AFTER REVIEW)

## Files to Convert to GitHub Issues:
1. **TODO.md** → 8 issues detected
2. **BACKLOG.md** → 15 items to convert

## Files to Move:
1. docs/notes.md → Delete (convert to issue comments)
2. ROADMAP.md → GitHub Project Board

## Files to Preserve (Hybrid-compatible):
1. TASK.md ✅
2. PLANNING.md ✅

## New Files to Create:
1. AGENTS.md
2. .✨/ARCHITECTURE.md
3. .✨/protocol.config.json
4. .github/copilot-instructions.md

---
**¿Proceder con la migración?** [Esperar confirmación del usuario]
EOF

echo "📋 Plan generado en .MIGRATION_PLAN.md"
echo "Por favor revisa y confirma para continuar."
\`\`\`

## FASE 4: Confirmación y Limpieza

Después de cualquier instalación:

\`\`\`bash
# Verificar instalación
echo "✅ Git-Core Protocol v2.0.0 instalado"
echo "📁 Modo: [OBSERVE|HYBRID|STRICT]"
echo ""
echo "Próximos pasos:"
echo "1. Lee .✨/ARCHITECTURE.md"
echo "2. Configura tus agentes en AGENTS.md"
echo "3. Usa 'gh issue list' para ver tareas"
\`\`\`

---

## REGLAS PARA EL AGENTE

1. **SIEMPRE** presenta las 3 opciones antes de actuar
2. **NUNCA** ejecutes la Opción 3 sin confirmación explícita
3. **SIEMPRE** genera un plan de migración visible antes de ejecutar
4. **PRESERVA** archivos cuando el usuario no confirme eliminación
5. **USA** gh CLI para operaciones de GitHub cuando esté disponible
6. **REPORTA** cada acción antes de ejecutarla

## CONTEXTO DEL MODELO

Para mejor análisis, usa:
- **Claude Opus 4.5**: Para análisis profundo de arquitectura
- **Gemini 2.5 Pro**: Para escaneo de contexto grande (1M tokens)
- **GPT-5.1 Codex**: Para generación de código de migración

Comando para invocar con contexto completo:
\`\`\`bash
# Con Gemini (mejor para proyectos grandes)
gemini -p "Analiza este proyecto para instalación de Git-Core Protocol: $(find . -name '*.md' -exec cat {} \;)"

# Con Claude (mejor para decisiones de arquitectura)
# Usa VS Code con Claude Opus 4.5 para análisis interactivo
\`\`\`
```

---

## 🎯 Ejemplo de Uso Completo

```bash
# 1. Clonar repo con el protocolo
git clone https://github.com/iberi22/git-core-protocol-template

# 2. Ir al proyecto destino
cd mi-proyecto

# 3. Ejecutar instalador con tu agente preferido
gh copilot suggest "Run Git-Core Protocol installer from docs/agent-docs/PROMPT_PROTOCOL_INSTALLER.md"

# O con Gemini
gemini -f docs/agent-docs/PROMPT_PROTOCOL_INSTALLER.md -p "Install protocol in this project"
```

---

## 📚 Referencias

- Documentación completa: `AGENTS.md`
- Instrucciones de Copilot: `.github/copilot-instructions.md`
- Configuración del protocolo: `.✨/protocol.config.json`
