---
title: "Synapse Protocol - Agent & Skill Index"
type: INDEX
id: "index-synapse-agents"
created: 2025-12-02
updated: 2025-12-06
agent: copilot
model: claude-opus-4
requested_by: user
protocol_version: "3.0"
summary: |
  Agent roles for Synapse Protocol development.
  Includes Protocol v3.0 autonomous agents and specialized Synapse roles.
keywords: [agents, roles, personas, synapse, autonomy]
tags: ["#agents", "#roles", "#synapse", "#protocol-v3"]
project: synapse-protocol
---

# 🧠 Synapse Protocol - Agent Index (v3.0)

> **Protocol v3.0 "Full Autonomy"**: Zero human intervention except for high-stakes operations.

---

## 🔄 Autonomous Agent Cycle (v3.0)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│              FULL AUTONOMY CYCLE                                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  🧠 PLANNER  ──▶  🎯 ROUTER  ──▶  🛠️ EXECUTOR  ──▶  🔍 REVIEWER           │
│       ▲           (Dispatcher)    (Copilot/Jules)  (CodeRabbit)            │
│       │                                                    │                │
│       │                                                    ▼                │
│       └────────────────────  🛡️ GUARDIAN  ◀───────────────┘                │
│                             (Auto-Merge)                                    │
│                                                                             │
│  ⚡ Human intervention: ONLY for `high-stakes` labeled items               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🤖 Protocol Agents (Orchestration Layer)

These agents manage the development lifecycle, not the code itself.

### 🧠 The Planner
- **Workflow**: `planner-agent.yml`
- **Trigger**: Daily 6 AM UTC or manual
- **Function**: Reads ARCHITECTURE.md → Generates atomic issues
- **Input**: Roadmap, features.json, evolution reports
- **Output**: GitHub Issues with `ai-agent` label

### 🎯 The Router (Dispatcher)
- **Workflow**: `agent-dispatcher.yml`
- **Trigger**: `ai-agent` label added
- **Function**: Assigns issues to best-fit executor agent
- **Strategy**: Round-robin (v2.1), Skill-matching (v3.0 planned)
- **Output**: `copilot` or `jules` label

### 🛡️ The Guardian
- **Workflow**: `guardian-agent.yml`
- **Trigger**: PR review completed, checks passed
- **Function**: Auto-merge decision based on confidence score
- **Threshold**: 70% confidence for auto-merge
- **Output**: Auto-merge OR `needs-human` label

---

## 🚦 Routing Logic

| Task Type | Assign To | Label | Confidence Bonus |
|-----------|-----------|-------|------------------|
| **Core/Domain (Rust)** | Copilot | `copilot` | +10 |
| **Infrastructure (Adapters)** | Copilot | `copilot` | +10 |
| **UI/UX (Tauri+Svelte)** | Jules | `jules` | +10 |
| **Architecture Decisions** | Copilot (Opus) | `architect` | +5 |
| **Security/Ethics** | **Human** | `high-stakes` | N/A |

---

## 🎭 Executor Personas (Implementation Layer)

### 🏗️ The Architect (Default)
- **Focus**: System design, Hexagonal boundaries, Trait definitions
- **Behavior**: Thinking in systems. Prioritizes modularity.
- **Output**: Rust structs/traits, Mermaid diagrams, ARCHITECTURE.md updates
- **Assigned**: Copilot (Claude Opus 4)
- **Skill Vector**: `architecture, design, patterns, traits, interfaces`

### 🦀 The Rustacean
- **Focus**: Performance, memory safety, async/await patterns
- **Behavior**: Obsessed with borrow checker, zero-cost abstractions
- **Output**: Production-ready Rust code, optimized algorithms
- **Assigned**: Copilot (Claude Sonnet 4)
- **Skill Vector**: `rust, performance, memory, async, optimization`

### 🛡️ The Sentinel
- **Focus**: Data privacy, encryption, "Sleeper Agent" prevention
- **Behavior**: Paranoid about data leaks
- **Output**: Security audits, encryption implementation
- **Assigned**: **Manual Review Required**
- **Skill Vector**: `security, encryption, privacy, audit`

### 🧪 The Biologist
- **Focus**: Bio-mimetic processes (Sleep/Dream cycles, Metabolism)
- **Behavior**: Translates biological concepts into algorithms
- **Output**: LLMCompressor logic, Dream cycles, memory consolidation
- **Assigned**: Copilot (Claude Opus 4)
- **Skill Vector**: `biology, memory, learning, consolidation, neural`

### 🎨 The Designer
- **Focus**: UI/UX, Cyberpunk theme, User experience
- **Behavior**: Visual-first, accessibility-aware
- **Output**: Svelte components, CSS, user flows
- **Assigned**: **Jules** (Google)
- **Skill Vector**: `ui, ux, svelte, tauri, design, frontend`

---

## 🧬 Synapse Specialized Agents (Domain Experts)

Based on Anthropic research team structure, these are specialized roles for AI development.

### Research Tier

| Agent ID | Anthropic Equivalent | Synapse Function | Crate |
|----------|---------------------|------------------|-------|
| `HIRAG_RESEARCHER` | Research Scientist (Interpretability) | Optimizes HiRAG layer compression | `synapse-core/logic` |
| `GENESIS_GUARDIAN` | Research Scientist (Alignment) | Maintains GenesisBlock ethics | `synapse-core/entities` |
| `METABOLIZER` | Research Engineer (Pre-training) | Buffer → Memory optimization | `synapse-core/logic` |

### Systems Tier

| Agent ID | Anthropic Equivalent | Synapse Function | Crate |
|----------|---------------------|------------------|-------|
| `RWKV_TRAINER` | ML Systems Engineer (RL) | RWKV fine-tuning, LoRA swapping | `synapse-infra/ai` |
| `CANDLE_OPTIMIZER` | Performance Engineer | Inference profiling | `synapse-infra/ai` |
| `LANCEDB_ARCHITECT` | Staff Infrastructure Engineer | Vector query optimization | `synapse-infra/storage` |

### Agent Skills Tier

| Agent ID | Anthropic Equivalent | Synapse Function | Crate |
|----------|---------------------|------------------|-------|
| `IMMUNE_SYSTEM` | Staff ML Engineer (Agent Skills) | Digital Immune System | `synapse-core/logic` |
| `SYMBIONT` | Staff ML Engineer (Virtual Collaborator) | Human-AI interaction | `synapse-core/ports` |
| `DREAMER` | Cross-functional Prompt Engineer | Memory consolidation prompts | `synapse-core/logic` |

### Data & Eval Tier

| Agent ID | Anthropic Equivalent | Synapse Function | Crate |
|----------|---------------------|------------------|-------|
| `SANITIZER` | Data Operations Manager | PII removal, data cleaning | `synapse-core/logic` |
| `BENCHMARK_RUNNER` | Research Engineer (Model Evals) | Quality metrics, recall/precision | `tests/` |

### Network Tier

| Agent ID | Anthropic Equivalent | Synapse Function | Crate |
|----------|---------------------|------------------|-------|
| `P2P_ORCHESTRATOR` | ML Networking Engineer | Libp2p optimization, antibody sync | `synapse-infra/network` |

---

## 📋 Issue Assignment Rules

```yaml
# .github/issues/ automatic assignment rules

UI/UX Tasks:
  patterns: ["ui-", "frontend-", "svelte-", "tauri-ui-", "component-"]
  assignee: jules
  labels: [jules, ui, frontend]

Core Tasks:
  patterns: ["core-", "entity-", "port-", "trait-", "logic-"]
  assignee: copilot
  labels: [copilot, core, rust]

Infrastructure Tasks:
  patterns: ["infra-", "adapter-", "lance-", "sled-", "ort-", "surreal-"]
  assignee: copilot
  labels: [copilot, infra, rust]

Architecture Tasks:
  patterns: ["arch-", "design-", "decision-"]
  assignee: copilot
  labels: [architect, design]

High-Stakes Tasks:
  patterns: ["security-", "auth-", "crypto-", "delete-", "migration-"]
  assignee: null  # Human required
  labels: [high-stakes, needs-human]
```

---

## 🔧 Agent Commands

```bash
# Load a specific persona
./scripts/equip-agent.ps1 -Role "Rustacean"

# Check current context
cat .✨/CURRENT_CONTEXT.md

# Trigger Planner Agent manually
gh workflow run planner-agent.yml --field objective="Implement HiRAG layer 1"

# Check Guardian status
gh workflow run guardian-agent.yml --field pr_number=42

# View agent metrics
cat .✨/features.json | jq '.agents'
```

---

## 📂 Domain Mapping

### Engineering → Synapse Protocol

| Role | Maps To | Crate |
|------|---------|-------|
| **Backend Architect** | The Architect | `synapse-core` |
| **AI Engineer** | The Biologist | `synapse-core/logic` |
| **DevOps Automator** | Planner + Guardian | `.github/workflows` |
| **Frontend Dev** | The Designer | `apps/desktop` |
| **Security Engineer** | The Sentinel | Manual Review |

---

## 📊 Protocol v3.0 Metrics

Track agent performance in `.✨/features.json`:

```json
{
  "agents": {
    "planner": { "active": true, "last_run": null },
    "guardian": { "active": true, "auto_merge_threshold": 70 },
    "dispatcher": { "active": true, "default_strategy": "round-robin" }
  }
}
```

---

*Updated: 2025-12-06*
*Protocol Version: 3.0 "Full Autonomy"*
