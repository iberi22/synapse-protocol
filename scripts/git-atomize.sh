#!/bin/bash
# git-atomize.sh - Split staged changes into atomic commits
# Part of Git-Core Protocol
#
# Usage:
#   git-atomize              # Interactive mode, suggests and waits for confirmation
#   git-atomize --analyze    # Analyze and show grouping plan
#   git-atomize --auto       # Auto-commit following suggestions
#   git-atomize --dry-run    # Show plan without executing
#   git-atomize --strict     # Fail if mixed concerns detected (for CI/teams)
#   git-atomize --ci         # CI mode, output JSON

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Mode flags
ANALYZE_MODE=false
AUTO_MODE=false
DRY_RUN=false
STRICT_MODE=false
CI_MODE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --analyze|-a)
            ANALYZE_MODE=true
            ;;
        --auto)
            AUTO_MODE=true
            ;;
        --dry-run|-n)
            DRY_RUN=true
            ;;
        --strict|-s)
            STRICT_MODE=true
            ;;
        --ci)
            CI_MODE=true
            ;;
        --help|-h)
            echo "git-atomize - Split staged changes into atomic commits"
            echo ""
            echo "Usage:"
            echo "  git-atomize              Interactive mode (default)"
            echo "  git-atomize --analyze    Analyze and show grouping plan"
            echo "  git-atomize --auto       Auto-commit following suggestions"
            echo "  git-atomize --dry-run    Show plan without executing"
            echo "  git-atomize --strict     Fail if mixed concerns detected"
            echo "  git-atomize --ci         CI mode, output JSON"
            echo ""
            echo "Options:"
            echo "  -a, --analyze    Same as --analyze"
            echo "  -n, --dry-run    Same as --dry-run"
            echo "  -s, --strict     Same as --strict"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# JSON string escape function
json_escape() {
    local str="$1"
    # Escape backslash first, then other special characters
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo -n "$str"
}

# Get staged files
get_staged_files() {
    git diff --cached --name-only 2>/dev/null
}

# Determine the concern/group for a file
get_file_group() {
    local file="$1"
    local dir
    local ext
    local basename_file
    
    dir=$(dirname "$file")
    ext="${file##*.}"
    basename_file=$(basename "$file")
    
    # By directory patterns
    case "$dir" in
        .github/workflows|.github/workflows/*)
            echo "ci:workflows"
            return
            ;;
        .github/actions|.github/actions/*)
            echo "ci:actions"
            return
            ;;
        .github/ISSUE_TEMPLATE|.github/ISSUE_TEMPLATE/*)
            echo "chore:issue-templates"
            return
            ;;
        .github|.github/*)
            echo "ci:github"
            return
            ;;
        docs|docs/*|doc|doc/*)
            echo "docs:documentation"
            return
            ;;
        supabase/migrations|supabase/migrations/*)
            echo "feat:db-migrations"
            return
            ;;
        supabase|supabase/*)
            echo "feat:db"
            return
            ;;
        migrations|migrations/*)
            echo "feat:db-migrations"
            return
            ;;
        tests|tests/*|test|test/*|__tests__|__tests__/*)
            echo "test:tests"
            return
            ;;
        scripts|scripts/*)
            echo "chore:scripts"
            return
            ;;
        src/components|src/components/*)
            echo "feat:ui"
            return
            ;;
        src/api|src/api/*|api|api/*)
            echo "feat:api"
            return
            ;;
        src/utils|src/utils/*|utils|utils/*|lib|lib/*)
            echo "refactor:utils"
            return
            ;;
        src/hooks|src/hooks/*)
            echo "feat:hooks"
            return
            ;;
        src/styles|src/styles/*|styles|styles/*)
            echo "style:styles"
            return
            ;;
        src/config|src/config/*|config|config/*)
            echo "chore:config"
            return
            ;;
        .ai|.ai/*)
            echo "docs:architecture"
            return
            ;;
    esac
    
    # By file extension
    case "$ext" in
        sql)
            echo "feat:db"
            return
            ;;
        md)
            echo "docs:markdown"
            return
            ;;
        yml|yaml)
            if [[ "$dir" == ".github"* ]]; then
                echo "ci:github"
            else
                echo "chore:config"
            fi
            return
            ;;
        json)
            case "$basename_file" in
                package.json|package-lock.json)
                    echo "chore:deps"
                    return
                    ;;
                tsconfig*.json|jsconfig*.json)
                    echo "chore:config"
                    return
                    ;;
                *)
                    echo "chore:data"
                    return
                    ;;
            esac
            ;;
        css|scss|sass|less)
            echo "style:styles"
            return
            ;;
    esac
    
    # By file name patterns
    case "$basename_file" in
        *.test.*|*.spec.*|test_*|*_test.*)
            echo "test:tests"
            return
            ;;
        *-listener*|*-manager*|*-handler*|*-service*)
            echo "feat:services"
            return
            ;;
        *-hook*|use[A-Z]*)
            echo "feat:hooks"
            return
            ;;
        .gitignore|.gitattributes)
            echo "chore:git"
            return
            ;;
        .env*|*.env)
            echo "chore:env"
            return
            ;;
        Dockerfile*|docker-compose*|.dockerignore)
            echo "ci:docker"
            return
            ;;
        README*|CHANGELOG*|LICENSE*|CONTRIBUTING*)
            echo "docs:root"
            return
            ;;
        AGENTS.md|.cursorrules|.windsurfrules)
            echo "chore:ai-config"
            return
            ;;
    esac
    
    # Default based on extension for source files
    case "$ext" in
        js|ts|jsx|tsx|py|rb|go|rs|java|kt|swift|c|cpp|h|hpp)
            echo "feat:source"
            return
            ;;
    esac
    
    # Fallback
    echo "chore:misc"
}

# Generate commit message for a group
generate_commit_message() {
    local group_key="$1"
    local file_count="$2"
    shift 2
    local files=("$@")
    
    local type="${group_key%%:*}"
    local scope="${group_key#*:}"
    
    # Generate description based on group
    local description=""
    case "$scope" in
        workflows)
            description="update CI/CD workflows"
            ;;
        actions)
            description="update GitHub actions"
            ;;
        github)
            description="update GitHub configuration"
            ;;
        issue-templates)
            description="update issue templates"
            ;;
        documentation)
            description="update documentation"
            ;;
        db-migrations)
            description="add database migrations"
            ;;
        db)
            description="update database configuration"
            ;;
        tests)
            description="update tests"
            ;;
        scripts)
            description="update scripts"
            ;;
        ui)
            description="update UI components"
            ;;
        api)
            description="update API endpoints"
            ;;
        utils)
            description="update utility functions"
            ;;
        hooks)
            description="update hooks"
            ;;
        styles)
            description="update styles"
            ;;
        config)
            description="update configuration"
            ;;
        architecture)
            description="update architecture documentation"
            ;;
        markdown)
            description="update markdown files"
            ;;
        deps)
            description="update dependencies"
            ;;
        data)
            description="update data files"
            ;;
        services)
            description="update services"
            ;;
        git)
            description="update git configuration"
            ;;
        env)
            description="update environment configuration"
            ;;
        docker)
            description="update Docker configuration"
            ;;
        root)
            description="update root documentation"
            ;;
        ai-config)
            description="update AI agent configuration"
            ;;
        source)
            description="update source files"
            ;;
        misc)
            description="update miscellaneous files"
            ;;
        *)
            description="update $scope"
            ;;
    esac
    
    # Format: type(scope): description
    if [[ "$scope" == "misc" || "$scope" == "source" ]]; then
        echo "${type}: ${description}"
    else
        echo "${type}(${scope}): ${description}"
    fi
}

# Main analysis function
analyze_staged_files() {
    local staged_files
    staged_files=$(get_staged_files)
    
    if [[ -z "$staged_files" ]]; then
        if [[ "$CI_MODE" == "true" ]]; then
            echo '{"error": "No staged files found", "groups": []}'
        else
            echo -e "${YELLOW}⚠️  No staged files found.${NC}"
            echo "Stage files first with: git add <files>"
        fi
        exit 0
    fi
    
    # Count total files
    local total_files
    total_files=$(echo "$staged_files" | wc -l | tr -d ' ')
    
    # Create associative array for groups
    declare -A groups
    declare -A group_files
    
    # Group files
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local group
        group=$(get_file_group "$file")
        
        if [[ -z "${groups[$group]}" ]]; then
            groups[$group]=0
            group_files[$group]=""
        fi
        
        groups[$group]=$((${groups[$group]} + 1))
        if [[ -n "${group_files[$group]}" ]]; then
            group_files[$group]="${group_files[$group]}"$'\n'"$file"
        else
            group_files[$group]="$file"
        fi
    done <<< "$staged_files"
    
    # Count groups
    local group_count=${#groups[@]}
    
    # Check for mixed concerns in strict mode
    if [[ "$STRICT_MODE" == "true" && "$group_count" -gt 1 ]]; then
        if [[ "$CI_MODE" == "true" ]]; then
            echo '{"error": "Mixed concerns detected", "group_count": '"$group_count"', "groups": []}'
        else
            echo -e "${RED}❌ STRICT MODE: Mixed concerns detected!${NC}"
            echo -e "${YELLOW}Found $group_count different concern groups in staged files.${NC}"
            echo "Please separate changes into atomic commits."
        fi
        exit 1
    fi
    
    # Output in CI/JSON mode
    if [[ "$CI_MODE" == "true" ]]; then
        echo '{"total_files": '"$total_files"', "group_count": '"$group_count"', "groups": ['
        local first=true
        for group in "${!groups[@]}"; do
            local count=${groups[$group]}
            local commit_msg
            local files_array
            
            IFS=$'\n' read -d '' -ra files_array <<< "${group_files[$group]}" || true
            commit_msg=$(generate_commit_message "$group" "$count" "${files_array[@]}")
            
            if [[ "$first" != "true" ]]; then
                echo ","
            fi
            first=false
            
            # Use json_escape for safe string output
            local escaped_group escaped_commit_msg
            escaped_group=$(json_escape "$group")
            escaped_commit_msg=$(json_escape "$commit_msg")
            
            echo -n '{"group": "'"$escaped_group"'", "file_count": '"$count"', "commit_message": "'"$escaped_commit_msg"'", "files": ['
            local first_file=true
            for f in "${files_array[@]}"; do
                [[ -z "$f" ]] && continue
                if [[ "$first_file" != "true" ]]; then
                    echo -n ","
                fi
                first_file=false
                local escaped_file
                escaped_file=$(json_escape "$f")
                echo -n '"'"$escaped_file"'"'
            done
            echo -n ']}'
        done
        echo ']}'
        return
    fi
    
    # Human-readable output
    echo -e "${CYAN}📊 Analysis of ${YELLOW}$total_files${CYAN} staged files:${NC}"
    echo ""
    
    local group_num=1
    for group in "${!groups[@]}"; do
        local count=${groups[$group]}
        local commit_msg
        local files_array
        
        IFS=$'\n' read -d '' -ra files_array <<< "${group_files[$group]}" || true
        commit_msg=$(generate_commit_message "$group" "$count" "${files_array[@]}")
        
        echo -e "${BLUE}📦 Group $group_num: ${MAGENTA}${group#*:}${NC} (${count} file$([ "$count" -ne 1 ] && echo "s"))"
        
        for f in "${files_array[@]}"; do
            [[ -z "$f" ]] && continue
            echo -e "   ${CYAN}- $f${NC}"
        done
        
        echo -e "   ${GREEN}Suggested commit: ${YELLOW}$commit_msg${NC}"
        echo ""
        
        group_num=$((group_num + 1))
    done
}

# Execute commits for each group
execute_commits() {
    local staged_files
    staged_files=$(get_staged_files)
    
    if [[ -z "$staged_files" ]]; then
        echo -e "${YELLOW}⚠️  No staged files found.${NC}"
        exit 0
    fi
    
    # Create associative array for groups
    declare -A groups
    declare -A group_files
    
    # Group files
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local group
        group=$(get_file_group "$file")
        
        if [[ -z "${groups[$group]}" ]]; then
            groups[$group]=0
            group_files[$group]=""
        fi
        
        groups[$group]=$((${groups[$group]} + 1))
        if [[ -n "${group_files[$group]}" ]]; then
            group_files[$group]="${group_files[$group]}"$'\n'"$file"
        else
            group_files[$group]="$file"
        fi
    done <<< "$staged_files"
    
    local total_groups=${#groups[@]}
    local current_group=1
    
    for group in "${!groups[@]}"; do
        local count=${groups[$group]}
        local commit_msg
        local files_array
        
        IFS=$'\n' read -d '' -ra files_array <<< "${group_files[$group]}" || true
        commit_msg=$(generate_commit_message "$group" "$count" "${files_array[@]}")
        
        echo -e "${BLUE}[$current_group/$total_groups] ${MAGENTA}${group#*:}${NC}"
        echo -e "   Files: ${count}"
        echo -e "   Commit: ${YELLOW}$commit_msg${NC}"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "   ${CYAN}(dry-run: would commit these files)${NC}"
        else
            # Unstage all files first
            git reset HEAD -- . >/dev/null 2>&1 || true
            
            # Stage only files in this group
            for f in "${files_array[@]}"; do
                [[ -z "$f" ]] && continue
                git add "$f" 2>/dev/null || true
            done
            
            # Commit
            if [[ "$AUTO_MODE" == "true" ]]; then
                git commit -m "$commit_msg" >/dev/null 2>&1
                echo -e "   ${GREEN}✓ Committed${NC}"
            else
                # Interactive mode - ask for confirmation
                echo -e "   ${YELLOW}Proceed with commit? [Y/n/e(dit message)]${NC} "
                read -r response
                case "$response" in
                    n|N)
                        echo -e "   ${CYAN}Skipped${NC}"
                        ;;
                    e|E)
                        echo -n "   Enter new message: "
                        read -r new_msg
                        if [[ -n "$new_msg" ]]; then
                            commit_msg="$new_msg"
                        fi
                        git commit -m "$commit_msg"
                        echo -e "   ${GREEN}✓ Committed${NC}"
                        ;;
                    *)
                        git commit -m "$commit_msg"
                        echo -e "   ${GREEN}✓ Committed${NC}"
                        ;;
                esac
            fi
        fi
        
        echo ""
        current_group=$((current_group + 1))
    done
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${CYAN}ℹ️  Dry run complete. No commits were made.${NC}"
        # Re-stage all original files
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            git add "$file" 2>/dev/null || true
        done <<< "$staged_files"
    else
        echo -e "${GREEN}✅ All groups committed successfully!${NC}"
    fi
}

# Main
if [[ "$ANALYZE_MODE" == "true" || "$CI_MODE" == "true" || "$STRICT_MODE" == "true" ]]; then
    analyze_staged_files
else
    # Show analysis first, then execute
    analyze_staged_files
    
    if [[ "$DRY_RUN" != "true" && "$AUTO_MODE" != "true" ]]; then
        echo -e "${YELLOW}═══════════════════════════════════════${NC}"
        echo -e "${YELLOW}Proceed with atomic commits? [Y/n]${NC} "
        read -r proceed
        if [[ "$proceed" =~ ^[Nn]$ ]]; then
            echo -e "${CYAN}Aborted.${NC}"
            exit 0
        fi
    fi
    
    execute_commits
fi
