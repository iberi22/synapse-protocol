---
description: "Actualiza el Git-Core Protocol a la última versión"
---

# Actualizar Git-Core Protocol

Ejecuta el siguiente comando para actualizar el protocolo a la última versión:

```powershell
$env:GIT_CORE_UPGRADE = "1"; irm https://raw.githubusercontent.com/iberi22/Git-Core-Protocol/main/install.ps1 | iex
```

O en Linux/macOS:
```bash
GIT_CORE_UPGRADE=1 curl -fsSL https://raw.githubusercontent.com/iberi22/Git-Core-Protocol/main/install.sh | bash
```

**Importante:** Tu archivo `.✨/ARCHITECTURE.md` será preservado automáticamente.

Después de actualizar:
1. Revisa los cambios con `git diff`
2. Commitea: `git add . && git commit -m "chore(protocol): upgrade Git-Core Protocol"`
