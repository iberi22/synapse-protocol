#!/bin/bash
# bump-version.sh - Increment Git-Core Protocol version
# Usage: ./scripts/bump-version.sh [major|minor|patch]

set -e

VERSION_FILE=".git-core-protocol-version"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get current version
if [ ! -f "$VERSION_FILE" ]; then
    echo "1.0.0" > "$VERSION_FILE"
fi

CURRENT=$(cat "$VERSION_FILE" | tr -d '[:space:]')
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

# Default to patch
BUMP_TYPE="${1:-patch}"

case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo -e "${RED}❌ Invalid bump type: $BUMP_TYPE${NC}"
        echo "Usage: $0 [major|minor|patch]"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Update version file
echo "$NEW_VERSION" > "$VERSION_FILE"

echo -e "${CYAN}🔄 Version Bumped${NC}"
echo -e "   ${YELLOW}$CURRENT${NC} → ${GREEN}$NEW_VERSION${NC}"
echo ""

# Update AGENTS.md version reference
if [ -f "AGENTS.md" ]; then
    sed -i "s/Protocol Version: .*/Protocol Version: $NEW_VERSION/" AGENTS.md 2>/dev/null || \
    sed -i '' "s/Protocol Version: .*/Protocol Version: $NEW_VERSION/" AGENTS.md
    echo -e "${GREEN}✓ Updated AGENTS.md${NC}"
fi

# Show git commands to commit
echo ""
echo -e "${YELLOW}📋 To commit this version bump:${NC}"
echo "   git add $VERSION_FILE AGENTS.md"
echo "   git commit -m \"chore: bump version to v$NEW_VERSION\""
echo "   git tag -a v$NEW_VERSION -m \"Release v$NEW_VERSION\""
echo "   git push origin main --tags"
