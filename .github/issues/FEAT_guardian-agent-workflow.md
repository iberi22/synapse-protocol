---
title: "[Agent] Implement Guardian Agent - Auto-Merge Workflow"
labels:
  - enhancement
  - ai-agent
  - automation
  - copilot
assignees: []
---

## 🎯 Objetivo

Crear el workflow `guardian-agent.yml` que actúa como el último gate antes del merge, decidiendo automáticamente si un PR puede ser merged o necesita escalación humana.

## 📋 Especificación

### Trigger Events
- `pull_request_review` - Cuando un review es submitted
- `check_suite` - Cuando los checks completan

### Condiciones para Auto-Merge

| Condición | Requerido | Peso |
|-----------|-----------|------|
| ✅ Todos los CI checks pasan | Sí | Bloqueante |
| ✅ CodeRabbit/Gemini review positivo | Sí | Bloqueante |
| ❌ No tiene label `high-stakes` | Sí | Bloqueante |
| ❌ No tiene label `needs-human` | Sí | Bloqueante |
| 📏 Cambios < 500 líneas | No | +10 confianza |
| 🎯 Scope único (un módulo) | No | +10 confianza |
| 🧪 Incluye tests | No | +15 confianza |

### Lógica de Decisión

```
IF all_checks_pass AND positive_review AND NOT high_stakes:
    IF confidence_score >= 70:
        → AUTO-MERGE (squash)
    ELSE:
        → REQUEST additional review
ELSE:
    → ESCALATE to human
    → Add label "needs-human"
    → Comment with reason
```

## ✅ Tareas

- [ ] Crear `.github/workflows/guardian-agent.yml`
- [ ] Implementar lógica de scoring
- [ ] Agregar comentario explicativo en PR
- [ ] Conectar con sistema de labels
- [ ] Tests del workflow

## 📁 Archivo a Crear

```yaml
# .github/workflows/guardian-agent.yml
name: 🛡️ Guardian Agent (Auto-Merge)

on:
  pull_request_review:
    types: [submitted]
  check_suite:
    types: [completed]
```

## 🔗 Dependencias

- Requiere: `codex-review.yml` funcionando
- Requiere: Labels `high-stakes`, `needs-human`
