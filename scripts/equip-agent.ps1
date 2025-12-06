<#
.SYNOPSIS
    Equips the AI agent with a specific Role (Recipe) by downloading it from GitHub.

.DESCRIPTION
    This script acts as the "Context Injector" for the AI. It:
    1. Looks up the requested Role in .✨/AGENT_INDEX.md.
    2. Extracts the recipe path.
    3. Downloads the recipe content from the remote repository.
    4. Appends standard protocol skills (Atomic Commits, Architecture).
    5. Generates a temporary context file for the agent to read.

.PARAMETER Role
    The name of the role to load (e.g., "Backend Architect", "frontend-developer").
    Partial matches are accepted.

.EXAMPLE
    ./scripts/equip-agent.ps1 -Role "backend"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$Role
)

$RepoBaseUrl = "https://raw.githubusercontent.com/iberi22/agents-flows-recipes/main"
$ConfigDir = ".✨"
$ContextFile = "$ConfigDir\CURRENT_CONTEXT.md"
$IndexFile = "$ConfigDir\AGENT_INDEX.md"

# Ensure Config Directory exists
if (-not (Test-Path $ConfigDir)) {
    Write-Error "❌ Configuration directory '$ConfigDir' not found."
    exit 1
}

Write-Host "🔍 Searching for role '$Role' in $IndexFile..." -ForegroundColor Cyan

# 1. Read Index and Find Role
if (-not (Test-Path $IndexFile)) {
    Write-Error "❌ Index file '$IndexFile' not found."
    exit 1
}

$IndexContent = Get-Content $IndexFile

# Find the line matching the role (case-insensitive match on the row)
# Regex looks for: | **...Role...** |
$MatchLine = $IndexContent | Where-Object { $_ -match "\|\s*\*\*.*$Role.*\*\*\s*\|" } | Select-Object -First 1

if (-not $MatchLine) {
    Write-Error "❌ Role '$Role' not found in $IndexFile."
    Write-Host "Available roles can be found in $IndexFile"
    exit 1
}

# 2. Extract Path
# The table format is: | **Role** | Desc | `path` | Skills |
# We extract the content inside the first pair of backticks that looks like a path
if ($MatchLine -match "`([^`]+)`") {
    $RecipePath = $Matches[1]
} else {
    Write-Error "❌ Could not extract recipe path from line: $MatchLine"
    exit 1
}

Write-Host "✅ Found Recipe Path: $RecipePath" -ForegroundColor Green

# 3. Download Recipe
$RecipeUrl = "$RepoBaseUrl/$RecipePath"
Write-Host "⬇️ Downloading from: $RecipeUrl" -ForegroundColor Cyan

try {
    $RecipeContent = Invoke-RestMethod -Uri $RecipeUrl -Method Get
} catch {
    Write-Error "❌ Failed to download recipe: $_"
    exit 1
}

# 4. Build Context
$Header = @"
# 🎭 ACTIVE AGENT PERSONA: $Role
> GENERATED CONTEXT - DO NOT EDIT MANUALLY
> Loaded at: $(Get-Date)

---
"@

$ProtocolSkills = @"

---
## 🛡️ MANDATORY PROTOCOL SKILLS
1. **Token Economy:** Use GitHub Issues for state. No TODO.md.
2. **Architecture First:** Verify against .✨/ARCHITECTURE.md.
3. **Atomic Commits:** One logical change per commit.
"@

# 5. Output to Context File
$FinalContext = $Header + "`n" + $RecipeContent + "`n" + $ProtocolSkills
Set-Content -Path $ContextFile -Value $FinalContext -Encoding UTF8

Write-Host "✨ Agent Equipped! Context written to $ContextFile" -ForegroundColor Yellow
Write-Host "🤖 INSTRUCTION: Read .✨/CURRENT_CONTEXT.md to assume your new role." -ForegroundColor Magenta
