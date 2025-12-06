<#
.SYNOPSIS
    Generates a dynamic workspace-hub.agent.md with buttons for all projects

.DESCRIPTION
    Scans a workspace directory for Git repositories and generates
    a custom agent with handoff buttons for each project.

.PARAMETER WorkspacePath
    Path to the workspace root (default: parent of current directory)

.PARAMETER OutputPath
    Where to save the generated agent file

.EXAMPLE
    .\generate-workspace-agent.ps1 -WorkspacePath "e:\scripts-python"
#>

param(
    [string]$WorkspacePath = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputPath = "$PSScriptRoot\..\\.github\agents\workspace-hub.agent.md",
    [switch]$DryRun
)

# Project metadata for known projects
$projectMeta = @{
    "Git-Core Protocol" = @{ Icon = "🧠"; Tech = "Rust, Scripts"; Agent = "protocol-claude" }
    "Software Factory" = @{ Icon = "🏭"; Tech = "Astro"; Agent = "protocol-claude" }
    "CGP-Colegios" = @{ Icon = "🏫"; Tech = "Next.js, Supabase"; Agent = "protocol-claude" }
    "orionhealth" = @{ Icon = "💊"; Tech = "Flutter/Dart"; Agent = "protocol-claude" }
    "syn" = @{ Icon = "🔗"; Tech = "Workspace"; Agent = "workspace-hub" }
    "cpanel4agents" = @{ Icon = "🖥️"; Tech = "Node.js/MCP"; Agent = "protocol-claude" }
    "MCP" = @{ Icon = "🧠"; Tech = "Python/Docker"; Agent = "protocol-grok" }
    "cerebro-flutter" = @{ Icon = "📱"; Tech = "Flutter/Dart"; Agent = "protocol-claude" }
    "jamstack-admin" = @{ Icon = "📊"; Tech = "Next.js"; Agent = "protocol-claude" }
    "cgpsanpatricio.cl" = @{ Icon = "🌐"; Tech = "Next.js"; Agent = "protocol-claude" }
    "tiktboost" = @{ Icon = "📱"; Tech = "Next.js"; Agent = "protocol-claude" }
    "cooktie" = @{ Icon = "🍳"; Tech = "Flutter"; Agent = "protocol-claude" }
    "vita" = @{ Icon = "💚"; Tech = "Flutter"; Agent = "protocol-claude" }
    "shelf" = @{ Icon = "📚"; Tech = "React"; Agent = "protocol-claude" }
    "NVC" = @{ Icon = "🔧"; Tech = "Rust/Flutter"; Agent = "protocol-claude" }
    "CurseQRCrtify" = @{ Icon = "📝"; Tech = "Next.js"; Agent = "protocol-claude" }
    "hosteler-ia" = @{ Icon = "🏨"; Tech = "Next.js"; Agent = "protocol-claude" }
    "gara-g" = @{ Icon = "🚗"; Tech = "Various"; Agent = "protocol-claude" }
    "video-ai-manager-advanced" = @{ Icon = "🎬"; Tech = "Python/FastAPI"; Agent = "protocol-claude" }
    "orion" = @{ Icon = "⭐"; Tech = "Flutter"; Agent = "protocol-claude" }
    "software-factory-site" = @{ Icon = "🌍"; Tech = "Astro"; Agent = "protocol-claude" }
}

Write-Host "🔍 Scanning workspace: $WorkspacePath" -ForegroundColor Cyan

# Find all git repositories
$projects = Get-ChildItem -Path $WorkspacePath -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName ".git")
} | ForEach-Object {
    $name = $_.Name
    $meta = $projectMeta[$name]
    
    if (-not $meta) {
        $meta = @{ Icon = "📁"; Tech = "Unknown"; Agent = "protocol-claude" }
    }
    
    # Check git status
    $changes = (git -C $_.FullName status --porcelain 2>$null | Measure-Object).Count
    $status = if ($changes -eq 0) { "✅" } else { "⚠️ $changes" }
    
    @{
        Name = $name
        Path = $_.FullName
        Icon = $meta.Icon
        Tech = $meta.Tech
        Agent = $meta.Agent
        Changes = $changes
        Status = $status
    }
} | Sort-Object { $_.Changes } -Descending

Write-Host "📊 Found $($projects.Count) projects" -ForegroundColor Green

# Generate handoffs section
$handoffs = @"
  # ═══════════════════════════════════════════════════════════════
  # 🏠 WORKSPACE ACTIONS
  # ═══════════════════════════════════════════════════════════════
  - label: 📊 Workspace Status
    agent: workspace-hub
    prompt: Show me the status of all projects in this workspace.
    send: false
  - label: 🔄 Sync All Projects
    agent: workspace-hub
    prompt: Check which projects have uncommitted changes or need sync.
    send: false
  - label: 🔍 Find Project
    agent: workspace-hub
    prompt: Help me find a project by technology, name, or purpose.
    send: false
  
  # ═══════════════════════════════════════════════════════════════
  # 📁 PROJECTS (Auto-generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm'))
  # ═══════════════════════════════════════════════════════════════
"@

foreach ($project in $projects) {
    $handoffs += @"

  - label: $($project.Icon) $($project.Name)
    agent: $($project.Agent)
    prompt: |
      CONTEXT SWITCH: $($project.Name) ($($project.Tech))
      Path: $($project.Path)
      Load: cat ".✨/ARCHITECTURE.md" 2>`$null || cat "AGENTS.md" 2>`$null
      Then: gh issue list --assignee "@me"
    send: false
"@
}

$handoffs += @"

  # ═══════════════════════════════════════════════════════════════
  # 🔀 WORKFLOW HANDOFFS
  # ═══════════════════════════════════════════════════════════════
  - label: 🔄 Workflow Manager
    agent: workflow-manager
    prompt: Help me choose a workflow for my current task.
    send: false
  - label: 🎭 Load Specialized Role
    agent: recipe-loader
    prompt: I need to load a specialized agent role.
    send: false
  - label: ⚡ Quick Action
    agent: quick
    prompt: I need a quick answer.
    send: false
"@

# Generate project table
$projectTable = "| Project | Tech | Status |`n|---------|------|--------|`n"
foreach ($project in $projects) {
    $projectTable += "| $($project.Icon) $($project.Name) | $($project.Tech) | $($project.Status) |`n"
}

# Full agent file content
$agentContent = @"
```chatagent
---
name: Workspace Hub
description: Multi-project workspace orchestrator with dynamic project navigation
model: Claude Sonnet 4
tools:
  - search
  - problems
  - runCommand
  - terminalLastCommand
  - fetch
handoffs:
$handoffs
---
# 🏠 Workspace Hub Agent

> **Auto-generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm')
> **Projects:** $($projects.Count)
> **Workspace:** $WorkspacePath

You are the **Workspace Hub** - the central orchestrator for a multi-project development environment.

## 🎯 Your Mission

1. **Project Navigation**: Help users switch between projects efficiently
2. **Context Isolation**: Load ONLY the context for the active project
3. **Status Overview**: Provide workspace-wide health checks
4. **Smart Routing**: Send users to the right agent for each project

## 📊 Current Workspace Status

$projectTable

## 🧠 Context Isolation Protocol

**CRITICAL**: When switching projects, ONLY load:

1. Target project's ARCHITECTURE.md or AGENTS.md
2. Target project's issue list (gh issue list)
3. Target project's git status

**NEVER** load multiple projects' context simultaneously.

### Context Switch Command
``powershell
# When user clicks a project button:
cd "{PROJECT_PATH}"
cat ".✨/ARCHITECTURE.md" 2>`$null || cat "AGENTS.md" 2>`$null
git status --short
gh issue list --assignee "@me" --limit 5
``

## 📐 Response Format

When starting a conversation:

``markdown
## 🏠 Workspace Hub

### Current Focus
**Project**: [None selected / Project Name]
**Workspace**: $($projects.Count) projects

### Quick Actions
[Show top 3 projects with uncommitted changes first]

---
💡 Click a project button to switch context, or describe what you want to work on.
``

## ⚠️ Rules

1. **One Project at a Time**: Never load multiple project contexts
2. **Lazy Loading**: Don't pre-load anything until user selects
3. **Clear Handoffs**: When switching, explicitly state the context change
4. **Preserve State**: Remember which project was active in conversation

```
"@

if ($DryRun) {
    Write-Host "`n📄 Would generate:" -ForegroundColor Yellow
    Write-Host $agentContent
} else {
    $agentContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "✅ Generated: $OutputPath" -ForegroundColor Green
    Write-Host "   Projects: $($projects.Count)" -ForegroundColor Gray
}

# Summary
Write-Host "`n📊 Workspace Summary:" -ForegroundColor Cyan
$withChanges = $projects | Where-Object { $_.Changes -gt 0 }
if ($withChanges) {
    Write-Host "⚠️  Projects with uncommitted changes:" -ForegroundColor Yellow
    foreach ($p in $withChanges) {
        Write-Host "   - $($p.Name): $($p.Changes) files" -ForegroundColor Yellow
    }
}
