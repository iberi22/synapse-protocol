---
description: "Guía rápida del Git-Core Protocol"
---

# Git-Core Protocol - Guía Rápida

## 🎯 Regla Principal
**Tu estado es GitHub Issues, no memoria, no archivos.**

## ⛔ NUNCA crear estos archivos:
- TODO.md, TASKS.md, PLANNING.md, ROADMAP.md
- PROGRESS.md, NOTES.md, CHECKLIST.md
- Cualquier .md para tracking de tareas

## ✅ Cómo trabajar:

### Crear una tarea:
```powershell
# Opción 1: Crear archivo
# .github/issues/FEAT_mi-feature.md

# Opción 2: Comando directo
gh issue create --title "Mi tarea" --label "enhancement"
```

### Antes de codear:
```powershell
cat .✨/ARCHITECTURE.md          # Leer decisiones
gh issue list --assignee "@me"   # Ver mis tareas
```

### Al commitear:
```powershell
git commit -m "feat(scope): descripción #123"
```

## 📚 Prompts disponibles:
- `#prompt:issue` - Crear un issue
- `#prompt:update` - Actualizar protocolo
- `#prompt:status` - Ver estado del protocolo
