param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("read", "write")]
    [string]$Command,

    [Parameter(ParameterSetName="read")]
    [string]$IssueNumber,

    [Parameter(ParameterSetName="write")]
    [string]$Intent,

    [Parameter(ParameterSetName="write")]
    [string]$Step,

    [Parameter(ParameterSetName="write")]
    [int]$Progress,

    [Parameter(ParameterSetName="write")]
    [string]$Memory = "{}",

    [Parameter(ParameterSetName="write")]
    [string]$Plan,

    [Parameter(ParameterSetName="write")]
    [string]$InputRequest,

    [Parameter(ParameterSetName="write")]
    [string]$NextAction
)

function Get-AgentState {
    param([string]$IssueId)

    if (-not $IssueId) {
        Write-Error "Issue Number is required for read command."
        return
    }

    # Fetch comments using gh cli
    try {
        $commentsJson = gh issue view $IssueId --json comments
        $comments = $commentsJson | ConvertFrom-Json
    } catch {
        Write-Error "Failed to fetch issue comments. Ensure gh cli is authenticated."
        return
    }

    # Find last comment with <agent-state>
    $lastState = $null
    foreach ($comment in $comments.comments) {
        if ($comment.body -match "(?s)<agent-state>(.*?)<\/agent-state>") {
            $lastState = $Matches[1]
        }
    }

    if (-not $lastState) {
        Write-Warning "No <agent-state> found in issue $IssueId"
        return
    }

    # Parse XML (Basic Regex parsing for robustness against malformed XML)
    $state = @{}

    $fields = @("intent", "step", "progress", "memory", "plan", "input_request", "next_action")
    foreach ($field in $fields) {
        if ($lastState -match "(?s)<$field>(.*?)<\/$field>") {
            $state[$field] = $Matches[1].Trim()
        }
    }

    # Handle Metrics specially if needed, or just generic parsing
    if ($lastState -match "(?s)<metrics>(.*?)<\/metrics>") {
        $state["metrics"] = $Matches[1].Trim()
    }

    return $state | ConvertTo-Json -Depth 5
}

function New-AgentState {
    $xml = "<agent-state>`n"

    if ($Intent) { $xml += "  <intent>$Intent</intent>`n" }
    if ($Step) { $xml += "  <step>$Step</step>`n" }
    if ($Progress) { $xml += "  <progress>$Progress</progress>`n" }

    if ($Memory) {
        $xml += "  <memory>`n$Memory`n  </memory>`n"
    }

    if ($Plan) {
        $xml += "  <plan>`n$Plan`n  </plan>`n"
    }

    if ($InputRequest) {
        $xml += "  <input_request>`n$InputRequest`n  </input_request>`n"
    }

    # Auto-generate metrics
    $date = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    $xml += "  <metrics>`n    <generated_at>$date</generated_at>`n  </metrics>`n"

    if ($NextAction) { $xml += "  <next_action>$NextAction</next_action>`n" }

    $xml += "</agent-state>"

    return $xml
}

if ($Command -eq "read") {
    Get-AgentState -IssueId $IssueNumber
} elseif ($Command -eq "write") {
    New-AgentState
}
