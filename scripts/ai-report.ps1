<#
.SYNOPSIS
    Genera reportes de AI para PRs usando Gemini CLI y GitHub Copilot CLI.

.DESCRIPTION
    Este script genera análisis automáticos de PRs usando:
    - Gemini CLI: Análisis técnico del diff
    - GitHub Copilot CLI: Análisis con Claude Sonnet 4.5

    Los reportes se agregan como comentarios al PR.

.PARAMETER PrNumber
    Número del PR a analizar. Si no se especifica, usa el PR del branch actual.

.PARAMETER ReportType
    Tipo de reporte: 'full' (ambos), 'gemini', 'copilot'. Default: 'full'

.PARAMETER Model
    Modelo para Copilot CLI. Default: 'claude-sonnet-4.5'
    Opciones: claude-sonnet-4.5, claude-opus-4.5, claude-haiku-4.5, gpt-5.1, gpt-5.1-codex

.PARAMETER DryRun
    Muestra el reporte sin agregarlo al PR.

.EXAMPLE
    .\scripts\ai-report.ps1
    .\scripts\ai-report.ps1 -PrNumber 42
    .\scripts\ai-report.ps1 -ReportType copilot -Model claude-opus-4.5
    .\scripts\ai-report.ps1 -ReportType gemini -DryRun
#>

param(
    [int]$PrNumber,
    [ValidateSet('full', 'gemini', 'copilot')]
    [string]$ReportType = 'full',
    [ValidateSet('claude-sonnet-4.5', 'claude-opus-4.5', 'claude-haiku-4.5', 'gpt-5.1', 'gpt-5.1-codex')]
    [string]$Model = 'claude-sonnet-4.5',
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Colores
function Write-Info { Write-Host "ℹ️  $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Warn { Write-Host "⚠️  $args" -ForegroundColor Yellow }
function Write-Err { Write-Host "❌ $args" -ForegroundColor Red }

# Verificar dependencias
function Test-Dependencies {
    $missing = @()

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        $missing += "gh (GitHub CLI)"
    }

    if ($ReportType -in @('full', 'gemini')) {
        if (-not (Get-Command gemini -ErrorAction SilentlyContinue)) {
            $missing += "gemini (Gemini CLI)"
        }
    }

    if ($ReportType -in @('full', 'copilot')) {
        if (-not (Get-Command copilot -ErrorAction SilentlyContinue)) {
            $missing += "copilot (@github/copilot - npm install -g @github/copilot)"
        }
    }

    if ($missing.Count -gt 0) {
        Write-Err "Dependencias faltantes: $($missing -join ', ')"
        exit 1
    }
}

# Obtener PR number del branch actual
function Get-CurrentPrNumber {
    try {
        $pr = gh pr view --json number 2>$null | ConvertFrom-Json
        return $pr.number
    } catch {
        return $null
    }
}

# Generar reporte con Gemini
function Get-GeminiReport {
    param([string]$Diff, [string]$Title, [string]$Body)

    Write-Info "Generando análisis con Gemini CLI..."

    $prompt = @"
Analiza este Pull Request y genera un reporte técnico conciso en español.

## PR: $Title

### Descripción
$Body

### Cambios (Diff)
``````diff
$Diff
``````

## Formato del Reporte

### 🔍 Resumen de Cambios
(Lista los cambios principales en bullets)

### 📊 Análisis de Impacto
(Evalúa el impacto: Alto/Medio/Bajo y explica por qué)

### ⚠️ Posibles Riesgos
(Lista riesgos potenciales o "Ninguno identificado")

### ✅ Recomendaciones
(Sugerencias para el reviewer)

### 🏷️ Etiquetas Sugeridas
(Sugiere labels apropiados: bug, enhancement, breaking-change, etc.)
"@

    try {
        $report = gemini -p $prompt -o text 2>&1
        return $report
    } catch {
        Write-Warn "Error ejecutando Gemini: $_"
        return $null
    }
}

# Generar reporte con Copilot CLI (nuevo agentic CLI)
function Get-CopilotReport {
    param([string]$Diff, [string]$Title, [string]$Body, [string]$Model)

    Write-Info "Generando análisis con GitHub Copilot CLI (modelo: $Model)..."

    # Truncar diff si es muy largo (límite ~8000 chars para el prompt)
    $maxDiffLength = 6000
    $truncatedDiff = if ($Diff.Length -gt $maxDiffLength) {
        $Diff.Substring(0, $maxDiffLength) + "`n... [diff truncado por longitud]"
    } else {
        $Diff
    }

    $prompt = @"
Analiza este Pull Request y genera un reporte técnico conciso en español.

## PR: $Title

### Descripción
$Body

### Cambios (Diff)
$truncatedDiff

## Genera un reporte con:
1. **Resumen de Cambios** (bullets concisos)
2. **Análisis de Impacto** (Alto/Medio/Bajo con justificación)
3. **Posibles Riesgos** (o "Ninguno identificado")
4. **Recomendaciones** para el reviewer
5. **Etiquetas Sugeridas** (bug, enhancement, breaking-change, etc.)

Sé directo y técnico. No uses markdown headers con #.
"@

    try {
        # Usar copilot en modo prompt (-p) con modelo especificado y modo silencioso (-s)
        $report = copilot -p $prompt --model $Model -s --allow-all-tools 2>&1
        return $report
    } catch {
        Write-Warn "Error ejecutando Copilot CLI: $_"
        return $null
    }
}

# Main
Test-Dependencies

# Determinar PR
if (-not $PrNumber) {
    $PrNumber = Get-CurrentPrNumber
    if (-not $PrNumber) {
        Write-Err "No se encontró PR para el branch actual. Usa -PrNumber <numero>"
        exit 1
    }
}

Write-Info "Analizando PR #$PrNumber..."

# Obtener datos del PR
try {
    $prData = gh pr view $PrNumber --json title,body,additions,deletions,changedFiles | ConvertFrom-Json
    $diff = gh pr diff $PrNumber
} catch {
    Write-Err "Error obteniendo datos del PR: $_"
    exit 1
}

Write-Info "PR: $($prData.title)"
Write-Info "Archivos: $($prData.changedFiles) | +$($prData.additions) -$($prData.deletions)"

# Generar reportes
$report = @()
$report += "## 🤖 AI Analysis Report"
$report += ""
$report += "> Generado automáticamente por Git-Core Protocol"
$report += ""

if ($ReportType -in @('full', 'gemini')) {
    $geminiReport = Get-GeminiReport -Diff $diff -Title $prData.title -Body $prData.body
    if ($geminiReport) {
        $report += "### 🔮 Gemini Analysis"
        $report += ""
        $report += $geminiReport
        $report += ""
    }
}

if ($ReportType -in @('full', 'copilot')) {
    $copilotReport = Get-CopilotReport -Diff $diff -Title $prData.title -Body $prData.body -Model $Model
    if ($copilotReport) {
        $report += "### 🤖 Copilot Analysis ($Model)"
        $report += ""
        $report += $copilotReport
        $report += ""
    }
}

$report += "---"
$report += "*Report generated at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')*"

$fullReport = $report -join "`n"

if ($DryRun) {
    Write-Warn "DRY RUN - Reporte generado (no se agregará al PR):"
    Write-Host ""
    Write-Host $fullReport
} else {
    # Agregar comentario al PR
    Write-Info "Agregando reporte al PR #$PrNumber..."

    $tempReportFile = [System.IO.Path]::GetTempFileName()
    $fullReport | Out-File -FilePath $tempReportFile -Encoding UTF8

    try {
        gh pr comment $PrNumber --body-file $tempReportFile
        Write-Success "Reporte agregado al PR #$PrNumber"
    } catch {
        Write-Err "Error agregando comentario: $_"
        Write-Host $fullReport
    } finally {
        Remove-Item $tempReportFile -ErrorAction SilentlyContinue
    }
}

Write-Success "¡Análisis completado!"
