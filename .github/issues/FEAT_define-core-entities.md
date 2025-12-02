---
title: "Define MemoryNode and GenesisBlock entities"
labels:
  - core
  - rust
  - copilot
  - phase-1
  - entities
assignees: ["copilot"]
---

## Descripción

Crear las entidades fundamentales del dominio en `synapse-core/src/entities/`.

## Tareas

- [ ] Crear `entities/mod.rs`
- [ ] Crear `entities/memory_node.rs` con struct `MemoryNode`
- [ ] Crear `entities/genesis_block.rs` con struct `GenesisBlock`
- [ ] Crear `entities/interaction.rs` con struct `Interaction`
- [ ] Crear `entities/node_type.rs` con enum `NodeType`
- [ ] Agregar documentación (docstrings) a todos los campos

## Criterios de Aceptación

- [ ] Todas las entidades son `Serialize + Deserialize`
- [ ] `MemoryNode` soporta HiRAG (campo `layer`)
- [ ] `GenesisBlock` tiene método `evaluate_intention`
- [ ] Tests unitarios para cada entidad

## Código de Referencia

```rust
// entities/memory_node.rs
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// A node in the memory graph representing a piece of knowledge.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemoryNode {
    /// Unique identifier (UUID)
    pub id: String,
    /// The actual content/fact stored
    pub content: String,
    /// HiRAG layer: 0 = base fact, 1+ = summary level
    pub layer: u8,
    /// Type of node (Fact, Summary, Thought)
    pub node_type: NodeType,
    /// Unix timestamp of creation
    pub created_at: i64,
    /// 384-dimensional embedding vector
    pub embedding: Vec<f32>,
    /// Additional metadata as JSON
    pub metadata: HashMap<String, serde_json::Value>,
    /// Namespace for multi-tenant support
    pub namespace: String,
}
```

## Referencia
- `.✨/ARCHITECTURE.md` - Core Entities section
