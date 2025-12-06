---
title: "[Agent] Implement Planner Agent - Autonomous Issue Creation"
labels:
  - enhancement
  - ai-agent
  - automation
  - copilot
assignees: []
---

## 🎯 Objetivo

Crear el workflow `planner-agent.yml` que genera automáticamente issues atómicos basándose en el roadmap del proyecto y el estado actual del desarrollo.

## 📋 Especificación

### Trigger Events
- `schedule` - Daily at 6 AM UTC
- `workflow_dispatch` - Manual con objetivo específico

### Input Sources

1. **ARCHITECTURE.md** - Roadmap y fases
2. **features.json** - Estado de features (passes: true/false)
3. **GitHub Issues** - Issues abiertos/cerrados
4. **Evolution Reports** - Métricas semanales

### Output

Issues atómicos con:
- Título descriptivo con prefijo de tipo
- Body con contexto y acceptance criteria
- Labels apropiados (`ai-agent`, tipo, prioridad)
- Estimación de complejidad

## 🧠 Lógica del Planner

```python
def plan():
    # 1. Read current state
    architecture = read_file(".✨/ARCHITECTURE.md")
    features = read_json(".✨/features.json")
    open_issues = gh_issue_list()

    # 2. Identify gaps
    current_phase = get_current_phase(architecture)
    incomplete_tasks = [f for f in features if not f.passes]

    # 3. Generate atomic issues
    for task in incomplete_tasks:
        if not has_existing_issue(task, open_issues):
            create_issue(
                title=f"[{task.type}] {task.description}",
                body=generate_body(task, architecture),
                labels=["ai-agent", task.type.lower()]
            )

    # 4. Dispatch to agents
    trigger_workflow("agent-dispatcher.yml")
```

## ✅ Tareas

- [ ] Crear `.github/workflows/planner-agent.yml`
- [ ] Crear `.✨/features.json` template
- [ ] Implementar parser de ARCHITECTURE.md
- [ ] Integrar con Gemini API (opcional fase 2)
- [ ] Tests del workflow

## 📁 Archivos a Crear

### `.github/workflows/planner-agent.yml`
```yaml
name: 🧠 Planner Agent

on:
  schedule:
    - cron: '0 6 * * *'
  workflow_dispatch:
    inputs:
      objective:
        description: 'Objective to plan'
```

### `.✨/features.json`
```json
{
  "version": "1.0.0",
  "features": [
    {
      "id": "core-entities",
      "phase": 1,
      "passes": false,
      "tests": ["tests/core/entities_test.rs"]
    }
  ]
}
```

## 🔗 Dependencias

- Requiere: `agent-dispatcher.yml` (ya existe)
- Requiere: `ARCHITECTURE.md` con roadmap
- Opcional: Gemini API key para generación inteligente
