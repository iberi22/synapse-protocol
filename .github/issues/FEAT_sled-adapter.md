---
title: "Implement Sled adapter for BufferPort"
labels:
  - infra
  - rust
  - copilot
  - phase-1
  - adapter
assignees: ["copilot"]
---

## Descripción

Implementar el adaptador de Sled para el buffer de memoria a corto plazo.

## Tareas

- [ ] Agregar dependencia `sled` a `synapse-infra/Cargo.toml`
- [ ] Crear `storage/sled_adapter.rs`
- [ ] Implementar `BufferPort` para `SledAdapter`
- [ ] FIFO queue behavior (push/pop)
- [ ] Persistencia en disco
- [ ] Tests unitarios

## Criterios de Aceptación

- [ ] Push/Pop funciona en orden FIFO
- [ ] Datos persisten entre reinicios
- [ ] Performance: < 1ms por operación
- [ ] Tests pasan

## Código de Referencia

```rust
// storage/sled_adapter.rs
use sled::Db;
use synapse_core::ports::BufferPort;
use synapse_core::entities::Interaction;

pub struct SledAdapter {
    db: Db,
    counter: AtomicU64,
}

impl SledAdapter {
    pub fn new(path: &str) -> Result<Self, InfraError> {
        let db = sled::open(path)?;
        let counter = AtomicU64::new(0);
        Ok(Self { db, counter })
    }
}

#[async_trait]
impl BufferPort for SledAdapter {
    async fn push(&self, interaction: Interaction) -> Result<(), CoreError> {
        let key = self.counter.fetch_add(1, Ordering::SeqCst);
        let value = serde_json::to_vec(&interaction)?;
        self.db.insert(key.to_be_bytes(), value)?;
        Ok(())
    }
    
    async fn pop_batch(&self, size: usize) -> Result<Vec<Interaction>, CoreError> {
        let mut results = Vec::with_capacity(size);
        for item in self.db.iter().take(size) {
            let (key, value) = item?;
            let interaction: Interaction = serde_json::from_slice(&value)?;
            results.push(interaction);
            self.db.remove(key)?;
        }
        Ok(results)
    }
}
```

## Dependencias
- Requiere: FEAT_define-core-ports

## Referencia
- `.✨/ARCHITECTURE.md` - Buffer Store: Sled
