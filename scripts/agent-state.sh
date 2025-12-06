#!/bin/bash

# Git-Core Protocol v1.4.0 - Agent State Tool (Bash)
# Usage:
#   ./agent-state.sh read --issue <number>
#   ./agent-state.sh write --intent "..." --step "..." --progress 50

COMMAND="$1"
shift

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --issue) ISSUE_NUMBER="$2"; shift 2 ;;
        --intent) INTENT="$2"; shift 2 ;;
        --step) STEP="$2"; shift 2 ;;
        --progress) PROGRESS="$2"; shift 2 ;;
        --memory) MEMORY="$2"; shift 2 ;;
        --plan) PLAN="$2"; shift 2 ;;
        --input-request) INPUT_REQUEST="$2"; shift 2 ;;
        --next-action) NEXT_ACTION="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Function to extract XML field value
extract_field() {
    local field="$1"
    local content="$2"
    echo "$content" | grep -oP "(?<=<$field>).*?(?=</$field>)" | head -1
}

# READ: Parse agent-state from issue comments
get_agent_state() {
    if [ -z "$ISSUE_NUMBER" ]; then
        echo "Error: Issue number is required for read command." >&2
        exit 1
    fi

    # Fetch comments using gh CLI
    COMMENTS_JSON=$(gh issue view "$ISSUE_NUMBER" --json comments 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch issue comments. Ensure gh CLI is authenticated." >&2
        exit 1
    fi

    # Find last comment with <agent-state>
    LAST_STATE=$(echo "$COMMENTS_JSON" | jq -r '.comments[].body' | grep -oP '(?s)<agent-state>.*?</agent-state>' | tail -1)

    if [ -z "$LAST_STATE" ]; then
        echo "Warning: No <agent-state> found in issue $ISSUE_NUMBER" >&2
        echo "{}"
        return
    fi

    # Parse XML fields (basic regex - for robust parsing, use a proper XML tool)
    INTENT_VAL=$(extract_field "intent" "$LAST_STATE")
    STEP_VAL=$(extract_field "step" "$LAST_STATE")
    PROGRESS_VAL=$(extract_field "progress" "$LAST_STATE")
    MEMORY_VAL=$(extract_field "memory" "$LAST_STATE")
    PLAN_VAL=$(extract_field "plan" "$LAST_STATE")
    INPUT_REQUEST_VAL=$(extract_field "input_request" "$LAST_STATE")
    METRICS_VAL=$(extract_field "metrics" "$LAST_STATE")
    NEXT_ACTION_VAL=$(extract_field "next_action" "$LAST_STATE")

    # Construct JSON output
    JSON="{"
    [ -n "$INTENT_VAL" ] && JSON="$JSON\"intent\":\"$INTENT_VAL\","
    [ -n "$STEP_VAL" ] && JSON="$JSON\"step\":\"$STEP_VAL\","
    [ -n "$PROGRESS_VAL" ] && JSON="$JSON\"progress\":$PROGRESS_VAL,"
    [ -n "$MEMORY_VAL" ] && JSON="$JSON\"memory\":\"$MEMORY_VAL\","
    [ -n "$PLAN_VAL" ] && JSON="$JSON\"plan\":\"$PLAN_VAL\","
    [ -n "$INPUT_REQUEST_VAL" ] && JSON="$JSON\"input_request\":\"$INPUT_REQUEST_VAL\","
    [ -n "$METRICS_VAL" ] && JSON="$JSON\"metrics\":\"$METRICS_VAL\","
    [ -n "$NEXT_ACTION_VAL" ] && JSON="$JSON\"next_action\":\"$NEXT_ACTION_VAL\","

    # Remove trailing comma and close JSON
    JSON="${JSON%,}}"
    echo "$JSON"
}

# WRITE: Generate agent-state XML block
new_agent_state() {
    echo "<agent-state>"
    [ -n "$INTENT" ] && echo "  <intent>$INTENT</intent>"
    [ -n "$STEP" ] && echo "  <step>$STEP</step>"
    [ -n "$PROGRESS" ] && echo "  <progress>$PROGRESS</progress>"

    if [ -n "$MEMORY" ]; then
        echo "  <memory>"
        echo "$MEMORY"
        echo "  </memory>"
    fi

    if [ -n "$PLAN" ]; then
        echo "  <plan>"
        echo "$PLAN"
        echo "  </plan>"
    fi

    if [ -n "$INPUT_REQUEST" ]; then
        echo "  <input_request>"
        echo "$INPUT_REQUEST"
        echo "  </input_request>"
    fi

    # Auto-generate metrics
    DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "  <metrics>"
    echo "    <generated_at>$DATE</generated_at>"
    echo "  </metrics>"

    [ -n "$NEXT_ACTION" ] && echo "  <next_action>$NEXT_ACTION</next_action>"
    echo "</agent-state>"
}

# Main dispatch
if [ "$COMMAND" == "read" ]; then
    get_agent_state
elif [ "$COMMAND" == "write" ]; then
    new_agent_state
else
    echo "Usage: $0 [read|write] ..."
    echo ""
    echo "Commands:"
    echo "  read --issue <number>        Read agent state from issue comments"
    echo "  write --intent <value> ...   Generate agent-state XML block"
    echo ""
    echo "Write options:"
    echo "  --intent <value>       Current intent"
    echo "  --step <value>         Current step (planning, coding, testing, etc.)"
    echo "  --progress <0-100>     Progress percentage"
    echo "  --memory <json>        Memory JSON string"
    echo "  --plan <text>          Plan items"
    echo "  --input-request <text> Input request details"
    echo "  --next-action <value>  Suggested next action"
    exit 1
fi
