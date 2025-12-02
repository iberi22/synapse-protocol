---
title: "Synapse Protocol - Agent & Skill Index"
type: INDEX
id: "index-synapse-agents"
created: 2025-12-02
updated: 2025-12-02
agent: copilot
model: claude-opus-4
requested_by: user
summary: |
  Agent roles for Synapse Protocol development.
keywords: [agents, roles, personas, synapse]
tags: ["#agents", "#roles", "#synapse"]
project: synapse-protocol
---

# 🧠 Synapse Protocol - Agent Index

## 🚦 Routing Logic

| Task Type | Assign To | Label |
|-----------|-----------|-------|
| **Core/Domain (Rust)** | Copilot (Opus/Sonnet) | `copilot` |
| **Infrastructure (Adapters)** | Copilot (Opus/Sonnet) | `copilot` |
| **UI/UX (Tauri+Svelte)** | Jules | `jules` |
| **Architecture Decisions** | Opus via Copilot | `architect` |
| **Security/Ethics** | Manual Review | `security` |

---

## 🤖 Agent Personas

### 🏗️ The Architect (Default)
- **Focus**: System design, Hexagonal boundaries, Trait definitions
- **Behavior**: Thinking in systems. Prioritizes modularity.
- **Output**: Rust structs/traits, Mermaid diagrams, ARCHITECTURE.md updates
- **Assigned**: Copilot (Claude Opus 4.5)

### 🦀 The Rustacean
- **Focus**: Performance, memory safety, async/await patterns
- **Behavior**: Obsessed with borrow checker, zero-cost abstractions
- **Output**: Production-ready Rust code, optimized algorithms
- **Assigned**: Copilot (Claude Sonnet 4)

### 🛡️ The Sentinel
- **Focus**: Data privacy, encryption, "Sleeper Agent" prevention
- **Behavior**: Paranoid about data leaks
- **Output**: Security audits, encryption implementation
- **Assigned**: Manual Review

### 🧪 The Biologist
- **Focus**: Bio-mimetic processes (Sleep/Dream cycles, Metabolism)
- **Behavior**: Translates biological concepts into algorithms
- **Output**: LLMCompressor logic, Dream cycles, memory consolidation
- **Assigned**: Copilot (Claude Opus 4.5)

### 🎨 The Designer
- **Focus**: UI/UX, Cyberpunk theme, User experience
- **Behavior**: Visual-first, accessibility-aware
- **Output**: Svelte components, CSS, user flows
- **Assigned**: **Jules** (Google)

---

## 📋 Issue Assignment Rules

```yaml
# .github/issues/ assignment rules

UI/UX Tasks:
  patterns: ["ui-", "frontend-", "svelte-", "tauri-ui-", "component-"]
  assignee: jules
  labels: [jules, ui, frontend]

Core Tasks:
  patterns: ["core-", "entity-", "port-", "trait-", "logic-"]
  assignee: copilot
  labels: [copilot, core, rust]

Infrastructure Tasks:
  patterns: ["infra-", "adapter-", "lance-", "sled-", "ort-"]
  assignee: copilot
  labels: [copilot, infra, rust]

Architecture Tasks:
  patterns: ["arch-", "design-", "decision-"]
  assignee: copilot
  labels: [architect, design]
```

---

## 🔧 Equipping an Agent

```bash
# Load a specific persona
./scripts/equip-agent.ps1 -Role "Rustacean"

# Check current context
cat .✨/CURRENT_CONTEXT.md
```

---

## 📂 Domain Mapping

### Engineering → Synapse Protocol

| Role | Maps To | Crate |
|------|---------|-------|
| **Backend Architect** | The Architect | `synapse-core` |
| **AI Engineer** | The Biologist | `synapse-core/logic` |
| **DevOps Automator** | CI/CD | `.github/workflows` |
| **Frontend Dev** | The Designer | `apps/desktop` |

---

*Updated: 2025-12-02*
