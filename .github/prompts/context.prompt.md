---
description: "🚀 Cargar contexto completo (usar al inicio de sesión)"
---

# Cargar Contexto

Ejecuta y analiza:

```powershell
# Estado Git
git status --porcelain
git log --oneline -3
git branch --show-current

# GitHub
gh issue list --state open --limit 10
gh pr list --state open --limit 5
```

Resume en formato compacto:

```
📊 ESTADO: [branch] | [archivos] | [commits sin push]
📋 ISSUES: #N título, #N título...
📤 PRs: #N título...
🎯 SIGUIENTE: [acción sugerida]
```
