---
title: "Create CLI application for testing"
labels:
  - app
  - rust
  - copilot
  - phase-1
assignees: ["copilot"]
---

## Descripción

Crear una aplicación CLI básica para probar el core y los adaptadores.

## Tareas

- [ ] Agregar dependencias a `synapse-cli/Cargo.toml` (clap, tokio)
- [ ] Crear estructura CLI con subcomandos
- [ ] Comando `store` - Guardar un MemoryNode
- [ ] Comando `search` - Buscar por query text
- [ ] Comando `buffer` - Ver estado del buffer
- [ ] Comando `digest` - Triggear Metabolism manualmente
- [ ] Logging con tracing

## Criterios de Aceptación

- [ ] `cargo run -p synapse-cli -- --help` muestra ayuda
- [ ] Comandos básicos funcionan
- [ ] Logs informativos

## Código de Referencia

```rust
// main.rs
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "synapse")]
#[command(about = "Synapse Protocol CLI", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Store a memory node
    Store {
        #[arg(short, long)]
        content: String,
    },
    /// Search memories
    Search {
        #[arg(short, long)]
        query: String,
        #[arg(short, long, default_value = "5")]
        top_k: usize,
    },
    /// Show buffer status
    Buffer,
    /// Trigger memory consolidation
    Digest,
}
```

## Dependencias
- Requiere: FEAT_lancedb-adapter, FEAT_sled-adapter

## Referencia
- `.✨/ARCHITECTURE.md` - Application Layer
