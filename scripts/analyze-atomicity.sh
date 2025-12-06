#!/bin/bash
# scripts/analyze-atomicity.sh
# 🔍 Analyze commit atomicity for the Git-Core Protocol
#
# This script analyzes commits in a PR to detect if they mix multiple concerns.
# It helps ensure commits follow the atomic commit principle.
#
# Usage:
#   ./scripts/analyze-atomicity.sh                    # Analyze all commits in PR
#   ./scripts/analyze-atomicity.sh --commit <sha>     # Analyze single commit
#   ./scripts/analyze-atomicity.sh --json             # Output JSON format
#
# Exit codes:
#   0 - All commits are atomic, or warning mode with issues (doesn't fail CI)
#   1 - Error mode with atomicity issues (fails CI)
#       For single commit mode (--commit): 1 = commit is not atomic

set -e

# Default values
OUTPUT_JSON=false
SINGLE_COMMIT=""
CONFIG_FILE=".github/atomicity-config.yml"
MAX_CONCERNS=1
MODE="warning"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            OUTPUT_JSON=true
            shift
            ;;
        --commit)
            SINGLE_COMMIT="$2"
            shift 2
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --mode)
            MODE="$2"
            shift 2
            ;;
        --max-concerns)
            MAX_CONCERNS="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Load configuration if available
if [ -f "$CONFIG_FILE" ]; then
    # Try to read values from YAML (basic parsing)
    if command -v yq &> /dev/null; then
        MAX_CONCERNS=$(yq -r '.max_concerns // 1' "$CONFIG_FILE" 2>/dev/null || echo "$MAX_CONCERNS")
        MODE=$(yq -r '.mode // "warning"' "$CONFIG_FILE" 2>/dev/null || echo "$MODE")
    fi
fi

# Function to categorize a file by concern type
categorize_file() {
    local file="$1"
    
    # Test files
    if [[ "$file" =~ ^tests?/ ]] || \
       [[ "$file" =~ \.test\. ]] || \
       [[ "$file" =~ \.spec\. ]] || \
       [[ "$file" =~ _test\. ]] || \
       [[ "$file" =~ ^test_ ]]; then
        echo "tests"
        return
    fi
    
    # Documentation
    if [[ "$file" =~ ^docs/ ]] || \
       [[ "$file" =~ \.md$ ]] || \
       [[ "$file" =~ ^README ]]; then
        echo "docs"
        return
    fi
    
    # CI/Infrastructure
    if [[ "$file" =~ ^\.github/workflows/ ]] || \
       [[ "$file" =~ ^scripts/ ]] || \
       [[ "$file" =~ ^Dockerfile ]] || \
       [[ "$file" =~ ^docker-compose ]]; then
        echo "infra"
        return
    fi
    
    # Configuration files
    if [[ "$file" =~ \.(yml|yaml|json|toml)$ ]] || \
       [[ "$file" =~ ^\. ]] || \
       [[ "$file" =~ ^\.github/ ]]; then
        echo "config"
        return
    fi
    
    # Source code (default)
    if [[ "$file" =~ ^src/ ]] || \
       [[ "$file" =~ ^lib/ ]] || \
       [[ "$file" =~ \.(py|js|ts|rs|go|java|rb|php|c|cpp|h|hpp)$ ]]; then
        echo "source"
        return
    fi
    
    # Unknown/other
    echo "other"
}

# Function to check if file should be excluded
is_excluded() {
    local file="$1"
    
    # Common exclusions
    if [[ "$file" =~ \.lock$ ]] || \
       [[ "$file" == "package-lock.json" ]] || \
       [[ "$file" == "yarn.lock" ]] || \
       [[ "$file" == "Cargo.lock" ]] || \
       [[ "$file" == ".gitignore" ]]; then
        return 0
    fi
    
    return 1
}

# Function to analyze a single commit
analyze_commit() {
    local commit="$1"
    local files
    local concerns=()
    local concern_files=()
    
    # Get list of files changed in commit
    files=$(git show --name-only --format="" "$commit" 2>/dev/null || echo "")
    
    if [ -z "$files" ]; then
        echo "{\"commit\": \"$commit\", \"error\": \"Could not get commit files\"}"
        return
    fi
    
    # Categorize each file
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        
        # Skip excluded files
        if is_excluded "$file"; then
            continue
        fi
        
        concern=$(categorize_file "$file")
        
        # Track unique concerns
        if [[ ! " ${concerns[*]} " =~ " ${concern} " ]]; then
            concerns+=("$concern")
        fi
        
        concern_files+=("{\"file\": \"$file\", \"concern\": \"$concern\"}")
    done <<< "$files"
    
    local concern_count=${#concerns[@]}
    local is_atomic=true
    
    if [ "$concern_count" -gt "$MAX_CONCERNS" ]; then
        is_atomic=false
    fi
    
    # Get commit info
    local commit_msg
    local commit_author
    commit_msg=$(git log -1 --format="%s" "$commit" 2>/dev/null || echo "")
    commit_author=$(git log -1 --format="%an" "$commit" 2>/dev/null || echo "")
    
    # Output
    if [ "$OUTPUT_JSON" = true ]; then
        local files_json
        files_json=$(printf '%s\n' "${concern_files[@]}" | paste -sd, -)
        echo "{\"commit\": \"${commit:0:8}\", \"message\": \"$commit_msg\", \"author\": \"$commit_author\", \"concerns\": [\"$(IFS='","'; echo "${concerns[*]}")\"], \"count\": $concern_count, \"is_atomic\": $is_atomic, \"files\": [$files_json]}"
    else
        if [ "$is_atomic" = true ]; then
            echo -e "${GREEN}✓${NC} ${commit:0:8}: $commit_msg (${concern_count} concern)"
        else
            echo -e "${YELLOW}⚠${NC} ${commit:0:8}: $commit_msg (${concern_count} concerns: ${concerns[*]})"
        fi
    fi
    
    # Return status
    [ "$is_atomic" = true ]
}

# Function to check if author is a bot
is_bot_author() {
    local author="$1"
    
    case "$author" in
        *"[bot]"*|*"github-actions"*|*"dependabot"*|*"copilot"*|*"jules"*|*"renovate"*)
            return 0
            ;;
    esac
    
    return 1
}

# Main execution
main() {
    local has_issues=false
    local total_commits=0
    local atomic_commits=0
    local non_atomic_commits=0
    local skipped_bots=0
    local results=()
    
    if [ -n "$SINGLE_COMMIT" ]; then
        # Analyze single commit
        analyze_commit "$SINGLE_COMMIT"
        exit $?
    fi
    
    # Get list of commits in PR (from origin/main to HEAD)
    local commits
    commits=$(git log --format="%H %an" origin/main..HEAD 2>/dev/null || echo "")
    
    if [ -z "$commits" ]; then
        if [ "$OUTPUT_JSON" = true ]; then
            echo '{"status": "ok", "message": "No commits to analyze", "commits": []}'
        else
            echo -e "${GREEN}✓${NC} No commits to analyze"
        fi
        exit 0
    fi
    
    if [ "$OUTPUT_JSON" != true ]; then
        echo -e "\n${CYAN}🔍 Analyzing commit atomicity...${NC}\n"
    fi
    
    while IFS=' ' read -r commit author; do
        [ -z "$commit" ] && continue
        ((total_commits++))
        
        # Check if bot author
        if is_bot_author "$author"; then
            ((skipped_bots++))
            if [ "$OUTPUT_JSON" != true ]; then
                echo -e "${CYAN}○${NC} ${commit:0:8}: Skipped (bot author)"
            fi
            continue
        fi
        
        # Analyze commit
        result=$(analyze_commit "$commit")
        results+=("$result")
        
        if [ "$OUTPUT_JSON" != true ]; then
            echo "$result"
        fi
        
        # Check if atomic
        if [[ "$result" =~ "⚠" ]] || [[ "$result" =~ '"is_atomic": false' ]]; then
            has_issues=true
            ((non_atomic_commits++))
        else
            ((atomic_commits++))
        fi
    done <<< "$commits"
    
    # Summary
    if [ "$OUTPUT_JSON" = true ]; then
        local commits_json
        commits_json=$(printf '%s\n' "${results[@]}" | paste -sd, -)
        echo "{\"status\": \"$([ "$has_issues" = true ] && echo "warning" || echo "ok")\", \"total\": $total_commits, \"atomic\": $atomic_commits, \"non_atomic\": $non_atomic_commits, \"skipped_bots\": $skipped_bots, \"commits\": [$commits_json]}"
    else
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}📊 Summary${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "   Total commits: $total_commits"
        echo -e "   ${GREEN}Atomic:${NC} $atomic_commits"
        echo -e "   ${YELLOW}Non-atomic:${NC} $non_atomic_commits"
        echo -e "   ${CYAN}Skipped (bots):${NC} $skipped_bots"
        echo ""
        
        if [ "$has_issues" = true ]; then
            echo -e "${YELLOW}⚠️  Some commits mix multiple concerns.${NC}"
            echo -e "   Consider using atomic commits for better history."
            echo ""
        else
            echo -e "${GREEN}✅ All commits are atomic!${NC}"
        fi
    fi
    
    # Exit code based on mode
    if [ "$has_issues" = true ]; then
        if [ "$MODE" = "error" ]; then
            exit 1
        else
            exit 0  # Warning mode - don't fail
        fi
    fi
    
    exit 0
}

main "$@"
