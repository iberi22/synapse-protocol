---
description: "Crea un nuevo issue siguiendo el Git-Core Protocol"
---

# Crear Issue

Voy a crear un issue para trackear esta tarea.

1. **Pregúntame:**
   - ¿Qué título le ponemos al issue?
   - ¿Es un bug, feature, o task?
   - ¿Alguna etiqueta específica?

2. **Crea el archivo** en `.github/issues/` con formato:
   - `FEAT_descripcion.md` para features
   - `BUG_descripcion.md` para bugs
   - `TASK_descripcion.md` para tareas

3. **Formato del archivo:**
```markdown
---
title: "Título del Issue"
labels:
  - enhancement
assignees: []
---

## Descripción
[Descripción aquí]

## Tareas
- [ ] Tarea 1
- [ ] Tarea 2
```

4. **Sincronizar:** El issue se creará automáticamente en GitHub en el próximo push, o ejecuta:
   ```powershell
   ./scripts/sync-issues.ps1
   ```
