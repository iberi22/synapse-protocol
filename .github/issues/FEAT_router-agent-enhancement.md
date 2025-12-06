---
title: "[Agent] Enhance Router Agent - Skill-Based Assignment"
labels:
  - enhancement
  - ai-agent
  - automation
assignees: []
---

## 🎯 Objetivo

Evolucionar el `agent-dispatcher.yml` actual de round-robin simple a un sistema de asignación basado en skills/especialización de cada agente.

## 📊 Estado Actual vs Objetivo

| Aspecto | Actual | Objetivo |
|---------|--------|----------|
| Estrategia | Round-robin / Random | Skill matching |
| Input | Solo labels | Labels + contenido del issue |
| Decisión | Determinística | Basada en embeddings |

## 🧠 Lógica de Skill Matching

```python
AGENT_SKILLS = {
    "copilot": {
        "vector": embed("rust, backend, systems, performance, core"),
        "strengths": ["synapse-core", "synapse-infra", "algorithms"]
    },
    "jules": {
        "vector": embed("ui, frontend, svelte, tauri, design"),
        "strengths": ["apps/desktop", "components", "styling"]
    }
}

def route_issue(issue):
    issue_vector = embed(issue.title + issue.body)

    scores = {}
    for agent, profile in AGENT_SKILLS.items():
        scores[agent] = cosine_similarity(issue_vector, profile.vector)

    best_agent = max(scores, key=scores.get)
    return best_agent
```

## ✅ Tareas

- [ ] Agregar embeddings a `agent-dispatcher.yml`
- [ ] Definir skill vectors por agente en `AGENT_INDEX.md`
- [ ] Implementar fallback a round-robin si embedding falla
- [ ] Logging de decisiones para análisis

## 📁 Cambios Requeridos

### `.github/workflows/agent-dispatcher.yml`
- Agregar step de embedding del issue
- Agregar step de skill matching
- Mantener fallback a estrategia actual

### `.✨/AGENT_INDEX.md`
- Agregar sección "Skill Vectors"
- Definir keywords por agente

## 🔗 Dependencias

- Requiere: API de embeddings (Gemini/OpenAI)
- Alternativa: Keywords matching simple (sin API)
