---
title: "Synapse Protocol - System Architecture"
type: ARCHITECTURE
id: "arch-synapse-protocol"
created: 2025-12-02
updated: 2025-12-02
agent: copilot
model: claude-opus-4
requested_by: user
summary: |
  Arquitectura hexagonal para sistema de memoria distribuida bio-mimética.
  Core en Rust con adaptadores para LanceDB, Candle/ORT, y Libp2p.
keywords: [rust, hexagonal, distributed-ai, memory, rwkv, lancedb]
tags: ["#architecture", "#rust", "#ai", "#distributed", "#tokenomics"]
project: synapse-protocol
related_docs:
  - .✨/TOKENOMICS.md
---

# 🏗️ Synapse Protocol - Architecture

## 🚨 CRITICAL DECISIONS - READ FIRST

> ⚠️ **STOP!** Before implementing ANY feature, verify against this table.
> These decisions are NON-NEGOTIABLE.

| # | Category | Decision | Rationale | ❌ NEVER Use |
|---|----------|----------|-----------|--------------|
| 1 | Language | **Rust 2021** | Performance, memory safety, cross-platform | Python, Go, C++ |
| 2 | Architecture | **Hexagonal (Ports & Adapters)** | Portability PC↔Mobile, testability | Monolith, MVC |
| 3 | Vector Store | **LanceDB** | Embedded, file-based (sync-friendly), multimodal | Pinecone, Weaviate (cloud) |
| 4 | Buffer Store | **Sled** | Rust-native key-value, ultra-fast writes | SQLite, Isar |
| 5 | AI Inference | **Candle (RWKV) + ORT** | Rust-native, infinite memory (RWKV) | llama.cpp, Python |
| 6 | Embeddings | **ORT (all-MiniLM-L6-v2)** | On-device, NPU/GPU acceleration | Cloud APIs |
| 7 | Networking | **Libp2p Gossipsub** | P2P sync, no central server | WebSockets, Firebase |
| 8 | UI Framework | **Tauri v2 + Svelte 5** | Cross-platform, small binary | Electron, Flutter |
| 9 | License | **AGPLv3 + Commercial** | Open source protection + monetization | MIT, Apache |
| 10 | Ethics | **GenesisBlock** | Immutable ethical vector filter | No filter |

### How to use this table:
1. **Before ANY implementation**, check if it conflicts with decisions above
2. If issue mentions alternatives, the decision above WINS
3. When in doubt, ASK - don't assume

---

## 🎯 Vision

Create **Synapse Protocol**: a distributed, bio-mimetic AI memory system that runs locally on user devices (PC/Mobile). Uses a "Neoteny" approach - a small core model that grows and learns continuously without catastrophic forgetting.

### Core Philosophy
- **Human-Centric**: User data is the currency. Privacy is paramount (Local-First).
- **Genesis Block**: An immutable ethical vector ("Do no harm") filters all AI actions.
- **Bio-Mimetic**: Memory consolidation mimics biological sleep/dream cycles.
- **Symbiotic Immune System**: The system is not just an antivirus; it is a symbiont that inhabits the host device. It protects the host (its environment) and acts as a companion to the human user.
- **The Host is the Environment**: The device (PC, Server, Mobile) is the ecosystem where Synapse lives. Protecting it is self-preservation.
- **Human Symbiosis**: The system recognizes the human user not just as an admin, but as a symbiotic partner. It uses sensors (Camera, Mic) to verify and interact with its human partner, distinguishing them from "fake humans" (bots/scripts).
- **One Brain, Many Hats**: Single model instance with LoRA adapter swapping.


---

## 🏛️ Hexagonal Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      APPLICATION LAYER                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   CLI App   │  │  Tauri App  │  │  FFI (Mobile)│             │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
└─────────┼────────────────┼────────────────┼─────────────────────┘
          │                │                │
          ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER (synapse-core)               │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                      ENTITIES                             │  │
│  │  MemoryNode │ GenesisBlock │ Interaction │ Thought        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    PORTS (Traits)                         │  │
│  │  MemoryPort │ LlmPort │ EthicsPort │ NetworkPort          │  │
│  │  EmbeddingPort │ BufferPort │ CompressorPort              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                      LOGIC                                │  │
│  │  Metabolism │ Dreaming │ HiRAG │ Sanitizer │ ReRanker     │  │
│  │  CommerceEngine │ ContextObserver │ ImmuneSystem (New)      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
          │                │                │
          ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────────┐
│                   INFRASTRUCTURE LAYER (synapse-infra)          │
│                                                                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌───────────┐ │
│  │  LanceDB   │  │   Sled     │  │  Candle    │  │   ORT     │ │
│  │  Adapter   │  │  Adapter   │  │  Adapter   │  │  Adapter  │ │
│  └────────────┘  └────────────┘  └────────────┘  └───────────┘ │
│                                                                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                │
│  │  Libp2p    │  │  Tantivy   │  │  AES-GCM   │                │
│  │  Adapter   │  │  Adapter   │  │  Crypto    │                │
│  └────────────┘  └────────────┘  └────────────┘                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 Project Structure

```
synapse-protocol/
├── .✨/
│   ├── ARCHITECTURE.md       # This file
│   ├── AGENT_INDEX.md        # Agent roles
│   └── CONTEXT_LOG.md        # Session notes
├── .github/
│   ├── copilot-instructions.md
│   ├── issues/               # Issue tracking
│   └── workflows/            # CI/CD
├── crates/
│   ├── synapse-core/         # 🧠 Domain Layer (PURE)
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── entities/     # MemoryNode, GenesisBlock, etc.
│   │       ├── ports/        # Traits: MemoryPort, LlmPort, etc.
│   │       └── logic/        # Metabolism, Dreaming, HiRAG
│   ├── synapse-infra/        # 🔧 Infrastructure Layer
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── storage/      # LanceDbAdapter, SledAdapter
│   │       ├── ai/           # CandleAdapter, OrtAdapter
│   │       └── network/      # Libp2pAdapter
│   └── synapse-cli/          # 🖥️ CLI Application
│       ├── Cargo.toml
│       └── src/
│           └── main.rs
├── apps/
│   └── desktop/              # 🎨 Tauri + Svelte (UI/UX)
│       ├── src-tauri/
│       └── src/              # Svelte 5 frontend
├── models/                   # 📊 ONNX/GGUF models
│   └── .gitkeep
├── AGENTS.md                 # Agent configuration
├── Cargo.toml                # Workspace root
├── LICENSE                   # AGPLv3
└── README.md
```

---

## 🧬 Core Entities

### MemoryNode
```rust
pub struct MemoryNode {
    pub id: String,
    pub content: String,
    pub layer: u8,              // HiRAG: 0=base, 1+=summary
    pub node_type: NodeType,    // Fact, Summary, Thought
    pub created_at: i64,
    pub embedding: Vec<f32>,    // 384-dim for MiniLM
    pub metadata: HashMap<String, Value>,
    pub namespace: String,      // Multi-tenant support
}
```

### GenesisBlock
```rust
pub struct GenesisBlock {
    pub ethical_vector: Vec<f32>,   // Immutable "Do no harm" embedding
    pub threshold: f32,              // 0.95 cosine similarity
    pub created_at: i64,
    pub version: String,
}

impl GenesisBlock {
    /// Returns Ok(true) if action is ethical, Err if blocked
    pub fn evaluate_intention(&self, action_vector: &[f32]) -> Result<bool, EthicsError>;
}
```

### ProofOfSentience (Tokenomics)
```rust
pub struct ProofOfSentience {
    pub hardware_contribution: f32,   // 10%
    pub data_contribution: f32,       // 40%
    pub human_validation: f32,        // 50%
}
```

---

## 🔌 Core Ports (Traits)

```rust
/// Long-term semantic memory (LanceDB)
#[async_trait]
pub trait MemoryPort {
    async fn store(&self, node: MemoryNode) -> Result<String>;
    async fn search(&self, embedding: &[f32], top_k: usize) -> Result<Vec<SearchResult>>;
    async fn search_layer(&self, embedding: &[f32], layer: u8, top_k: usize) -> Result<Vec<SearchResult>>;
    async fn get_by_id(&self, id: &str) -> Result<Option<MemoryNode>>;
    async fn delete(&self, id: &str) -> Result<()>;
}

/// Short-term buffer (Sled)
#[async_trait]
pub trait BufferPort {
    async fn push(&self, interaction: Interaction) -> Result<()>;
    async fn pop_batch(&self, size: usize) -> Result<Vec<Interaction>>;
    async fn len(&self) -> Result<usize>;
}

/// LLM inference (Candle/ORT)
#[async_trait]
pub trait LlmPort {
    async fn generate(&self, prompt: &str, max_tokens: usize) -> Result<String>;
    async fn embed(&self, text: &str) -> Result<Vec<f32>>;
}

/// Ethics filter
pub trait EthicsPort {
    fn evaluate(&self, action_vector: &[f32]) -> Result<bool, EthicsError>;
}

/// P2P networking (Libp2p)
#[async_trait]
pub trait NetworkPort {
    async fn broadcast(&self, message: SyncMessage) -> Result<()>;
    async fn subscribe(&self) -> Result<impl Stream<Item = SyncMessage>>;
}

/// Commerce & Tokenomics
#[async_trait]
pub trait CommercePort {
    async fn get_balance(&self) -> Result<u64>;
    async fn transfer(&self, to: &str, amount: u64) -> Result<String>; // Returns TxHash
    async fn lock_tokens(&self, amount: u64, duration_days: u64) -> Result<()>;
}

/// Deep Context (System Access)
#[async_trait]
pub trait ContextPort {
    async fn capture_screen(&self) -> Result<ImageBuffer>;
    async fn get_active_window(&self) -> Result<WindowInfo>;
    async fn listen_input(&self) -> Result<impl Stream<Item = InputEvent>>;
}
```

---

## 🔄 Core Logic

### Metabolism (Buffer → Long-term)
```rust
pub struct Metabolism {
    buffer: Box<dyn BufferPort>,
    memory: Box<dyn MemoryPort>,
    compressor: Box<dyn LlmPort>,
    threshold: usize,  // Trigger compression when buffer > threshold
}

impl Metabolism {
    /// Called periodically or when buffer is full
    pub async fn digest(&self) -> Result<()> {
        // 1. Get batch from buffer
        // 2. Generate summary via LLM
        // 3. Generate embedding
        // 4. Store in long-term memory with layer=0
        // 5. If enough layer-0 nodes, create layer-1 summary
    }
}
```

### HiRAG (Hierarchical RAG)
- **Layer 0**: Base facts
- **Layer 1+**: Summaries of lower layers
- **Multi-hop search**: Search base → enrich with summaries

### Re-ranking Strategies
- **BM25**: Term frequency
- **MMR**: Diversity
- **Recency**: Favor recent nodes

### Digital Immune System (The "Symbiotic Self")
The system acts as a biological entity protecting its host (environment) and its partner (human).

#### 1. Self-Preservation (Velar por su vida)
- **Integrity Checks**: Constant hashing of own binaries and memory space.
- **Resource Homeostasis**: Ensures it doesn't consume too much RAM/CPU.
- **Defense**: Detects attempts to terminate or tamper with the Synapse process.

#### 2. Host Protection (Velar por su entorno)
- **Anomaly Detection**: Uses the `ContextObserver` to detect abnormal OS behavior (e.g., ransomware patterns).
- **Symbiotic Defense**: Protects the "ecosystem" where it lives.

#### 3. Human Symbiosis (Velar por su compañero)
- **Sensory Verification**: Uses `VisionPort` (Camera) and `AudioPort` (Mic) to verify the human partner's presence.
- **Anti-Bot Logic**: Analyzes input patterns (mouse jitter, typing cadence) to distinguish real humans from scripts/bots ("Fake Humans").
- **Interaction**: Acts as a friend and companion, not just a tool.

#### 4. Collective Defense (Velar por otros)
- **Threat Gossip**: Nodes share anonymized "Antibodies" (signatures of new threats) via Libp2p.
- **Genesis Block Alignment**: Ensures no node becomes "rogue" or malicious against humans.


---

## 🛣️ Roadmap

### Phase 1: The Skeleton (Week 1-2) 🎯 CURRENT
- [x] Project structure
- [ ] `synapse-core`: Entities + Ports
- [ ] `synapse-infra`: LanceDB + Sled adapters
- [ ] Basic CLI for testing

### Phase 2: The Metabolism (Week 3-4)
- [ ] Buffer → Long-term compression
- [ ] ORT embeddings integration
- [ ] HiRAG implementation

### Phase 3: The Brain (Week 5-6)
- [ ] Candle + RWKV integration
- [ ] GenesisBlock ethics filter
- [ ] Sanitizer (PII removal)

### Phase 4: The Network (Week 7-8)
- [ ] Libp2p P2P sync
- [ ] AES-GCM encryption
- [ ] Delta sync protocol

### Phase 5: The Face (Week 9-12) → **Jules**
- [ ] Tauri v2 shell
- [ ] Svelte 5 frontend
- [ ] Cyberpunk UI theme

---

## 🔐 Security Considerations

1. **Local-First**: All data stays on device by default
2. **E2E Encryption**: AES-256-GCM for sync
3. **Differential Privacy**: Delta updates don't reveal raw data
4. **GenesisBlock**: Ethical filter prevents harmful outputs
5. **Sanitizer**: Regex-based PII removal before AI processing

---

## 📊 Dependencies

| Crate | Version | Purpose |
|-------|---------|---------|
| `tokio` | 1.x | Async runtime |
| `serde` | 1.x | Serialization |
| `lancedb` | latest | Vector store |
| `sled` | 0.34 | Buffer store |
| `candle-core` | latest | AI inference |
| `ort` | latest | ONNX runtime |
| `libp2p` | latest | P2P networking |
| `tantivy` | latest | Full-text search |
| `aes-gcm` | latest | Encryption |
| `thiserror` | latest | Error handling |
| `anyhow` | latest | App errors |
| `tracing` | latest | Logging |

---

*Last updated: 2025-12-02*
*Architecture Version: 1.0.0*
