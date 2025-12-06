```prompt
---
description: "📤 Exportar sesión para continuar en otra ventana"
---

# Exportar Sesión para Continuación

Genera un resumen estructurado de la sesión actual para continuar en otra ventana de chat.

## Paso 1: Recopilar Contexto

Ejecuta y analiza:

```powershell
# Estado actual
git status --porcelain
git branch --show-current
git log --oneline -5

# Issues y PRs
gh issue list --state open --limit 5 --json number,title
gh pr list --state open --limit 3 --json number,title,state

# Archivos modificados recientemente
git diff --stat HEAD~3
```

## Paso 2: Generar el Prompt de Continuación

Crea un archivo en `docs/prompts/SESSION_{fecha}_{topic}.md` con este formato:

```markdown
---
title: "Session Continuation - {topic}"
type: PROMPT
generated: {fecha} {hora}
generator: agent-export
project: {nombre-repo}
branch: {branch}
---

# 🔄 Session Continuation

## 📊 Estado al Exportar
- Branch: `{branch}`
- Archivos modificados: {N}
- Último commit: {mensaje}

## ✅ Lo que se completó
- {lista de tareas completadas}

## 🚧 Lo que falta
- {lista de tareas pendientes}

## 📋 Issues relacionados
- #{N}: {título}

## 📝 Contexto técnico
{detalles relevantes para continuar}

## 🎯 Siguiente acción recomendada
{acción específica para continuar}

---
*Usar en nueva ventana: `#file:docs/prompts/SESSION_xxx.md`*
*Eliminar después de usar*
```

## Paso 3: Copiar al Portapapeles e Informar

**CRÍTICO: Siempre copia la referencia al portapapeles.**

Ejecuta:
```powershell
"#file:docs/prompts/SESSION_{fecha}_{topic}.md" | Set-Clipboard
```

Muestra al usuario:
```
✅ Sesión exportada: docs/prompts/SESSION_{fecha}_{topic}.md

📋 **COPIADO AL PORTAPAPELES** (Ctrl+V para pegar):
   #file:docs/prompts/SESSION_{fecha}_{topic}.md

🔄 Para continuar:
   1. Abre una NUEVA ventana de chat
   2. Pega (Ctrl+V) → el texto ya está copiado
   3. ¡El agente tendrá el contexto completo!

🗑️ Recuerda eliminar el archivo después de usar
```

## Reglas Importantes

1. **SÍ incluir:** Estado git, issues abiertos, lo completado, lo pendiente, contexto técnico
2. **NO incluir:** Conversación completa, código extenso (solo referencias a archivos)
3. **Formato:** YAML frontmatter + markdown estructurado
4. **Eliminación:** El archivo es temporal, no documentación permanente
```
