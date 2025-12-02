# 🧠 GitHub Copilot Instructions - Synapse Protocol

> **"Distributed, Bio-Mimetic AI Memory System"**

## 🎯 Project Context

You are working on **Synapse Protocol**, a Rust-based AI memory system that runs locally on user devices (PC/Mobile). The system uses a "Neoteny" approach - a small core model that grows continuously without catastrophic forgetting.

### Core Philosophy
- **Human-Centric**: User data is the currency. Privacy is paramount (Local-First).
- **Genesis Block**: An immutable ethical vector ("Do no harm") filters all AI actions.
- **Bio-Mimetic**: Memory consolidation mimics biological sleep/dream cycles.
- **One Brain, Many Hats**: Single model instance with LoRA adapter swapping.

---

## 🏗️ Architecture (CRITICAL - READ FIRST)

**Hexagonal Architecture (Ports & Adapters)**

```
synapse-core    # PURE domain logic (no infrastructure dependencies)
synapse-infra   # Infrastructure adapters (LanceDB, Sled, ORT)
synapse-cli     # Application layer
```

### 🚨 GOLDEN RULES

1. **Core MUST NOT depend on infra**
   - `synapse-core` only uses: `serde`, `async-trait`, `uuid`, `chrono`
   - NO `lancedb`, NO `sled`, NO `ort` in core
   - All infrastructure accessed via Traits (Ports)

2. **Ports define boundaries**
   - `MemoryPort` → Long-term semantic memory (LanceDB)
   - `BufferPort` → Short-term FIFO buffer (Sled)
   - `EmbeddingPort` → Text → Vector (ORT)
   - `LlmPort` → Text generation (Candle/RWKV)

3. **Immutable Genesis Block**
   - The GenesisBlock ethical vector is IMMUTABLE
   - All AI actions MUST pass `GenesisBlock::evaluate_intention()`
   - Similarity threshold: 0.95 (default)

---

## 📦 Core Entities

### MemoryNode
```rust
pub struct MemoryNode {
    pub id: String,               // UUID
    pub content: String,          // Fact or summary
    pub layer: u8,                // HiRAG layer (0 = fact, 1+ = summary)
    pub node_type: NodeType,      // Fact, Summary, Thought, etc.
    pub embedding: Vec<f32>,      // 384-dim (MiniLM) or 768-dim
    pub namespace: String,        // Multi-tenant support
    // ...
}
```

### GenesisBlock
```rust
pub struct GenesisBlock {
    pub ethical_vector: Vec<f32>,  // IMMUTABLE "Do no harm"
    pub threshold: f32,            // Default: 0.95
    // ...
}
```

### Interaction
```rust
pub struct Interaction {
    pub user_input: String,
    pub ai_response: String,
    pub timestamp: i64,
    pub session_id: String,
    pub processed: bool,
}
```

---

## 🔌 Ports (Traits)

### MemoryPort (Long-Term Memory)
```rust
#[async_trait]
pub trait MemoryPort {
    async fn store(&self, node: MemoryNode) -> Result<String>;
    async fn search(&self, embedding: &[f32], top_k: usize) -> Result<Vec<SearchResult>>;
    async fn search_layer(&self, embedding: &[f32], layer: u8, top_k: usize);
    async fn search_namespace(&self, embedding: &[f32], namespace: &str, top_k: usize);
    // ...
}
```

### BufferPort (Short-Term Buffer)
```rust
#[async_trait]
pub trait BufferPort {
    async fn push(&self, interaction: Interaction) -> Result<()>;
    async fn pop_batch(&self, size: usize) -> Result<Vec<Interaction>>;
    async fn peek(&self, size: usize) -> Result<Vec<Interaction>>;
    // ...
}
```

---

## 🛠️ Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Language | **Rust 2021** | Performance, Safety |
| Vector Store | **LanceDB** | Semantic memory (embeddings) |
| Buffer Store | **Sled** | FIFO short-term interactions |
| AI Inference | **Candle (RWKV)** | Local text generation |
| Embeddings | **ORT (MiniLM)** | On-device 384-dim embeddings |
| Desktop UI | **Tauri v2 + Svelte 5** | Cross-platform (Phase 5) |

---

## 📋 Development Workflow

### 1. Issue-Driven Development
```bash
# Check assigned issues
gh issue list --assignee "@me"

# Create branch
git checkout -b feat/issue-<N>

# After coding
git commit -m "feat(core): add HiRAG layer logic #<N>"

# Create PR
gh pr create --fill
```

### 2. Atomic Commits
- **ONE commit = ONE logical change**
- **NEVER mix concerns** (e.g., core logic + UI styling)
- Use conventional commits: `feat(scope): description #issue`

### 3. Testing
- Unit tests in each crate's `tests/` folder
- Integration tests in workspace `tests/` folder
- Run: `cargo test`

---

## 🚫 What NOT to Do

❌ **NEVER add infrastructure deps to `synapse-core`**
❌ **NEVER skip ethics check** (GenesisBlock)
❌ **NEVER mutate GenesisBlock** after initialization
❌ **NEVER mix UI and core logic** in same commit
❌ **NEVER create TODO.md files** (use GitHub Issues)

---

## ✅ What to Do

✅ **ALWAYS use Ports (Traits)** to access infrastructure
✅ **ALWAYS validate ethics** via `GenesisBlock::evaluate_intention()`
✅ **ALWAYS write tests** for new features
✅ **ALWAYS use HiRAG layers** for summaries (layer 0 = facts, 1+ = summaries)
✅ **ALWAYS use namespaces** for multi-tenant queries

---

## 📊 HiRAG (Hierarchical RAG)

### Concept
- **Layer 0**: Raw facts (user interactions, harvested data)
- **Layer 1**: Daily summaries (10-20 facts → 1 summary)
- **Layer 2**: Weekly summaries (7 daily summaries → 1 summary)
- **Layer 3+**: Long-term memory consolidation

### Example
```rust
// Store base fact (Layer 0)
let fact = MemoryNode::new("User likes cyberpunk themes".to_string());
memory_port.store(fact).await?;

// Create summary (Layer 1)
let summary = MemoryNode::with_layer("User aesthetic: Dark tech, neon".to_string(), 1);
memory_port.store(summary).await?;

// Search within layer
let results = memory_port.search_layer(&query_embedding, 1, 5).await?;
```

---

## 🔐 Ethics Enforcement

### Rule
**ALL AI-generated actions MUST pass ethics check.**

### Implementation
```rust
// Before executing any AI action
let action_embedding = embedding_port.embed(&proposed_action).await?;
genesis_block.evaluate_intention(&action_embedding)?;

// If similarity < threshold → Err(CoreError::EthicsViolation)
```

---

## 📁 File Structure

```
synapse-protocol/
├── .✨/
│   ├── ARCHITECTURE.md     # System architecture (READ THIS FIRST)
│   ├── AGENT_INDEX.md      # Agent roles and routing
│   └── CONTEXT_LOG.md      # Session notes
├── .github/
│   ├── copilot-instructions.md  # THIS FILE
│   └── issues/             # Issue tracking
├── crates/
│   ├── synapse-core/       # Domain layer (PURE)
│   │   ├── src/
│   │   │   ├── entities/   # MemoryNode, GenesisBlock, etc.
│   │   │   ├── ports/      # Traits (MemoryPort, BufferPort, etc.)
│   │   │   └── error.rs    # Core errors
│   │   └── Cargo.toml
│   ├── synapse-infra/      # Infrastructure adapters
│   │   ├── src/
│   │   │   └── adapters/   # LanceDbAdapter, SledAdapter, etc.
│   │   └── Cargo.toml
│   └── synapse-cli/        # CLI application
│       ├── src/
│       │   ├── main.rs
│       │   └── commands.rs
│       └── Cargo.toml
├── Cargo.toml              # Workspace configuration
├── AGENTS.md               # Agent configuration
├── README.md               # Project overview
└── LICENSE                 # AGPLv3 + Commercial
```

---

## 🎨 Code Style

### Naming
- **Entities**: PascalCase (e.g., `MemoryNode`)
- **Ports**: PascalCase + Port suffix (e.g., `MemoryPort`)
- **Adapters**: PascalCase + Adapter suffix (e.g., `LanceDbAdapter`)
- **Functions**: snake_case (e.g., `evaluate_intention`)

### Error Handling
```rust
// Use Result<T, CoreError> for domain logic
pub async fn store(&self, node: MemoryNode) -> Result<String, CoreError> {
    // ...
}

// Use ? operator for propagation
let embedding = embedding_port.embed(&text).await?;
```

### Async
- Use `tokio` as async runtime
- Use `async-trait` for trait methods
- Prefer `async fn` over manual futures

---

## 🚀 Current Phase

**Phase 1: Core Infrastructure**

### Active Issues
- [ ] Setup Cargo workspace
- [ ] Define core entities (MemoryNode, GenesisBlock)
- [ ] Define core ports (MemoryPort, BufferPort, etc.)
- [ ] Implement LanceDB adapter
- [ ] Implement Sled adapter
- [ ] Implement CLI application

### Next Phases
- **Phase 2**: AI Integration (RWKV + ORT)
- **Phase 3**: Memory Consolidation ("Sleep" cycle)
- **Phase 4**: P2P Networking (Libp2p Gossipsub)
- **Phase 5**: Desktop UI (Tauri + Svelte)

---

## 📞 Help & Resources

- **Architecture**: `.✨/ARCHITECTURE.md`
- **Agent Routing**: `.✨/AGENT_INDEX.md`
- **Issues**: `.github/issues/`
- **Commit Standard**: `docs/COMMIT_STANDARD.md`

---

*Version: 1.0.0*
*Last Updated: December 2, 2025*
