---
title: "Federated Telemetry - Scalability Analysis"
type: ANALYSIS
id: "analysis-telemetry-scale"
created: 2025-12-06
updated: 2025-12-06
agent: protocol-gemini
model: gemini-3-pro
requested_by: user
summary: |
  Analysis of telemetry system scalability. Proposes switching from
  PR-based to Discussion-based aggregation to handle 1000+ users.
keywords: [telemetry, scalability, architecture, discussions]
tags: ["#analysis", "#telemetry", "#scalability"]
protocol_version: 1.5.0
project: Git-Core-Protocol
---

# 📊 Análisis de Escalabilidad: Sistema de Telemetría Federada

## 1. Problema Identificado

El diseño actual crea **1 PR por usuario por semana**:

```
Usuario A → PR #101
Usuario B → PR #102
Usuario C → PR #103
...
Usuario N → PR #10N
```

### Proyección de Carga

| Usuarios Activos | PRs/Semana | PRs/Mes | PRs/Año |
|------------------|------------|---------|---------|
| 10 | 10 | 40 | 520 |
| 100 | 100 | 400 | 5,200 |
| 1,000 | 1,000 | 4,000 | 52,000 |
| 10,000 | 10,000 | 40,000 | **520,000** |

**Impacto:**
- ❌ Notificaciones excesivas para mantenedores
- ❌ GitHub Actions minutes consumidos
- ❌ Historial de PRs inutilizable
- ❌ Posible rate limiting de GitHub API
- ❌ Dificulta encontrar PRs "reales" (features, fixes)

---

## 2. Alternativas Evaluadas

### Opción A: GitHub Discussions (RECOMENDADA ✅)

```
┌─────────────────┐   API: createDiscussion   ┌─────────────────────┐
│  Tu Proyecto    │ ─────────────────────────▶│ Discussion Category │
│  (protocolo)    │                           │ "Telemetry Data"    │
└─────────────────┘                           └─────────────────────┘
                                                       │
                                                       │ Weekly Workflow
                                                       ▼
                                              ┌─────────────────────┐
                                              │ 1 Issue Agregado    │
                                              │ "[Evolution] Week X" │
                                              └─────────────────────┘
```

| Pros | Contras |
|------|---------|
| ✅ No contamina PRs | ⚠️ Requiere habilitar Discussions |
| ✅ Fácil de ignorar por usuarios | |
| ✅ API GraphQL eficiente | |
| ✅ Busqueda y filtrado nativo | |
| ✅ No requiere fork | |

### Opción B: Archivo Append-Only (JSON Lines)

```
telemetry/submissions/2025-W49.jsonl
```

Cada línea es un JSON independiente. Un workflow agrega al final.

| Pros | Contras |
|------|---------|
| ✅ Un solo archivo por semana | ❌ Conflictos de merge |
| ✅ Fácil de parsear | ❌ Crece indefinidamente |
| | ❌ Aún requiere PRs |

### Opción C: Issue con Comentarios

Un issue fijo `#TELEMETRY` donde cada usuario agrega un comentario.

| Pros | Contras |
|------|---------|
| ✅ Todo en un lugar | ❌ Issues no diseñados para esto |
| ✅ No requiere PRs | ❌ Puede volverse enorme |
| | ❌ Parsing de comentarios complejo |

### Opción D: Webhook Externo (Serverless)

```
Usuario → POST /api/telemetry → CloudFlare Worker → KV Store → Weekly Report
```

| Pros | Contras |
|------|---------|
| ✅ Máxima escalabilidad | ❌ Infraestructura externa |
| ✅ Procesamiento en tiempo real | ❌ Dependencia de terceros |
| ✅ Dashboards en vivo | ❌ Costos potenciales |

### Opción E: GitHub Gist

Cada usuario crea un Gist, el workflow los descubre y agrega.

| Pros | Contras |
|------|---------|
| ✅ Descentralizado | ❌ Difícil descubrir Gists |
| | ❌ No hay notificación |

---

## 3. Recomendación: GitHub Discussions

### Arquitectura Propuesta

```
┌──────────────────────────────────────────────────────────────────┐
│                     FLUJO DE TELEMETRÍA v2                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌───────────────┐                                              │
│   │ Proyecto A    │──┐                                           │
│   └───────────────┘  │                                           │
│                      │  gh api graphql                           │
│   ┌───────────────┐  │  (createDiscussion)                       │
│   │ Proyecto B    │──┼─────────────────────▶ Discussion:         │
│   └───────────────┘  │                      Category: "📊 Telemetry"
│                      │                      Title: "anon-abc123 Week 49"
│   ┌───────────────┐  │                      Body: { JSON metrics } │
│   │ Proyecto C    │──┘                                           │
│   └───────────────┘                                              │
│                                                                  │
│                           ║                                      │
│                           ║ WEEKLY (Lunes 9:00 UTC)              │
│                           ▼                                      │
│                                                                  │
│                   ┌───────────────────────┐                      │
│                   │  aggregate-telemetry  │                      │
│                   │      workflow         │                      │
│                   └───────────────────────┘                      │
│                           │                                      │
│                           │ 1. Lee todas las Discussions         │
│                           │ 2. Parsea JSON de cada una           │
│                           │ 3. Calcula promedios/totales         │
│                           │ 4. Detecta patrones                  │
│                           │ 5. Marca Discussions como "Answered" │
│                           │                                      │
│                           ▼                                      │
│                   ┌───────────────────────┐                      │
│                   │  1 Issue Agregado     │                      │
│                   │  "[Evolution] Week 49" │                      │
│                   │  • 47 proyectos       │                      │
│                   │  • Avg adoption: 72%  │                      │
│                   │  • Top friction: X    │                      │
│                   └───────────────────────┘                      │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Ventajas de esta Arquitectura

1. **Escalabilidad Infinita**
   - 10,000 discussions ≠ 10,000 PRs
   - Discussions no aparecen en PR feed
   - No consumen Actions minutes (solo lectura)

2. **Transparencia**
   - Cualquiera puede ver las submissions
   - Auditable públicamente

3. **Opt-Out Simple**
   - No ejecutar el workflow = no envío
   - Borrar tu Discussion = datos eliminados

4. **Eficiencia**
   - GraphQL permite batch queries
   - Un query puede traer 100 discussions

5. **Limpieza Automática**
   - Discussions "Answered" se archivan visualmente
   - Datos históricos se mantienen en Issues agregados

---

## 4. Implementación Técnica

### 4.1 Script Actualizado: `send-telemetry.ps1`

```powershell
# En lugar de crear PR, crea Discussion
$mutation = @"
mutation {
  createDiscussion(input: {
    repositoryId: "$REPO_ID"
    categoryId: "$TELEMETRY_CATEGORY_ID"
    title: "$projectId Week $weekNumber ($year)"
    body: "$jsonBody"
  }) {
    discussion { id url }
  }
}
"@

gh api graphql -f query="$mutation"
```

### 4.2 Workflow: `aggregate-telemetry.yml`

```yaml
name: Aggregate Telemetry
on:
  schedule:
    - cron: '0 10 * * 1'  # Lunes 10:00 UTC (después de submissions)
  workflow_dispatch:

jobs:
  aggregate:
    runs-on: ubuntu-latest
    steps:
      - name: Fetch all telemetry discussions
        run: |
          gh api graphql -f query='
            query {
              repository(owner: "iberi22", name: "Git-Core-Protocol") {
                discussions(categoryId: "$TELEMETRY_CATEGORY", first: 100) {
                  nodes {
                    id
                    title
                    body
                    createdAt
                  }
                }
              }
            }
          ' > discussions.json

      - name: Aggregate metrics
        run: |
          # Parse and aggregate all JSON bodies
          jq -s 'map(.order1) | add' discussions.json > aggregated.json

      - name: Create evolution issue
        run: |
          gh issue create --title "[Evolution] Week $WEEK" --body "..."

      - name: Mark discussions as answered
        run: |
          # Mark processed discussions to avoid re-processing
```

### 4.3 Categoría de Discussion Requerida

1. Ir a repo Settings → Discussions → Enable
2. Crear categoría: "📊 Telemetry Submissions"
3. Tipo: "Announcements" (solo mantenedores pueden crear... wait)

**Problema:** Solo mantenedores pueden crear Discussions tipo Announcement.

**Solución:** Usar tipo "General" o "Q&A" que permite a cualquiera crear.

---

## 5. Comparación Final

| Criterio | PRs (Actual) | Discussions (Propuesto) |
|----------|--------------|-------------------------|
| Escalabilidad | ❌ 1:1 | ✅ Agregado |
| Ruido en feed | ❌ Alto | ✅ Separado |
| Transparencia | ✅ Pública | ✅ Pública |
| Complejidad | ⚠️ Media | ⚠️ Media |
| Dependencias | Ninguna | Discussions habilitado |
| Rate limits | ⚠️ Riesgo | ✅ Bajo riesgo |

---

## 6. Plan de Migración

### Fase 1: Preparar Infraestructura
- [ ] Habilitar Discussions en el repo
- [ ] Crear categoría "📊 Telemetry Submissions"
- [ ] Obtener category ID para GraphQL

### Fase 2: Actualizar Scripts
- [ ] Modificar `send-telemetry.ps1` para crear Discussion
- [ ] Crear workflow `aggregate-telemetry.yml`
- [ ] Deprecar workflow `process-telemetry.yml`

### Fase 3: Documentar
- [ ] Actualizar `telemetry/README.md`
- [ ] Actualizar `EVOLUTION_PROTOCOL.md` sección 11

### Fase 4: Cleanup
- [ ] Eliminar `telemetry/submissions/` (ya no necesario)
- [ ] Cerrar PRs de telemetría existentes

---

## 7. Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Spam de Discussions | Baja | Medio | Labeling + moderation |
| API GraphQL cambia | Muy baja | Alto | Versionado de queries |
| Usuarios no adoptan | Media | Bajo | Opt-in, sin fricción |
| Datos inconsistentes | Media | Medio | Schema validation |

---

## 8. Conclusión

**Recomendación: Migrar de PRs a Discussions + Agregación Semanal**

Esta arquitectura permite escalar a **miles de usuarios** sin:
- Inundar el feed de PRs
- Consumir Actions minutes excesivos
- Requerir infraestructura externa
- Perder transparencia

El único requisito es habilitar Discussions en el repositorio.
