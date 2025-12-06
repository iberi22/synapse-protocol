<#
.SYNOPSIS
    Collects evolution metrics for Git-Core Protocol weekly improvement cycle.

.DESCRIPTION
    This script gathers metrics from GitHub API, analyzes patterns,
    and outputs a structured report for the Evolution Protocol.

.PARAMETER WeekOffset
    How many weeks back to analyze (0 = current week, 1 = last week, etc.)

.PARAMETER OutputFormat
    Output format: 'json', 'markdown', or 'console'

.PARAMETER CreateIssue
    If set, creates a GitHub issue with the evolution report

.EXAMPLE
    ./evolution-metrics.ps1 -WeekOffset 1 -OutputFormat markdown -CreateIssue
#>

param(
    [int]$WeekOffset = 1,
    [ValidateSet("json", "markdown", "console")]
    [string]$OutputFormat = "console",
    [switch]$CreateIssue
)

$ErrorActionPreference = "Stop"

# Calculate date range
$endDate = (Get-Date).AddDays(-($WeekOffset * 7))
$startDate = $endDate.AddDays(-7)
$weekNumber = [System.Globalization.ISOWeek]::GetWeekOfYear($endDate)
$year = $endDate.Year

Write-Host "📊 Collecting metrics for Week $weekNumber ($year)" -ForegroundColor Cyan
Write-Host "   Date range: $($startDate.ToString('yyyy-MM-dd')) to $($endDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray

# Initialize metrics object
$metrics = @{
    week = $weekNumber
    year = $year
    dateRange = @{
        start = $startDate.ToString("yyyy-MM-dd")
        end = $endDate.ToString("yyyy-MM-dd")
    }
    order1 = @{} # Operational
    order2 = @{} # Quality
    order3 = @{} # Evolution
    patterns = @()
    proposals = @()
}

# ============================================
# ORDER 1: OPERATIONAL METRICS (from GitHub API)
# ============================================
Write-Host "`n🔢 Order 1: Operational Metrics" -ForegroundColor Yellow

try {
    # Issues opened in the period
    $issuesOpened = gh issue list --state all --json number,createdAt 2>$null | ConvertFrom-Json
    $issuesOpenedCount = ($issuesOpened | Where-Object {
        $created = [DateTime]::Parse($_.createdAt)
        $created -ge $startDate -and $created -le $endDate
    }).Count
    $metrics.order1.issues_opened = $issuesOpenedCount
    Write-Host "   Issues opened: $issuesOpenedCount"

    # Issues closed in the period
    $issuesClosed = gh issue list --state closed --json number,closedAt 2>$null | ConvertFrom-Json
    $issuesClosedCount = ($issuesClosed | Where-Object {
        $closed = [DateTime]::Parse($_.closedAt)
        $closed -ge $startDate -and $closed -le $endDate
    }).Count
    $metrics.order1.issues_closed = $issuesClosedCount
    Write-Host "   Issues closed: $issuesClosedCount"

    # PRs merged
    $prsMerged = gh pr list --state merged --json number,mergedAt 2>$null | ConvertFrom-Json
    $prsMergedCount = ($prsMerged | Where-Object {
        $merged = [DateTime]::Parse($_.mergedAt)
        $merged -ge $startDate -and $merged -le $endDate
    }).Count
    $metrics.order1.prs_merged = $prsMergedCount
    Write-Host "   PRs merged: $prsMergedCount"

    # Workflow runs (requires gh extension or direct API)
    # Simplified: count recent failures
    $metrics.order1.workflow_failures = 0 # Placeholder
    Write-Host "   Workflow failures: (requires API access)"

} catch {
    Write-Warning "Could not fetch GitHub data: $_"
}

# ============================================
# ORDER 2: QUALITY METRICS
# ============================================
Write-Host "`n📈 Order 2: Quality Metrics" -ForegroundColor Yellow

try {
    # Agent state usage (check for <agent-state> in comments)
    $allIssues = gh issue list --state all --limit 50 --json number,comments 2>$null | ConvertFrom-Json
    $issuesWithAgentState = 0
    $totalIssuesWithComments = 0

    foreach ($issue in $allIssues) {
        if ($issue.comments.Count -gt 0) {
            $totalIssuesWithComments++
            $hasAgentState = $false
            # Note: gh issue list doesn't include comment bodies
            # This would need gh issue view for each issue
            # Simplified for now
        }
    }

    $metrics.order2.agent_state_usage_pct = 0 # Needs deeper analysis
    Write-Host "   Agent-state usage: (requires comment analysis)"

    # Atomic commit ratio (check commit messages)
    $commits = git log --since="$($startDate.ToString('yyyy-MM-dd'))" --until="$($endDate.ToString('yyyy-MM-dd'))" --oneline 2>$null
    $totalCommits = ($commits | Measure-Object -Line).Lines
    $atomicCommits = ($commits | Where-Object { $_ -match "^[a-f0-9]+ (feat|fix|docs|style|refactor|test|chore)\(" }).Count

    if ($totalCommits -gt 0) {
        $metrics.order2.atomic_commit_ratio = [math]::Round(($atomicCommits / $totalCommits) * 100, 1)
    } else {
        $metrics.order2.atomic_commit_ratio = 0
    }
    Write-Host "   Atomic commit ratio: $($metrics.order2.atomic_commit_ratio)%"

} catch {
    Write-Warning "Could not calculate quality metrics: $_"
}

# ============================================
# ORDER 3: EVOLUTION METRICS
# ============================================
Write-Host "`n🧬 Order 3: Evolution Metrics" -ForegroundColor Yellow

try {
    # Issues with evolution labels
    $frictionIssues = (gh issue list --label "friction" --state all --json number 2>$null | ConvertFrom-Json).Count
    $evolutionIssues = (gh issue list --label "evolution" --state all --json number 2>$null | ConvertFrom-Json).Count

    $metrics.order3.friction_reports = $frictionIssues
    $metrics.order3.improvement_proposals = $evolutionIssues
    Write-Host "   Friction reports: $frictionIssues"
    Write-Host "   Improvement proposals: $evolutionIssues"

} catch {
    Write-Warning "Could not calculate evolution metrics: $_"
}

# ============================================
# PATTERN DETECTION
# ============================================
Write-Host "`n🔍 Analyzing Patterns..." -ForegroundColor Yellow

# Throughput trend
if ($metrics.order1.issues_closed -gt $metrics.order1.issues_opened) {
    $metrics.patterns += @{
        type = "positive"
        description = "Throughput healthy: closing more issues than opening"
    }
} elseif ($metrics.order1.issues_opened -gt ($metrics.order1.issues_closed * 1.5)) {
    $metrics.patterns += @{
        type = "warning"
        description = "Backlog growing: opening significantly more than closing"
    }
}

# Atomic commits
if ($metrics.order2.atomic_commit_ratio -lt 70) {
    $metrics.patterns += @{
        type = "attention"
        description = "Low atomic commit ratio ($($metrics.order2.atomic_commit_ratio)%). Consider stricter validation."
    }
}

foreach ($pattern in $metrics.patterns) {
    $icon = switch ($pattern.type) {
        "positive" { "✅" }
        "warning" { "⚠️" }
        "attention" { "🔶" }
        default { "➡️" }
    }
    Write-Host "   $icon $($pattern.description)"
}

# ============================================
# OUTPUT
# ============================================
Write-Host "`n📤 Generating Output..." -ForegroundColor Yellow

switch ($OutputFormat) {
    "json" {
        $metrics | ConvertTo-Json -Depth 10
    }
    "markdown" {
        $md = @"
## 📊 Evolution Report - Week $weekNumber ($year)

**Period:** $($metrics.dateRange.start) to $($metrics.dateRange.end)

### Order 1: Operational Metrics

| Metric | Value |
|--------|-------|
| Issues Opened | $($metrics.order1.issues_opened) |
| Issues Closed | $($metrics.order1.issues_closed) |
| PRs Merged | $($metrics.order1.prs_merged) |

### Order 2: Quality Metrics

| Metric | Value |
|--------|-------|
| Atomic Commit Ratio | $($metrics.order2.atomic_commit_ratio)% |

### Order 3: Evolution Metrics

| Metric | Value |
|--------|-------|
| Friction Reports | $($metrics.order3.friction_reports) |
| Improvement Proposals | $($metrics.order3.improvement_proposals) |

### Patterns Detected

$(if ($metrics.patterns.Count -eq 0) { "No significant patterns detected." } else {
    ($metrics.patterns | ForEach-Object { "- **$($_.type):** $($_.description)" }) -join "`n"
})
"@
        $md
    }
    "console" {
        Write-Host "`n✅ Metrics collection complete." -ForegroundColor Green
        Write-Host "   Use -OutputFormat json or markdown for structured output."
    }
}

# Create issue if requested
if ($CreateIssue) {
    Write-Host "`n📝 Creating Evolution Report Issue..." -ForegroundColor Cyan
    $issueBody = $md
    gh issue create --title "[Evolution] Weekly Report - Week $weekNumber ($year)" --body $issueBody --label "evolution,weekly-report"
}
