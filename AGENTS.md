---
title: "Synapse Protocol - Agent Configuration"
type: CONFIGURATION
id: "config-synapse-agents"
created: 2025-12-02
updated: 2025-12-02
agent: copilot
model: claude-opus-4
requested_by: user
summary: |
  Agent rules and workflow for Synapse Protocol development.
keywords: [agents, rules, workflow, synapse]
tags: ["#configuration", "#agents", "#rules"]
project: synapse-protocol
---

# 🤖 AGENTS.md - Synapse Protocol

> **"Inteligente, sofisticada pero minimalista en complejidad"**

## Overview

This project follows the **Git-Core Protocol** for AI-assisted development.

---

## ⛔ FORBIDDEN FILES (HARD RULES)

**NEVER create these files:**
- ❌ TODO.md, TASKS.md, PLANNING.md, PROGRESS.md
- ❌ Any .md for task tracking

**✅ USE GitHub Issues instead** (`.github/issues/`)

---

## 🎯 Prime Directive

```
Your state is GitHub Issues. Not memory. Not files. GitHub Issues.
```

---

## 🤖 Agent Personas

### 🏗️ The Architect
- **Focus**: System design, Hexagonal boundaries, Trait definitions
- **Assigned**: Copilot (Claude Opus 4.5)

### 🦀 The Rustacean
- **Focus**: Performance, memory safety, async patterns
- **Assigned**: Copilot (Claude Sonnet 4)

### 🎨 The Designer
- **Focus**: UI/UX, Cyberpunk theme
- **Assigned**: **Jules** (Google)

---

## 📋 Issue Assignment Rules

| Task Type | Assignee | Labels |
|-----------|----------|--------|
| Core (entities, ports, logic) | `copilot` | `core`, `rust` |
| Infrastructure (adapters) | `copilot` | `infra`, `rust` |
| UI/UX (Tauri, Svelte) | `jules` | `ui`, `frontend` |

---

## 🔄 Development Workflow

```bash
# 1. Check assigned issues
gh issue list --assignee "@me"

# 2. Create feature branch
git checkout -b feat/issue-<N>

# 3. Implement with atomic commits
git commit -m "feat(core): add MemoryNode entity #<N>"

# 4. Create PR
gh pr create --fill
```

---

## 🛠️ Tech Stack Constraints

- **Language**: Rust (2021 edition)
- **Core AI**: Candle (RWKV) + ORT
- **Memory**: LanceDB (Vectors), Sled (Buffer)
- **UI**: Tauri v2 + Svelte 5
- **Async**: Tokio

---

## 📝 Commit Standard

```
<type>(<scope>): <description> #<issue>

Types: feat, fix, docs, refactor, test, chore
Scopes: core, infra, cli, ui
```

---

## 🏷️ Labels

| Label | Purpose |
|-------|---------|
| `core` | Domain layer code |
| `infra` | Infrastructure adapters |
| `ui` | Frontend/UI code |
| `copilot` | Assigned to Copilot |
| `jules` | Assigned to Jules |
| `phase-1` | Phase 1 tasks |
| `phase-5` | Phase 5 (UI) tasks |

---

*Protocol Version: 1.0.0*
