<#
.SYNOPSIS
    Sincroniza issues locales (.md) con GitHub Issues

.DESCRIPTION
    - Crea issues en GitHub desde archivos .md en .github/issues/
    - Elimina archivos .md cuando los issues se cierran
    - Mantiene un mapeo issue_number <-> archivo

.EXAMPLE
    ./sync-issues.ps1
    ./sync-issues.ps1 -Push    # Solo crear issues desde .md
    ./sync-issues.ps1 -Pull    # Solo limpiar issues cerrados
    ./sync-issues.ps1 -Watch   # Modo watch continuo
#>

param(
    [switch]$Push,      # Solo crear issues desde .md
    [switch]$Pull,      # Solo limpiar issues cerrados
    [switch]$Watch,     # Modo watch
    [switch]$DryRun,    # No ejecutar, solo mostrar
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$IssuesDir = ".github/issues"
$MappingFile = ".github/issues/.issue-mapping.json"

# Colores
function Write-Success { param($msg) Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "ℹ️  $msg" -ForegroundColor Cyan }
function Write-Warn { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Write-Err { param($msg) Write-Host "❌ $msg" -ForegroundColor Red }

# Verificar gh CLI
function Test-GhCli {
    try {
        $null = gh --version
        return $true
    } catch {
        Write-Err "GitHub CLI (gh) no está instalado o no está en PATH"
        Write-Info "Instala con: winget install GitHub.cli"
        return $false
    }
}

# Cargar mapeo existente
function Get-IssueMapping {
    if (Test-Path $MappingFile) {
        return Get-Content $MappingFile | ConvertFrom-Json -AsHashtable
    }
    return @{}
}

# Guardar mapeo
function Save-IssueMapping {
    param([hashtable]$Mapping)
    $Mapping | ConvertTo-Json -Depth 10 | Set-Content $MappingFile -Encoding UTF8
}

# Parsear frontmatter YAML del archivo .md
function Get-IssueFrontmatter {
    param([string]$FilePath)

    $content = Get-Content $FilePath -Raw -Encoding UTF8

    # Extraer frontmatter entre ---
    if ($content -match "(?s)^---\r?\n(.+?)\r?\n---\r?\n(.*)$") {
        $frontmatter = $matches[1]
        $body = $matches[2].Trim()

        $data = @{
            title = ""
            labels = @()
            assignees = @()
            body = $body
        }

        # Parsear YAML simple
        foreach ($line in $frontmatter -split "`n") {
            $line = $line.Trim()
            if ($line -match '^title:\s*"?([^"]+)"?') {
                $data.title = $matches[1].Trim()
            }
            elseif ($line -match '^labels:') {
                # Continuar parseando lista
            }
            elseif ($line -match '^\s*-\s*(.+)') {
                # Item de lista (labels o assignees)
                $item = $matches[1].Trim().Trim('"')
                if ($data._parsing -eq "labels") {
                    $data.labels += $item
                } elseif ($data._parsing -eq "assignees") {
                    $data.assignees += $item
                }
            }

            # Detectar inicio de listas
            if ($line -match '^labels:') { $data._parsing = "labels" }
            elseif ($line -match '^assignees:') { $data._parsing = "assignees" }
            elseif ($line -match '^\w+:' -and $line -notmatch '^\s*-') { $data._parsing = $null }
        }

        $data.Remove("_parsing")
        return $data
    }

    # Sin frontmatter, usar nombre de archivo como título
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    return @{
        title = $fileName -replace "_", ": " -replace "-", " "
        labels = @("ai-plan")
        assignees = @()
        body = $content
    }
}

# Crear issue en GitHub desde archivo .md
function New-GitHubIssueFromFile {
    param([string]$FilePath)

    $data = Get-IssueFrontmatter -FilePath $FilePath
    $fileName = [System.IO.Path]::GetFileName($FilePath)

    if ([string]::IsNullOrWhiteSpace($data.title)) {
        Write-Warn "Archivo $fileName sin título, saltando..."
        return $null
    }

    Write-Info "Creando issue: $($data.title)"

    if ($DryRun) {
        Write-Warn "[DRY-RUN] Se crearía: $($data.title)"
        return @{ number = 0; url = "dry-run" }
    }

    # Construir comando
    $args = @("issue", "create", "--title", $data.title)

    # Agregar body desde archivo temporal
    $tempBody = [System.IO.Path]::GetTempFileName()
    $data.body | Set-Content $tempBody -Encoding UTF8
    $args += "--body-file", $tempBody

    # Labels
    foreach ($label in $data.labels) {
        if ($label -and $label -ne "") {
            $args += "--label", $label
        }
    }

    # Assignees
    foreach ($assignee in $data.assignees) {
        if ($assignee -and $assignee -ne "" -and $assignee -ne "@me") {
            $args += "--assignee", $assignee
        }
    }

    try {
        $result = & gh @args 2>&1
        Remove-Item $tempBody -ErrorAction SilentlyContinue

        # Extraer número del issue de la URL
        if ($result -match "/issues/(\d+)") {
            $issueNumber = [int]$matches[1]
            Write-Success "Issue #$issueNumber creado: $result"
            return @{ number = $issueNumber; url = $result }
        }

        Write-Err "No se pudo crear el issue: $result"
        return $null
    } catch {
        Remove-Item $tempBody -ErrorAction SilentlyContinue
        Write-Err "Error creando issue: $_"
        return $null
    }
}

# Obtener issues cerrados de GitHub
function Get-ClosedIssues {
    param([int[]]$IssueNumbers)

    $closed = @()
    foreach ($num in $IssueNumbers) {
        try {
            $state = gh issue view $num --json state --jq ".state" 2>$null
            if ($state -eq "CLOSED") {
                $closed += $num
            }
        } catch {
            # Issue no existe o error
            $closed += $num
        }
    }
    return $closed
}

# Push: Crear issues desde archivos .md
function Invoke-Push {
    Write-Info "🔄 Sincronizando archivos .md → GitHub Issues..."

    $mapping = Get-IssueMapping
    $files = Get-ChildItem -Path $IssuesDir -Filter "*.md" -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -notmatch "^_" -and $_.Name -ne ".gitkeep" }

    $created = 0
    foreach ($file in $files) {
        $relativePath = $file.Name

        # Verificar si ya existe en el mapeo
        if ($mapping.ContainsKey($relativePath)) {
            if ($Verbose) { Write-Info "  ⏭️  $relativePath ya mapeado a #$($mapping[$relativePath])" }
            continue
        }

        # Crear issue
        $result = New-GitHubIssueFromFile -FilePath $file.FullName
        if ($result -and $result.number -gt 0) {
            $mapping[$relativePath] = $result.number
            $created++

            # Agregar comentario al archivo indicando el número
            $content = Get-Content $file.FullName -Raw -Encoding UTF8
            if ($content -notmatch "github_issue:") {
                $content = $content -replace "(^---)", "`$1`ngithub_issue: $($result.number)"
                $content | Set-Content $file.FullName -Encoding UTF8
            }
        }
    }

    Save-IssueMapping $mapping
    Write-Success "Push completado: $created issues creados"
}

# Pull: Eliminar archivos de issues cerrados
function Invoke-Pull {
    Write-Info "🔄 Limpiando archivos de issues cerrados..."

    $mapping = Get-IssueMapping
    if ($mapping.Count -eq 0) {
        Write-Info "No hay issues mapeados"
        return
    }

    $issueNumbers = @($mapping.Values | ForEach-Object { [int]$_ })
    $closedIssues = Get-ClosedIssues -IssueNumbers $issueNumbers

    $deleted = 0
    foreach ($kvp in @($mapping.GetEnumerator())) {
        $fileName = $kvp.Key
        $issueNum = [int]$kvp.Value

        if ($closedIssues -contains $issueNum) {
            $filePath = Join-Path $IssuesDir $fileName

            if ($DryRun) {
                Write-Warn "[DRY-RUN] Se eliminaría: $fileName (issue #$issueNum cerrado)"
            } else {
                if (Test-Path $filePath) {
                    Remove-Item $filePath -Force
                    Write-Success "Eliminado: $fileName (issue #$issueNum cerrado)"
                }
                $mapping.Remove($fileName)
            }
            $deleted++
        }
    }

    if (-not $DryRun) {
        Save-IssueMapping $mapping
    }
    Write-Success "Pull completado: $deleted archivos eliminados"
}

# Modo Watch
function Invoke-Watch {
    Write-Info "👁️  Modo watch activado (Ctrl+C para salir)..."

    while ($true) {
        Invoke-Push
        Invoke-Pull
        Write-Info "Esperando 60 segundos..."
        Start-Sleep -Seconds 60
    }
}

# Main
if (-not (Test-GhCli)) {
    exit 1
}

# Asegurar que el directorio existe
if (-not (Test-Path $IssuesDir)) {
    New-Item -ItemType Directory -Path $IssuesDir -Force | Out-Null
}

if ($Watch) {
    Invoke-Watch
} elseif ($Push -and -not $Pull) {
    Invoke-Push
} elseif ($Pull -and -not $Push) {
    Invoke-Pull
} else {
    # Por defecto, hacer ambos
    Invoke-Push
    Invoke-Pull
}

Write-Host "`n📋 Mapeo actual:" -ForegroundColor Cyan
$mapping = Get-IssueMapping
if ($mapping.Count -eq 0) {
    Write-Info "  (vacío)"
} else {
    foreach ($kvp in $mapping.GetEnumerator()) {
        Write-Host "  $($kvp.Key) → #$($kvp.Value)" -ForegroundColor Gray
    }
}
