---
title: "Setup Cargo Workspace structure"
labels:
  - core
  - rust
  - copilot
  - phase-1
assignees: ["copilot"]
---

## Descripción

Inicializar el workspace de Rust con arquitectura hexagonal para synapse-protocol.

## Tareas

- [ ] Crear `Cargo.toml` root con workspace members
- [ ] Crear `crates/synapse-core/Cargo.toml` (sin dependencias externas)
- [ ] Crear `crates/synapse-infra/Cargo.toml` (con LanceDB, Sled, ORT)
- [ ] Crear `crates/synapse-cli/Cargo.toml` (aplicación CLI)
- [ ] Verificar que `cargo check` pasa

## Criterios de Aceptación

- [ ] Workspace compila sin errores
- [ ] `synapse-core` NO tiene dependencias de `synapse-infra`
- [ ] Estructura hexagonal respetada

## Contexto Técnico

```toml
# Cargo.toml (root)
[workspace]
resolver = "2"
members = [
    "crates/synapse-core",
    "crates/synapse-infra",
    "crates/synapse-cli",
]

[workspace.package]
version = "0.1.0"
edition = "2021"
license = "AGPL-3.0-or-later"
```

## Referencia
- `.✨/ARCHITECTURE.md` - Estructura del proyecto
