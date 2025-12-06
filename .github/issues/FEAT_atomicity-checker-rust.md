---
title: "Migrate commit-atomicity.yml to Rust (atomicity-checker)"
labels:
  - enhancement
  - rust
  - performance
  - ai-plan
assignees: []
---

## Descripción

Migrar las ~325 líneas de shell script del workflow `commit-atomicity.yml` a una herramienta Rust nativa de alto rendimiento.

## Motivación

- **Frecuencia**: Se ejecuta en **cada PR** (máxima frecuencia)
- **Complejidad**: Parsing complejo de Git logs, YAML config, regex
- **ROI estimado**: 10-50x más rápido, reduce tiempo CI significativamente

## Tareas

- [ ] Crear estructura del proyecto `tools/atomicity-checker/`
- [ ] Implementar CLI con clap (check, report, validate)
- [ ] Implementar parser de Git commits (git2-rs o command execution)
- [ ] Implementar parser de YAML config
- [ ] Implementar clasificador de archivos por "concern"
- [ ] Implementar generador de reportes (Markdown, JSON, Terminal)
- [ ] Actualizar workflow para usar el binario Rust
- [ ] Agregar al release de binarios pre-compilados
- [ ] Tests unitarios y de integración

## Funcionalidades a Migrar

```
┌─────────────────────────────────────────────────────────────┐
│                    SHELL → RUST MAPPING                     │
├─────────────────────────────────────────────────────────────┤
│ YAML Parsing (grep/sed)    → serde_yaml                     │
│ Git log parsing            → git2-rs / tokio::process       │
│ Bot detection (regex)      → regex crate                    │
│ File categorization        → Pattern matching               │
│ Associative arrays         → HashMap<String, Concern>       │
│ Report generation          → pulldown-cmark / custom        │
└─────────────────────────────────────────────────────────────┘
```

## Beneficios Esperados

| Métrica | Shell | Rust | Mejora |
|---------|-------|------|--------|
| Parse 100 commits | ~5-10s | ~0.1-0.5s | 10-50x |
| Memory usage | Variable | Predictable | ✓ |
| Error handling | Exit codes | Result types | ✓ |
| Paralelismo | Limited | Native async | ✓ |
| Testability | Hard | Easy | ✓ |
