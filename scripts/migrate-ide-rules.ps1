<#
.SYNOPSIS
    Migrates existing IDE rules to Git-Core Protocol without overwriting.

.DESCRIPTION
    Detects and parses rules from:
    - Antigravity IDE (.agent/rules/)
    - Cursor IDE (.cursorrules)
    - Windsurf (.windsurfrules)
    - GitHub Copilot (.github/copilot-instructions.md)

    Extracts content and merges into Git-Core Protocol structure.

.PARAMETER ProjectPath
    Path to the project to migrate.

.PARAMETER DryRun
    Show what would be done without making changes.

.PARAMETER Force
    Overwrite existing Git-Core files (not recommended).

.EXAMPLE
    ./migrate-ide-rules.ps1 -ProjectPath "C:\projects\my-app"
    ./migrate-ide-rules.ps1 -ProjectPath "." -DryRun
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURATION
# ============================================================================

$IDE_SOURCES = @{
    "Antigravity" = @{
        Path = ".agent/rules"
        Files = @("rule-0.md", "rule-*.md")
        Type = "markdown"
    }
    "Cursor" = @{
        Path = "."
        Files = @(".cursorrules")
        Type = "markdown"
    }
    "Windsurf" = @{
        Path = "."
        Files = @(".windsurfrules")
        Type = "markdown"
    }
    "Copilot" = @{
        Path = ".github"
        Files = @("copilot-instructions.md")
        Type = "markdown"
    }
}

# Classification patterns
$PATTERNS = @{
    Architecture = @(
        "arquitectura", "architecture", "stack", "backend", "frontend",
        "database", "hosting", "deployment", "infrastructure",
        "proveedor", "provider", "decision", "decisión"
    )
    Secrets = @(
        "ssh", "password", "key", "token", "secret", "credential",
        "api_key", "apikey", "private", "access_token"
    )
    AgentRules = @(
        "agente", "agent", "ia", "ai", "copilot", "cursor",
        "recomendacion", "recommendation", "evita", "avoid",
        "nunca", "never", "siempre", "always", "regla", "rule"
    )
    Commands = @(
        "npm run", "yarn", "pnpm", "comando", "command", "script",
        "build", "dev", "test", "start", "install"
    )
    Troubleshooting = @(
        "error", "falla", "fail", "debug", "buscar", "search",
        "cuando algo", "if something", "problema", "problem"
    )
}

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    $colors = @{
        "Info" = "Cyan"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error" = "Red"
        "DryRun" = "Magenta"
    }
    $prefix = @{
        "Info" = "ℹ️"
        "Success" = "✅"
        "Warning" = "⚠️"
        "Error" = "❌"
        "DryRun" = "🔍"
    }
    Write-Host "$($prefix[$Type]) $Message" -ForegroundColor $colors[$Type]
}

function Get-DetectedIDEs {
    param([string]$Path)

    $detected = @()

    foreach ($ide in $IDE_SOURCES.Keys) {
        $config = $IDE_SOURCES[$ide]
        $idePath = Join-Path $Path $config.Path

        if (Test-Path $idePath) {
            foreach ($filePattern in $config.Files) {
                $files = Get-ChildItem -Path $idePath -Filter $filePattern -ErrorAction SilentlyContinue
                if ($files) {
                    $detected += @{
                        IDE = $ide
                        Files = $files
                        Config = $config
                    }
                    break
                }
            }
        }
    }

    return $detected
}

function Get-SectionClassification {
    param([string]$Content)

    $contentLower = $Content.ToLower()
    $scores = @{}

    foreach ($category in $PATTERNS.Keys) {
        $score = 0
        foreach ($pattern in $PATTERNS[$category]) {
            if ($contentLower -match [regex]::Escape($pattern)) {
                $score++
            }
        }
        $scores[$category] = $score
    }

    # Return category with highest score
    $maxCategory = ($scores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
    $maxScore = $scores[$maxCategory]

    if ($maxScore -eq 0) {
        return "General"
    }

    return $maxCategory
}

function Split-MarkdownSections {
    param([string]$Content)

    $sections = @()
    $currentSection = @{
        Title = "Header"
        Content = ""
        Level = 0
    }

    $lines = $Content -split "`n"

    foreach ($line in $lines) {
        if ($line -match "^(#{1,6})\s+(.+)$") {
            # Save previous section
            if ($currentSection.Content.Trim()) {
                $sections += $currentSection
            }

            # Start new section
            $currentSection = @{
                Title = $Matches[2].Trim()
                Content = "$line`n"
                Level = $Matches[1].Length
            }
        }
        else {
            $currentSection.Content += "$line`n"
        }
    }

    # Don't forget last section
    if ($currentSection.Content.Trim()) {
        $sections += $currentSection
    }

    return $sections
}

function ConvertTo-ArchitectureSection {
    param([array]$Sections)

    $archContent = @"
## Project-Specific Decisions (Migrated from IDE Rules)

> These decisions were extracted from existing IDE configuration.

"@

    foreach ($section in $Sections) {
        $archContent += @"

### $($section.Title)
$($section.Content.Trim())

"@
    }

    return $archContent
}

function ConvertTo-AgentRulesSection {
    param([array]$Sections, [string]$IdeName)

    $rulesContent = @"

## Project-Specific Rules (from $IdeName)

> Migrated from existing $IdeName configuration.

"@

    foreach ($section in $Sections) {
        $rulesContent += @"

### $($section.Title)
$($section.Content.Trim())

"@
    }

    return $rulesContent
}

function Remove-SecretsFromContent {
    param([string]$Content)

    # Patterns to redact
    $redactPatterns = @(
        '(ssh\s+-i\s+)[^\s]+',
        '(password["\s:=]+)[^\s"]+',
        '(key["\s:=]+)[^\s"]+',
        '(token["\s:=]+)[^\s"]+',
        '(ghp_)[a-zA-Z0-9]+',
        '(sk-)[a-zA-Z0-9]+',
        '([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
    )

    $cleaned = $Content
    foreach ($pattern in $redactPatterns) {
        $cleaned = $cleaned -replace $pattern, '$1[REDACTED]'
    }

    return $cleaned
}

function New-ProtocolStructure {
    param([string]$Path)

    $dirs = @(
        ".✨",
        ".github/issues"
    )

    foreach ($dir in $dirs) {
        $fullPath = Join-Path $Path $dir
        if (-not (Test-Path $fullPath)) {
            if ($DryRun) {
                Write-Status "Would create directory: $dir" -Type "DryRun"
            }
            else {
                New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
                Write-Status "Created directory: $dir" -Type "Success"
            }
        }
    }
}

function Update-AntigravityRules {
    param(
        [string]$Path,
        [string]$RuleFile
    )

    $protocolImport = @"

---

## 🔗 Git-Core Protocol Integration

> This project follows the Git-Core Protocol. See root-level files for full configuration.

### Quick Reference
- **Architecture Decisions:** `.✨/ARCHITECTURE.md`
- **Agent Rules:** `AGENTS.md`
- **Issues:** `.github/issues/` or `gh issue list`

### Protocol Rules Apply
1. State = GitHub Issues (not memory, not files)
2. No TODO.md, PLANNING.md, etc.
3. Use `gh issue create` or `.github/issues/*.md`
4. Commits reference issues: `feat(scope): description #123`

"@

    $content = Get-Content $RuleFile -Raw

    # Check if already integrated
    if ($content -match "Git-Core Protocol Integration") {
        Write-Status "Antigravity rules already integrated with protocol" -Type "Warning"
        return
    }

    if ($DryRun) {
        Write-Status "Would append protocol integration to: $RuleFile" -Type "DryRun"
    }
    else {
        Add-Content -Path $RuleFile -Value $protocolImport
        Write-Status "Updated Antigravity rules with protocol integration" -Type "Success"
    }
}

# ============================================================================
# MAIN
# ============================================================================

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           Git-Core Protocol - IDE Rules Migration            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Resolve path
$ProjectPath = Resolve-Path $ProjectPath -ErrorAction Stop

Write-Status "Analyzing project: $ProjectPath"

# Detect existing IDEs
$detectedIDEs = Get-DetectedIDEs -Path $ProjectPath

if ($detectedIDEs.Count -eq 0) {
    Write-Status "No existing IDE configurations found" -Type "Warning"
    Write-Status "Will install fresh Git-Core Protocol" -Type "Info"
}
else {
    Write-Host ""
    Write-Status "Detected IDE configurations:" -Type "Info"
    foreach ($ide in $detectedIDEs) {
        Write-Host "  • $($ide.IDE): $($ide.Files.Name -join ', ')" -ForegroundColor White
    }
}

# Check for existing Git-Core Protocol
$hasProtocol = Test-Path (Join-Path $ProjectPath ".✨")
if ($hasProtocol -and -not $Force) {
    Write-Status "Git-Core Protocol already installed. Use -Force to re-migrate." -Type "Warning"
}

Write-Host ""

# Process each detected IDE
$archSections = @()
$agentSections = @()
$secretsFound = @()
$commandSections = @()

foreach ($ide in $detectedIDEs) {
    Write-Status "Processing $($ide.IDE) configuration..." -Type "Info"

    foreach ($file in $ide.Files) {
        $content = Get-Content $file.FullName -Raw
        $sections = Split-MarkdownSections -Content $content

        foreach ($section in $sections) {
            $classification = Get-SectionClassification -Content $section.Content

            Write-Host "    [$classification] $($section.Title)" -ForegroundColor DarkGray

            switch ($classification) {
                "Architecture" {
                    $archSections += $section
                }
                "Secrets" {
                    $secretsFound += @{
                        Section = $section
                        File = $file.Name
                    }
                    # Also add to agent rules but redacted
                    $section.Content = Remove-SecretsFromContent -Content $section.Content
                    $agentSections += $section
                }
                "AgentRules" {
                    $agentSections += $section
                }
                "Commands" {
                    $commandSections += $section
                }
                "Troubleshooting" {
                    $agentSections += $section
                }
                default {
                    $agentSections += $section
                }
            }
        }
    }
}

# Warn about secrets
if ($secretsFound.Count -gt 0) {
    Write-Host ""
    Write-Status "⚠️ SECRETS DETECTED - These should be in .env or secrets manager:" -Type "Warning"
    foreach ($secret in $secretsFound) {
        Write-Host "    • $($secret.Section.Title) in $($secret.File)" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Create protocol structure
Write-Host ""
Write-Status "Creating Git-Core Protocol structure..." -Type "Info"
New-ProtocolStructure -Path $ProjectPath

# Generate ARCHITECTURE.md content
if ($archSections.Count -gt 0) {
    $archPath = Join-Path $ProjectPath ".✨\ARCHITECTURE.md"

    if ((Test-Path $archPath) -and -not $Force) {
        # Append to existing
        $appendContent = ConvertTo-ArchitectureSection -Sections $archSections

        if ($DryRun) {
            Write-Status "Would append to ARCHITECTURE.md:" -Type "DryRun"
            Write-Host $appendContent.Substring(0, [Math]::Min(200, $appendContent.Length)) -ForegroundColor DarkGray
        }
        else {
            Add-Content -Path $archPath -Value $appendContent
            Write-Status "Updated ARCHITECTURE.md with extracted decisions" -Type "Success"
        }
    }
    else {
        # Will be created by main install
        Write-Status "Architecture sections will be added to ARCHITECTURE.md" -Type "Info"
    }
}

# Update Antigravity rules (don't delete, integrate)
$antigravity = $detectedIDEs | Where-Object { $_.IDE -eq "Antigravity" }
if ($antigravity) {
    foreach ($file in $antigravity.Files) {
        Update-AntigravityRules -Path $ProjectPath -RuleFile $file.FullName
    }
}

# Summary
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                      Migration Summary                       ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "  Sections classified:" -ForegroundColor White
Write-Host "    • Architecture decisions: $($archSections.Count)" -ForegroundColor Cyan
Write-Host "    • Agent rules: $($agentSections.Count)" -ForegroundColor Cyan
Write-Host "    • Commands/scripts: $($commandSections.Count)" -ForegroundColor Cyan
Write-Host "    • Secrets (redacted): $($secretsFound.Count)" -ForegroundColor Yellow

Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Review .✨/ARCHITECTURE.md for extracted decisions" -ForegroundColor Gray
Write-Host "    2. Move secrets to .env.local or secrets manager" -ForegroundColor Gray
Write-Host "    3. Run: git-core check" -ForegroundColor Gray
Write-Host ""

if ($DryRun) {
    Write-Status "DRY RUN - No changes were made. Run without -DryRun to apply." -Type "DryRun"
}
