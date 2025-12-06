#!/bin/bash
# scripts/check-protocol-update.sh
# 🔍 Check if Git-Core Protocol needs updating
#
# Usage:
#   ./scripts/check-protocol-update.sh          # Check only
#   ./scripts/check-protocol-update.sh --update # Check and update
#   ./scripts/check-protocol-update.sh --force  # Force update

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
TEMPLATE_REPO="iberi22/Git-Core-Protocol"
BASE_URL="https://raw.githubusercontent.com/$TEMPLATE_REPO/main"
VERSION_FILE=".git-core-protocol-version"

# Parse args
UPDATE_MODE=false
FORCE_MODE=false

for arg in "$@"; do
    case $arg in
        --update|-u) UPDATE_MODE=true ;;
        --force|-f) FORCE_MODE=true; UPDATE_MODE=true ;;
    esac
done

echo -e "${CYAN}🔍 Checking Git-Core Protocol version...${NC}"

# Get current version
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
else
    CURRENT_VERSION="0.0.0"
fi
echo -e "   Current: ${YELLOW}$CURRENT_VERSION${NC}"

# Get latest version
LATEST_VERSION=$(curl -sL "$BASE_URL/$VERSION_FILE" 2>/dev/null | tr -d '[:space:]' || echo "error")

if [ "$LATEST_VERSION" = "error" ] || [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}❌ Could not fetch latest version${NC}"
    exit 1
fi
echo -e "   Latest:  ${GREEN}$LATEST_VERSION${NC}"

# Compare versions
if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ] && [ "$FORCE_MODE" = false ]; then
    echo -e "${GREEN}✅ Git-Core Protocol is up to date!${NC}"
    exit 0
fi

# Update needed
echo -e "${YELLOW}⚠️  Update available: $CURRENT_VERSION → $LATEST_VERSION${NC}"

if [ "$UPDATE_MODE" = false ]; then
    echo -e "\nRun with ${CYAN}--update${NC} to apply updates"
    echo -e "Run with ${CYAN}--force${NC} to force update"
    exit 0
fi

# Perform update
echo -e "\n${CYAN}📥 Downloading protocol files...${NC}"

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Download files
FILES=(
    "AGENTS.md"
    ".cursorrules"
    ".windsurfrules"
    ".github/copilot-instructions.md"
    ".git-core-protocol-version"
)

mkdir -p "$TEMP_DIR/.github"

for file in "${FILES[@]}"; do
    echo -e "   Downloading $file..."
    curl -sL "$BASE_URL/$file" -o "$TEMP_DIR/$file"
done

# Apply updates
echo -e "\n${CYAN}📦 Applying updates...${NC}"

mkdir -p .github

for file in "${FILES[@]}"; do
    if [ -f "$TEMP_DIR/$file" ]; then
        cp "$TEMP_DIR/$file" "$file"
        echo -e "   ${GREEN}✓${NC} $file"
    fi
done

echo -e "\n${GREEN}✅ Git-Core Protocol updated to $LATEST_VERSION${NC}"
echo -e "\n${YELLOW}📝 Don't forget to commit the changes:${NC}"
echo -e "   git add -A && git commit -m \"chore: 🔄 Update Git-Core Protocol to $LATEST_VERSION\""
