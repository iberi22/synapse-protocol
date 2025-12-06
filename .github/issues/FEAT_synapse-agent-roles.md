---
title: "[Synapse] Define Specialized Agent Roles Based on Anthropic Research"
labels:
  - enhancement
  - ai-plan
  - synapse
  - documentation
assignees: []
---

## 🎯 Objetivo

Mapear los roles de investigación de Anthropic a agentes especializados para el desarrollo del Synapse Protocol, maximizando la automatización del proyecto.

## 📊 Mapping de Roles Anthropic → Synapse Agents

### Research Tier

| Rol Anthropic | Agent Synapse | Función |
|---------------|---------------|---------|
| Research Scientist (Interpretability) | `HIRAG_RESEARCHER` | Optimiza HiRAG layers |
| Research Scientist (Alignment) | `GENESIS_GUARDIAN` | Mantiene GenesisBlock ético |
| Research Engineer (Pre-training) | `METABOLIZER` | Optimiza Buffer → Memory |

### Systems Tier

| Rol Anthropic | Agent Synapse | Función |
|---------------|---------------|---------|
| ML Systems Engineer (RL) | `RWKV_TRAINER` | Fine-tuning RWKV |
| Performance Engineer | `CANDLE_OPTIMIZER` | Profiling inferencia |
| Staff Infrastructure Engineer | `LANCEDB_ARCHITECT` | Queries vectoriales |

### Agent Skills Tier

| Rol Anthropic | Agent Synapse | Función |
|---------------|---------------|---------|
| Staff ML Engineer (Agent Skills) | `IMMUNE_SYSTEM` | Digital Immune System |
| Staff ML Engineer (Virtual Collaborator) | `SYMBIONT` | Interacción humano-IA |
| Cross-functional Prompt Engineer | `DREAMER` | Prompts de consolidación |

### Data & Eval Tier

| Rol Anthropic | Agent Synapse | Función |
|---------------|---------------|---------|
| Data Operations Manager | `SANITIZER` | PII removal |
| Research Engineer (Model Evals) | `BENCHMARK_RUNNER` | Tests de calidad |

## ✅ Tareas

- [ ] Actualizar `AGENT_INDEX.md` con nuevos roles
- [ ] Crear labels para cada agent role
- [ ] Definir skill vectors para routing
- [ ] Documentar triggers y responsabilidades
- [ ] Crear templates de issues por rol

## 📁 Cambios Requeridos

### `.✨/AGENT_INDEX.md`
Agregar sección completa de "Synapse Specialized Agents"

### `.github/labels.yml` (o via workflow)
```yaml
labels:
  - name: "agent:hirag-researcher"
    color: "7057ff"
  - name: "agent:genesis-guardian"
    color: "d73a4a"
  - name: "agent:metabolizer"
    color: "0e8a16"
  # ... etc
```

## 🔗 Referencias

- Análisis original: `skins.md`
- Arquitectura: `.✨/ARCHITECTURE.md`
