---
description: "Verifica el estado del Git-Core Protocol en este proyecto"
---

# Verificar Estado del Protocolo

Ejecuta estos comandos para verificar el estado:

```powershell
# Ver versión actual
Get-Content .git-core-protocol-version

# Comparar con versión remota
$remote = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/iberi22/Git-Core-Protocol/main/.git-core-protocol-version" -UseBasicParsing).Content.Trim()
$local = Get-Content .git-core-protocol-version -ErrorAction SilentlyContinue
Write-Host "Local: $local | Remoto: $remote"

# Verificar archivos del protocolo
Test-Path ".✨/ARCHITECTURE.md"
Test-Path "AGENTS.md"
Test-Path ".github/copilot-instructions.md"
```

Si hay una nueva versión, usa `#prompt:update` para actualizar.
