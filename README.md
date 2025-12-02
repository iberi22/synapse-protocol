# 🧠 Synapse Protocol

> **Distributed, Bio-Mimetic AI Memory System**

[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-blue.svg)](LICENSE)
[![Rust](https://img.shields.io/badge/Rust-2021-orange.svg)](https://www.rust-lang.org/)

## 🎯 Vision

Synapse Protocol is a distributed AI memory system that runs locally on user devices (PC/Mobile). It uses a "Neoteny" approach - a small core model that grows and learns continuously without catastrophic forgetting.

### Core Philosophy
- **Human-Centric**: User data is the currency. Privacy is paramount (Local-First).
- **Genesis Block**: An immutable ethical vector ("Do no harm") filters all AI actions.
- **Bio-Mimetic**: Memory consolidation mimics biological sleep/dream cycles.
- **One Brain, Many Hats**: Single model instance with LoRA adapter swapping.

## 🏗️ Architecture

```
Hexagonal Architecture (Ports & Adapters)
├── synapse-core    # Domain logic (PURE - no external deps)
├── synapse-infra   # Infrastructure adapters
└── synapse-cli     # CLI application
```

## 🚀 Quick Start

### Prerequisites

1. **Rust** (2021 edition or later)
2. **Protocol Buffers Compiler** (`protoc`)
   ```bash
   # Windows (Chocolatey)
   choco install protoc
   
   # macOS (Homebrew)
   brew install protobuf
   
   # Ubuntu/Debian
   sudo apt install protobuf-compiler
   
   # Or download from:
   # https://github.com/protocolbuffers/protobuf/releases
   ```

### Build

```bash
# Clone
git clone https://github.com/YOUR_ORG/synapse-protocol
cd synapse-protocol

# Build
cargo build --release

# Run CLI
cargo run -p synapse-cli -- --help
```

## 📦 Project Structure

```
synapse-protocol/
├── .✨/                    # AI context (Architecture, Agent Index)
├── .github/issues/         # Issue tracking (Git-Core Protocol)
├── crates/
│   ├── synapse-core/       # Domain layer
│   ├── synapse-infra/      # Infrastructure layer
│   └── synapse-cli/        # CLI application
├── apps/desktop/           # Tauri + Svelte UI
└── models/                 # ONNX/GGUF models
```

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Rust 2021 |
| Vector Store | LanceDB |
| Buffer Store | Sled |
| AI Inference | Candle (RWKV) + ORT |
| Embeddings | all-MiniLM-L6-v2 |
| P2P Network | Libp2p |
| Desktop UI | Tauri v2 + Svelte 5 |

## 📋 Development

This project follows the [Git-Core Protocol](https://github.com/iberi22/Git-Core-Protocol):

- **State**: GitHub Issues (not TODO.md files)
- **Commits**: Conventional Commits
- **Architecture**: `.✨/ARCHITECTURE.md`

### Agent Assignments
- **Core/Infra (Rust)**: Copilot (Claude Opus/Sonnet)
- **UI/UX (Tauri+Svelte)**: Jules (Google)

## ⚖️ License

This project is licensed under **AGPLv3**. 

For commercial/proprietary use, contact: [your-email]

---

*Built with 🧠 by South West Labs*
