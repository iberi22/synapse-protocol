<#
.SYNOPSIS
    Sends anonymized protocol metrics to the official Git-Core Protocol repository via GitHub Discussions.

.DESCRIPTION
    This script collects evolution metrics from the current project and submits
    them as a GitHub Discussion (not PR) to the official Git-Core Protocol repository.
    This approach scales to thousands of users without flooding the PR feed.

.PARAMETER DryRun
    If set, shows what would be sent without actually creating the Discussion.

.PARAMETER Anonymous
    If set, removes project identifiers (default: true).

.PARAMETER IncludePatterns
    If set, includes detected patterns in the telemetry.

.EXAMPLE
    ./send-telemetry.ps1
    # Sends anonymized metrics to official repo via Discussion

.EXAMPLE
    ./send-telemetry.ps1 -DryRun
    # Preview what would be sent

.NOTES
    Scalability: This script creates Discussions, not PRs.
    10,000 users = 10,000 Discussions (not PRs), aggregated weekly.
#>

param(
    [switch]$DryRun,
    [bool]$Anonymous = $true,
    [switch]$IncludePatterns
)

$ErrorActionPreference = "Stop"

$OFFICIAL_REPO_OWNER = "iberi22"
$OFFICIAL_REPO_NAME = "Git-Core-Protocol"
$TELEMETRY_CATEGORY_NAME = "Telemetry Submissions"

Write-Host "📡 Git-Core Protocol - Federated Telemetry System v2" -ForegroundColor Cyan
Write-Host "   Method: GitHub Discussions (scalable)" -ForegroundColor Gray
Write-Host "   Destination: github.com/$OFFICIAL_REPO_OWNER/$OFFICIAL_REPO_NAME" -ForegroundColor Gray

# ============================================
# 1. COLLECT LOCAL METRICS
# ============================================
Write-Host "`n📊 Collecting local metrics..." -ForegroundColor Yellow

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$weekNumber = [System.Globalization.ISOWeek]::GetWeekOfYear((Get-Date))
$year = (Get-Date).Year

# Get current repo info
$repoUrl = git config --get remote.origin.url 2>$null
$repoName = if ($repoUrl) {
    $repoUrl -replace ".*[:/]([^/]+/[^/]+?)(.git)?$", '$1'
} else {
    "unknown"
}

# Anonymize if requested
$projectId = if ($Anonymous) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($repoName)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    "anon-" + [BitConverter]::ToString($hash[0..3]).Replace("-", "").ToLower()
} else {
    $repoName
}

Write-Host "   Project ID: $projectId" -ForegroundColor Gray

# Collect metrics
$metrics = @{
    schema_version = "2.0"
    submission_method = "discussion"
    project_id = $projectId
    anonymous = $Anonymous
    timestamp = $timestamp
    week = $weekNumber
    year = $year
    protocol_version = "2.1"
    order1 = @{}
    order2 = @{}
    order3 = @{}
}

# Order 1: Operational
try {
    $issuesOpen = (gh issue list --state open --json number 2>$null | ConvertFrom-Json).Count
    $issuesClosed = (gh issue list --state closed --limit 100 --json number 2>$null | ConvertFrom-Json).Count
    $prsOpen = (gh pr list --state open --json number 2>$null | ConvertFrom-Json).Count
    $prsMerged = (gh pr list --state merged --limit 100 --json number 2>$null | ConvertFrom-Json).Count

    $metrics.order1 = @{
        issues_open = $issuesOpen
        issues_closed_total = $issuesClosed
        prs_open = $prsOpen
        prs_merged_total = $prsMerged
    }
    Write-Host "   ✓ Order 1 metrics collected" -ForegroundColor Green
} catch {
    Write-Warning "   Could not collect Order 1 metrics: $_"
}

# Order 2: Quality
try {
    $recentIssues = gh issue list --limit 10 --json number 2>$null | ConvertFrom-Json
    $agentStateCount = 0

    foreach ($issue in $recentIssues) {
        $issueBody = gh issue view $issue.number --json body 2>$null | ConvertFrom-Json
        if ($issueBody.body -match "<agent-state>") {
            $agentStateCount++
        }
    }

    $usagePct = if ($recentIssues.Count -gt 0) {
        [math]::Round(($agentStateCount / $recentIssues.Count) * 100, 1)
    } else { 0 }

    $commits = git log --oneline -50 2>$null
    $totalCommits = ($commits | Measure-Object -Line).Lines
    $atomicCommits = ($commits | Where-Object { $_ -match "^[a-f0-9]+ (feat|fix|docs|style|refactor|test|chore)\(" }).Count
    $atomicRatio = if ($totalCommits -gt 0) {
        [math]::Round(($atomicCommits / $totalCommits) * 100, 1)
    } else { 0 }

    $metrics.order2 = @{
        agent_state_usage_pct = $usagePct
        atomic_commit_ratio = $atomicRatio
        sample_size = $recentIssues.Count
    }
    Write-Host "   ✓ Order 2 metrics collected" -ForegroundColor Green
} catch {
    Write-Warning "   Could not collect Order 2 metrics: $_"
}

# Order 3: Evolution
try {
    $frictionCount = (gh issue list --label "friction" --state all --json number 2>$null | ConvertFrom-Json).Count
    $evolutionCount = (gh issue list --label "evolution" --state all --json number 2>$null | ConvertFrom-Json).Count

    $metrics.order3 = @{
        friction_reports = $frictionCount
        evolution_proposals = $evolutionCount
    }
    Write-Host "   ✓ Order 3 metrics collected" -ForegroundColor Green
} catch {
    Write-Warning "   Could not collect Order 3 metrics: $_"
}

# Detect patterns (optional)
if ($IncludePatterns) {
    $patterns = @()

    if ($metrics.order2.agent_state_usage_pct -lt 50) {
        $patterns += "low_agent_state_adoption"
    }
    if ($metrics.order2.atomic_commit_ratio -lt 70) {
        $patterns += "low_atomic_commit_ratio"
    }
    if ($metrics.order3.friction_reports -gt 5) {
        $patterns += "high_friction"
    }

    $metrics.patterns = $patterns
}

# ============================================
# 2. GENERATE TELEMETRY PAYLOAD
# ============================================
$telemetryJson = $metrics | ConvertTo-Json -Depth 10 -Compress
$discussionTitle = "📊 $projectId - Week $weekNumber ($year)"

Write-Host "`n📄 Generated telemetry:" -ForegroundColor Yellow
Write-Host ($metrics | ConvertTo-Json -Depth 10)

if ($DryRun) {
    Write-Host "`n🔍 DRY RUN - No Discussion will be created" -ForegroundColor Magenta
    Write-Host "   Would create Discussion: '$discussionTitle'" -ForegroundColor Gray
    return
}

# ============================================
# 3. GET REPOSITORY AND CATEGORY IDs
# ============================================
Write-Host "`n🔍 Getting repository info..." -ForegroundColor Yellow

try {
    # Get repo ID
    $repoQuery = @"
query {
  repository(owner: "$OFFICIAL_REPO_OWNER", name: "$OFFICIAL_REPO_NAME") {
    id
    discussionCategories(first: 20) {
      nodes {
        id
        name
        slug
      }
    }
  }
}
"@

    $repoInfo = gh api graphql -f query="$repoQuery" 2>$null | ConvertFrom-Json
    $repoId = $repoInfo.data.repository.id

    # Find telemetry category
    $telemetryCategory = $repoInfo.data.repository.discussionCategories.nodes |
        Where-Object { $_.name -like "*Telemetry*" -or $_.slug -like "*telemetry*" } |
        Select-Object -First 1

    if (-not $telemetryCategory) {
        Write-Warning "Telemetry category not found. Creating in 'General' category..."
        $telemetryCategory = $repoInfo.data.repository.discussionCategories.nodes |
            Where-Object { $_.slug -eq "general" } |
            Select-Object -First 1
    }

    if (-not $telemetryCategory) {
        throw "No suitable Discussion category found. Please enable Discussions in the repository."
    }

    $categoryId = $telemetryCategory.id
    Write-Host "   Repository ID: $repoId" -ForegroundColor Gray
    Write-Host "   Category: $($telemetryCategory.name) ($categoryId)" -ForegroundColor Gray

} catch {
    Write-Error "Failed to get repository info: $_"
    Write-Host "`n⚠️ Discussions may not be enabled on the repository." -ForegroundColor Yellow
    Write-Host "   Please ensure Discussions are enabled at:" -ForegroundColor Yellow
    Write-Host "   https://github.com/$OFFICIAL_REPO_OWNER/$OFFICIAL_REPO_NAME/settings" -ForegroundColor Cyan
    return
}

# ============================================
# 4. CREATE DISCUSSION
# ============================================
Write-Host "`n🚀 Creating Discussion..." -ForegroundColor Yellow

$discussionBody = @"
## 📡 Telemetry Submission

**Project ID:** \`$projectId\`
**Week:** $weekNumber ($year)
**Protocol Version:** $($metrics.protocol_version)

### Metrics

\`\`\`json
$($metrics | ConvertTo-Json -Depth 10)
\`\`\`

---
*Auto-generated by Git-Core Protocol Telemetry System v2*
"@

# Escape for GraphQL
$escapedBody = $discussionBody.Replace('\', '\\').Replace('"', '\"').Replace("`n", '\n').Replace("`r", '')

$createMutation = @"
mutation {
  createDiscussion(input: {
    repositoryId: "$repoId"
    categoryId: "$categoryId"
    title: "$discussionTitle"
    body: "$escapedBody"
  }) {
    discussion {
      id
      url
    }
  }
}
"@

try {
    $result = gh api graphql -f query="$createMutation" 2>$null | ConvertFrom-Json

    if ($result.data.createDiscussion.discussion) {
        $discussionUrl = $result.data.createDiscussion.discussion.url
        Write-Host "`n✅ Telemetry submitted successfully!" -ForegroundColor Green
        Write-Host "   Discussion: $discussionUrl" -ForegroundColor Cyan
    } else {
        throw "Discussion creation returned empty result"
    }
} catch {
    Write-Error "Failed to create Discussion: $_"
    Write-Host "`n💡 Tip: Make sure you have permission to create Discussions." -ForegroundColor Yellow
}
