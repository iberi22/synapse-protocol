#!/bin/bash
#
# SYNOPSIS
#     Equips the AI agent with a specific Role (Recipe) by downloading it from GitHub.
#
# DESCRIPTION
#     This script acts as the "Context Injector" for the AI. It:
#     1. Looks up the requested Role in .✨/AGENT_INDEX.md.
#     2. Extracts the recipe path.
#     3. Downloads the recipe content from the remote repository.
#     4. Appends standard protocol skills (Atomic Commits, Architecture).
#     5. Generates a temporary context file for the agent to read.
#
# USAGE
#     ./scripts/equip-agent.sh "Backend Architect"

ROLE="$1"

if [ -z "$ROLE" ]; then
    echo "Usage: $0 <Role>"
    exit 1
fi

REPO_BASE_URL="https://raw.githubusercontent.com/iberi22/agents-flows-recipes/main"
CONFIG_DIR=".✨"
CONTEXT_FILE="$CONFIG_DIR/CURRENT_CONTEXT.md"
INDEX_FILE="$CONFIG_DIR/AGENT_INDEX.md"

# Ensure Config Directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo "❌ Configuration directory '$CONFIG_DIR' not found."
    exit 1
fi

echo -e "\033[0;36m🔍 Searching for role '$ROLE' in $INDEX_FILE...\033[0m"

# 1. Read Index and Find Role
if [ ! -f "$INDEX_FILE" ]; then
    echo "❌ Index file '$INDEX_FILE' not found."
    exit 1
fi

# Regex to find the table row. Matches: | **Role Name** | Description | Path |
# We use grep to find the line matching the role, then awk to extract the path (3rd column usually)
# The table format is: | **Role** | Desc | `path` | Skills |
MATCH=$(grep -i "$ROLE" "$INDEX_FILE" | head -n 1)

if [ -z "$MATCH" ]; then
    echo "❌ Role '$ROLE' not found in $INDEX_FILE."
    echo "Available roles can be found in $INDEX_FILE"
    exit 1
fi

# Extract path between backticks or just the text in the 3rd column
RECIPE_PATH=$(echo "$MATCH" | awk -F'|' '{print $4}' | tr -d '`' | xargs)

echo -e "\033[0;32m✅ Found Recipe Path: $RECIPE_PATH\033[0m"

# 2. Download Recipe
DOWNLOAD_URL="$REPO_BASE_URL/$RECIPE_PATH"
echo -e "\033[0;36m⬇️ Downloading from: $DOWNLOAD_URL\033[0m"

RECIPE_CONTENT=$(curl -sL "$DOWNLOAD_URL")

if [ -z "$RECIPE_CONTENT" ] || [[ "$RECIPE_CONTENT" == *"404: Not Found"* ]]; then
    echo "❌ Failed to download recipe from $DOWNLOAD_URL"
    exit 1
fi

# 3. Build the Context
CURRENT_DATE=$(date)
HEADER="# 🎭 ACTIVE AGENT PERSONA: $ROLE
> GENERATED CONTEXT - DO NOT EDIT MANUALLY
> Source: $DOWNLOAD_URL
> Loaded at: $CURRENT_DATE

---
"

PROTOCOL_SKILLS="

---
## 🛡️ MANDATORY PROTOCOL SKILLS
1. **Token Economy:** Use GitHub Issues for state. No TODO.md.
2. **Architecture First:** Verify against $CONFIG_DIR/ARCHITECTURE.md.
3. **Atomic Commits:** One logical change per commit.
"

# 4. Output to Context File
echo "$HEADER" > "$CONTEXT_FILE"
echo "$RECIPE_CONTENT" >> "$CONTEXT_FILE"
echo "$PROTOCOL_SKILLS" >> "$CONTEXT_FILE"

echo -e "\033[0;33m✨ Agent Equipped! Context written to $CONTEXT_FILE\033[0m"
echo -e "\033[0;35m🤖 INSTRUCTION: Read $CONTEXT_FILE to assume your new role.\033[0m"
