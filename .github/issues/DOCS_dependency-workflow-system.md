---
github_issue: 47
title: "Documentar sistema de workflows de dependencias"
labels:
  - documentation
  - enhancement
  - workflow
protocol_version: 1.3.0
---
github_issue: 47

## 📋 Descripción

Documentar el sistema completo de workflows para manejo de dependencias siguiendo el protocolo Git-Core.

## 🏗️ Arquitectura del Sistema

```mermaid
graph TD
    subgraph "1️⃣ Entrada"
        A[Dependabot] -->|Crea PR| B[PR con label 'quarantine']
    end

    subgraph "2️⃣ Análisis Inicial"
        B --> C[dependency-quarantine.yml]
        C -->|Analiza con Gemini| D[Comentario con análisis AI]
        C --> E[Calcula fecha graduación]
    end

    subgraph "3️⃣ Centinela"
        F[dependency-sentinel.yml] -->|Monitorea| B
        F -->|Diario| G{¿14 días?}
        G -->|No| H[Sigue en cuarentena]
        G -->|Sí| I{¿Conflicto ARCHITECTURE?}
        I -->|Sí| J[Requiere revisión manual]
        I -->|No| K[Gradúa a 'ready-to-adopt']
    end

    subgraph "4️⃣ Post-Cuarentena"
        K --> L[post-quarantine-analysis.yml]
        L --> M[Análisis profundo]
        M --> N[Crea PR implementación]
    end

    subgraph "5️⃣ Adopción"
        N --> O{¿Aprobado?}
        O -->|Sí| P[Merge]
        O -->|No/3 días| Q[Auto-implementación]
        P --> R[living-context.yml]
        R --> S[Actualiza RESEARCH_STACK_CONTEXT.md]
    end

    subgraph "6️⃣ Validación"
        T[workflow-validator.yml] -->|Post-merge| U[Valida resultado]
        U --> V[Solicita reviews AI]
    end
```

## 📊 Workflows Involucrados

| Workflow | Función | Trigger |
|----------|---------|---------|
| `dependency-sentinel.yml` | 🛡️ **Cerebro central** - Orquesta todas las decisiones | PRs, schedule, workflow_run |
| `dependency-quarantine.yml` | 🔬 Análisis inicial con AI | PRs de Dependabot |
| `post-quarantine-analysis.yml` | 🔓 Análisis post-14 días | Schedule, workflow_call |
| `living-context.yml` | 🌐 Actualiza documentación | PRs mergeados, schedule |
| `workflow-validator.yml` | 🔬 Meta-validación | workflow_run |

## ✅ Tareas

- [ ] Añadir diagrama de flujo al README
- [ ] Crear sección en AGENTS.md sobre el Sentinel
- [ ] Documentar variables de entorno configurables
- [ ] Añadir ejemplos de uso manual

---
github_issue: 47

*Generado por análisis del sistema de workflows*
