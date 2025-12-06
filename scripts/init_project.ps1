# scripts/init_project.ps1
# 🧠 Git-Core Protocol - Project Initializer (PowerShell)
#
# Options:
#   -Organize    Organize existing files before setup
#   -Auto        Non-interactive mode (auto-accept defaults)
#   -Private     Create private repository (default: public)
#
# Usage:
#   .\init_project.ps1
#   .\init_project.ps1 -Organize
#   .\init_project.ps1 -Auto -Organize -Private

param(
    [switch]$Organize,
    [switch]$Auto,
    [switch]$Private
)

$ErrorActionPreference = "Stop"

# Function to organize existing files
function Invoke-OrganizeFiles {
    Write-Host "`n📂 Organizing existing files..." -ForegroundColor Yellow

    # Create directories
    $dirs = @("docs/archive", "scripts", "tests", "src")
    foreach ($dir in $dirs) {
        New-Item -ItemType Directory -Force -Path $dir -ErrorAction SilentlyContinue | Out-Null
    }

    # Files to keep in root
    $keepInRoot = @("README.md", "AGENTS.md", "CHANGELOG.md", "CONTRIBUTING.md", "LICENSE.md", "LICENSE")

    # Move markdown files to docs/archive
    Get-ChildItem -Filter "*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -notin $keepInRoot) {
            Move-Item $_.FullName -Destination "docs/archive/" -Force -ErrorAction SilentlyContinue
            Write-Host "  → $($_.Name) moved to docs/archive/" -ForegroundColor Cyan
        } else {
            Write-Host "  ✓ Keeping $($_.Name) in root" -ForegroundColor Green
        }
    }

    # Move test files
    $testPatterns = @("test_*.py", "*_test.py", "*.test.js", "*.test.ts", "*.spec.js", "*.spec.ts")
    foreach ($pattern in $testPatterns) {
        Get-ChildItem -Filter $pattern -File -ErrorAction SilentlyContinue | ForEach-Object {
            Move-Item $_.FullName -Destination "tests/" -Force -ErrorAction SilentlyContinue
            Write-Host "  → $($_.Name) moved to tests/" -ForegroundColor Cyan
        }
    }

    # Move loose scripts (except init scripts)
    $scriptKeep = @("install.sh")
    Get-ChildItem -Filter "*.sh" -File -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -notin $scriptKeep -and $_.DirectoryName -eq (Get-Location).Path) {
            Move-Item $_.FullName -Destination "scripts/" -Force -ErrorAction SilentlyContinue
            Write-Host "  → $($_.Name) moved to scripts/" -ForegroundColor Cyan
        }
    }
    Get-ChildItem -Filter "*.bat" -File -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.DirectoryName -eq (Get-Location).Path) {
            Move-Item $_.FullName -Destination "scripts/" -Force -ErrorAction SilentlyContinue
            Write-Host "  → $($_.Name) moved to scripts/" -ForegroundColor Cyan
        }
    }

    Write-Host "✅ Files organized" -ForegroundColor Green
}

Write-Host "🧠 Initializing Git-Core Protocol..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Run organize if requested
if ($Organize) {
    Invoke-OrganizeFiles
}

# 1. Validate environment
Write-Host "`n📋 Validating environment..." -ForegroundColor Yellow

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: Git is not installed." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Git installed" -ForegroundColor Green

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: GitHub CLI (gh) is not installed." -ForegroundColor Red
    Write-Host "  Install from: https://cli.github.com/" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ GitHub CLI installed" -ForegroundColor Green

# Check if gh is authenticated
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error: Not authenticated with GitHub CLI." -ForegroundColor Red
    Write-Host "  Run: gh auth login" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ GitHub CLI authenticated" -ForegroundColor Green

# Check for Codex CLI (optional but recommended)
if (Get-Command codex -ErrorAction SilentlyContinue) {
    Write-Host "✓ Codex CLI installed" -ForegroundColor Green
} else {
    Write-Host "⚠️  Codex CLI not found (optional)" -ForegroundColor Yellow
    if (-not $Auto) {
        $installCodex = Read-Host "  Install Codex CLI for AI automation? (y/N)"
        if ($installCodex -eq "y" -or $installCodex -eq "Y") {
            Write-Host "  Installing Codex CLI..." -ForegroundColor Cyan
            if (Get-Command npm -ErrorAction SilentlyContinue) {
                npm install -g @openai/codex
                Write-Host "✓ Codex CLI installed" -ForegroundColor Green
            } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
                winget install --id OpenAI.Codex -e
                Write-Host "✓ Codex CLI installed" -ForegroundColor Green
            } else {
                Write-Host "  ⚠️  Please install manually: npm i -g @openai/codex" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "  Install with: npm i -g @openai/codex" -ForegroundColor Cyan
    }
}

# 2. Get project name
$PROJECT_NAME = Split-Path -Leaf (Get-Location)
Write-Host "`n📁 Project: $PROJECT_NAME" -ForegroundColor Yellow

# 3. Check if this is an existing Git repository
$EXISTING_REPO = $false
$SKIP_REPO_CREATE = $false

if (Test-Path ".git") {
    $EXISTING_REPO = $true
    Write-Host "ℹ️  Existing Git repository detected" -ForegroundColor Cyan

    # Check if remote already exists
    $remoteUrl = git remote get-url origin 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Remote 'origin' already configured" -ForegroundColor Green
        Write-Host "  $remoteUrl" -ForegroundColor Cyan
        $SKIP_REPO_CREATE = $true
    }
} else {
    Write-Host "`n🔧 Initializing Git repository..." -ForegroundColor Yellow
    # Ensure default branch is 'main' (works with older Git versions)
    git config --global init.defaultBranch main 2>$null
    git init
    git branch -M main  # Rename to main if needed (for older Git versions)
    git add .
    git commit -m "feat: 🚀 Initial commit with Git-Core Protocol"
}

# 4. Create GitHub repository (if needed)
if (-not $SKIP_REPO_CREATE) {
    Write-Host "`n☁️  Creating GitHub repository..." -ForegroundColor Yellow

    if ($Auto) {
        if ($Private) {
            $VISIBILITY = "--private"
            Write-Host "  (Auto mode: creating private repository)" -ForegroundColor Cyan
        } else {
            $VISIBILITY = "--public"
            Write-Host "  (Auto mode: creating public repository)" -ForegroundColor Cyan
        }
    } else {
        $PRIVATE_CHOICE = Read-Host "Private repository? (y/N)"
        if ($PRIVATE_CHOICE -match "^[Yy]$") {
            $VISIBILITY = "--private"
        } else {
            $VISIBILITY = "--public"
        }
    }

    Invoke-Expression "gh repo create $PROJECT_NAME $VISIBILITY --source=. --remote=origin --push"
} else {
    Write-Host "`nℹ️  Skipping repository creation (already exists)" -ForegroundColor Cyan

    # Check for uncommitted changes
    $status = git status --porcelain
    if ($status) {
        Write-Host "⚠️  Uncommitted changes detected, committing..." -ForegroundColor Yellow
        git add .
        git commit -m "chore: 🧠 Add Git-Core Protocol configuration"
        git push origin HEAD
    }
}

# 5. Setup Architecture file if empty
$archFile = ".ai/ARCHITECTURE.md"
if (-not (Test-Path $archFile) -or (Get-Item $archFile).Length -eq 0) {
    Write-Host "`n📐 Setting up ARCHITECTURE.md..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path ".ai" | Out-Null
    @"
# 🏗️ Architecture

## Stack
- **Language:** TBD
- **Framework:** TBD
- **Database:** TBD

## Key Decisions
_Document architectural decisions here_

## Project Structure
``````
TBD
``````
"@ | Set-Content $archFile -Encoding UTF8
}

# 6. Create Semantic Labels for AI
Write-Host "`n🏷️  Creating semantic labels..." -ForegroundColor Yellow

function Create-Label {
    param($name, $description, $color)

    $existingLabels = gh label list --json name | ConvertFrom-Json
    if ($existingLabels.name -notcontains $name) {
        gh label create $name --description $description --color $color 2>$null
        Write-Host "  ✓ $name" -ForegroundColor Green
    } else {
        Write-Host "  ~ $name (already exists)" -ForegroundColor Yellow
    }
}

Create-Label "ai-plan" "High-level planning tasks" "0E8A16"
Create-Label "ai-context" "Critical context information" "FBCA04"
Create-Label "ai-blocked" "Blocked - requires human intervention" "D93F0B"
Create-Label "in-progress" "Task in progress" "1D76DB"
Create-Label "needs-review" "Requires review" "5319E7"

# 7. Create Initial Issues
Write-Host "`n📝 Checking for existing issues..." -ForegroundColor Yellow

# Check if repo already has issues
$existingIssues = gh issue list --state all --limit 1 --json number 2>$null | ConvertFrom-Json
$SKIP_ISSUES = $false

if ($existingIssues -and $existingIssues.Count -gt 0) {
    $issueCount = (gh issue list --state all --json number | ConvertFrom-Json).Count
    Write-Host "⚠️  This repository already has $issueCount issue(s)" -ForegroundColor Yellow

    if ($Auto) {
        Write-Host "  (Auto mode: skipping issue creation)" -ForegroundColor Cyan
        $SKIP_ISSUES = $true
    } else {
        $createChoice = Read-Host "Create initial planning issues anyway? (y/N)"
        if ($createChoice -notmatch "^[Yy]$") {
            $SKIP_ISSUES = $true
            Write-Host "ℹ️  Skipping issue creation" -ForegroundColor Cyan
        }
    }
}

if (-not $SKIP_ISSUES) {
    Write-Host "`n📝 Creating initial issues..." -ForegroundColor Yellow

    gh issue create `
    --title "🏗️ SETUP: Define Architecture and Tech Stack" `
    --body @"
## Objective
Define and document the architectural decisions for the project.

## Tasks
- [ ] Define main language/framework
- [ ] Define database (if applicable)
- [ ] Define folder structure
- [ ] Document in ``.ai/ARCHITECTURE.md``

## Notes for AI Agent
Read project requirements and propose an appropriate stack.
"@ `
    --label "ai-plan"

gh issue create `
    --title "⚙️ INFRA: Initial development environment setup" `
    --body @"
## Objective
Set up development tools.

## Tasks
- [ ] Configure linter
- [ ] Configure formatter
- [ ] Configure pre-commit hooks (optional)
- [ ] Create base folder structure
- [ ] Add initial dependencies

## Notes for AI Agent
Use best practices for the chosen stack.
"@ `
    --label "ai-plan"

gh issue create `
    --title "📚 DOCS: Initial project documentation" `
    --body @"
## Objective
Create basic documentation.

## Tasks
- [ ] Update README.md with project description
- [ ] Document how to run the project
- [ ] Document how to contribute

## Notes for AI Agent
Keep documentation concise and practical.
"@ `
    --label "ai-plan"
}

# 8. Install pre-commit hooks for atomic commit validation
Write-Host "`n🪝 Installing pre-commit hooks..." -ForegroundColor Yellow

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$hooksInstaller = Join-Path $scriptDir "hooks/install-hooks.sh"
$preCommitHook = Join-Path $scriptDir "hooks/pre-commit"

# For PowerShell, we'll install the hooks directly
$gitHooksDir = Join-Path (Get-Location) ".git/hooks"
if (Test-Path ".git") {
    if (-not (Test-Path $gitHooksDir)) {
        New-Item -ItemType Directory -Force -Path $gitHooksDir | Out-Null
    }
    
    # Create the pre-commit wrapper
    $hookContent = @'
#!/bin/bash
# Git-Core Protocol pre-commit hook (git-core-protocol)
# This hook validates atomic commits based on .git-atomize.yml configuration
# Bypass with: git commit --no-verify

# Get repository root
REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOK_SCRIPT="$REPO_ROOT/scripts/hooks/pre-commit"

# Run the hook script if it exists
if [ -f "$HOOK_SCRIPT" ] && [ -x "$HOOK_SCRIPT" ]; then
    exec "$HOOK_SCRIPT"
elif [ -f "$HOOK_SCRIPT" ]; then
    exec bash "$HOOK_SCRIPT"
else
    # Hook script not found, skip validation
    echo "Note: scripts/hooks/pre-commit not found, skipping atomicity check"
    exit 0
fi
'@
    
    $preCommitPath = Join-Path $gitHooksDir "pre-commit"
    Set-Content -Path $preCommitPath -Value $hookContent -Encoding UTF8 -NoNewline
    
    # Copy example config if .git-atomize.yml doesn't exist
    $configExample = Join-Path (Get-Location) ".git-atomize.yml.example"
    $configFile = Join-Path (Get-Location) ".git-atomize.yml"
    if ((Test-Path $configExample) -and (-not (Test-Path $configFile))) {
        Copy-Item $configExample $configFile
        Write-Host "✓ Created .git-atomize.yml from example" -ForegroundColor Green
    }
    
    Write-Host "✓ Pre-commit hooks installed" -ForegroundColor Green
} else {
    Write-Host "⚠️  Could not install hooks (no .git directory)" -ForegroundColor Yellow
}

# 9. Final message
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "✅ Project initialized successfully!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
$username = (gh api user --jq .login)
Write-Host "📍 Repository: https://github.com/$username/$PROJECT_NAME" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Open the project in your AI editor (Cursor/Windsurf/VS Code)"
Write-Host "   2. Type: 'Start with the first assigned issue'"
Write-Host "   3. The agent will read the rules and begin working"
Write-Host ""
Write-Host "📋 Issues created:" -ForegroundColor Yellow
gh issue list --limit 5
