---
title: "Define core Ports (Traits) for hexagonal architecture"
labels:
  - core
  - rust
  - copilot
  - phase-1
  - ports
assignees: ["copilot"]
---

## Descripción

Definir los Traits (Ports) que abstraen la infraestructura del dominio.

## Tareas

- [ ] Crear `ports/mod.rs`
- [ ] Crear `ports/memory_port.rs` - `trait MemoryPort`
- [ ] Crear `ports/buffer_port.rs` - `trait BufferPort`
- [ ] Crear `ports/llm_port.rs` - `trait LlmPort`
- [ ] Crear `ports/ethics_port.rs` - `trait EthicsPort`
- [ ] Crear `ports/network_port.rs` - `trait NetworkPort`
- [ ] Crear `ports/embedding_port.rs` - `trait EmbeddingPort`

## Criterios de Aceptación

- [ ] Todos los traits usan `async_trait` donde necesario
- [ ] Error types definidos con `thiserror`
- [ ] NO hay dependencias de infraestructura (LanceDB, Sled, etc.)
- [ ] Documentación completa

## Código de Referencia

```rust
// ports/memory_port.rs
use async_trait::async_trait;
use crate::entities::MemoryNode;
use crate::error::CoreError;

/// Port for long-term semantic memory storage.
/// Implementations: LanceDbAdapter
#[async_trait]
pub trait MemoryPort: Send + Sync {
    /// Store a memory node and return its ID
    async fn store(&self, node: MemoryNode) -> Result<String, CoreError>;
    
    /// Search by embedding similarity
    async fn search(&self, embedding: &[f32], top_k: usize) -> Result<Vec<SearchResult>, CoreError>;
    
    /// Search within a specific HiRAG layer
    async fn search_layer(&self, embedding: &[f32], layer: u8, top_k: usize) -> Result<Vec<SearchResult>, CoreError>;
    
    /// Get a node by ID
    async fn get_by_id(&self, id: &str) -> Result<Option<MemoryNode>, CoreError>;
    
    /// Delete a node
    async fn delete(&self, id: &str) -> Result<(), CoreError>;
}
```

## Referencia
- `.✨/ARCHITECTURE.md` - Core Ports section
