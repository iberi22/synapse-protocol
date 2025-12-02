---
title: "Implement LanceDB adapter for MemoryPort"
labels:
  - infra
  - rust
  - copilot
  - phase-1
  - adapter
assignees: ["copilot"]
---

## Descripción

Implementar el adaptador de LanceDB que implementa `MemoryPort` para almacenamiento vectorial.

## Tareas

- [ ] Agregar dependencia `lancedb` a `synapse-infra/Cargo.toml`
- [ ] Crear `storage/mod.rs`
- [ ] Crear `storage/lancedb_adapter.rs`
- [ ] Implementar `MemoryPort` para `LanceDbAdapter`
- [ ] Crear método `new()` con configuración
- [ ] Implementar búsqueda con filtro por layer (HiRAG)
- [ ] Tests de integración

## Criterios de Aceptación

- [ ] CRUD completo funciona
- [ ] Búsqueda vectorial devuelve resultados ordenados por similitud
- [ ] Filtrado por `layer` funciona (HiRAG)
- [ ] Filtrado por `namespace` funciona (multi-tenant)
- [ ] Tests pasan

## Código de Referencia

```rust
// storage/lancedb_adapter.rs
use lancedb::connect;
use synapse_core::ports::MemoryPort;
use synapse_core::entities::MemoryNode;

pub struct LanceDbAdapter {
    db: Database,
    table_name: String,
}

impl LanceDbAdapter {
    pub async fn new(path: &str, table_name: &str) -> Result<Self, InfraError> {
        let db = connect(path).execute().await?;
        Ok(Self { db, table_name: table_name.to_string() })
    }
}

#[async_trait]
impl MemoryPort for LanceDbAdapter {
    async fn search_layer(&self, embedding: &[f32], layer: u8, top_k: usize) -> Result<Vec<SearchResult>, CoreError> {
        let table = self.db.open_table(&self.table_name).execute().await?;
        let results = table
            .search(embedding)
            .filter(format!("layer = {}", layer))
            .limit(top_k)
            .execute()
            .await?;
        // Convert to SearchResult...
    }
}
```

## Dependencias
- Requiere: FEAT_define-core-ports

## Referencia
- `.✨/ARCHITECTURE.md` - Infrastructure Layer
