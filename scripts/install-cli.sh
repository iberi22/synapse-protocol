#!/bin/bash
# Quick installer for git-core CLI
# Usage: curl -fsSL https://raw.githubusercontent.com/iberi22/Git-Core-Protocol/main/scripts/install-cli.sh | bash

set -e

REPO="iberi22/Git-Core-Protocol"
BINARY_NAME="git-core"
INSTALL_DIR="${HOME}/.local/bin"
RAW_URL="https://raw.githubusercontent.com/$REPO/main/bin"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🧠 Git-Core CLI Installer${NC}"
echo "=========================="
echo ""

# Detect platform
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux*)
        case "$ARCH" in
            x86_64) TARGET="x86_64-unknown-linux-gnu" ;;
            aarch64) TARGET="aarch64-unknown-linux-gnu" ;;
            *) echo -e "${RED}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
        esac
        ;;
    Darwin*)
        case "$ARCH" in
            x86_64) TARGET="x86_64-apple-darwin" ;;
            arm64) TARGET="aarch64-apple-darwin" ;;
            *) echo -e "${RED}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
        esac
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS${NC}"
        echo "Please use Windows PowerShell installer or cargo install"
        exit 1
        ;;
esac

echo -e "Platform: ${CYAN}$OS $ARCH${NC}"
echo -e "Target: ${CYAN}$TARGET${NC}"
echo ""

# Create install directory
mkdir -p "$INSTALL_DIR"

# Try downloading from repo's bin/ folder first (fastest)
REPO_BIN_URL="${RAW_URL}/${BINARY_NAME}-${TARGET}"
echo "Checking for pre-built binary..."

if curl -fsSL --head "$REPO_BIN_URL" > /dev/null 2>&1; then
    echo -e "Found pre-built binary in repo"
    echo "Downloading from bin/..."
    curl -fsSL "$REPO_BIN_URL" -o "$INSTALL_DIR/$BINARY_NAME"
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
    echo -e "${GREEN}✅ Installed from repo bin/${NC}"
else
    # Try GitHub releases
    echo "Checking GitHub releases..."
    LATEST_RELEASE=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)

    if [ -n "$LATEST_RELEASE" ]; then
        echo -e "Latest release: ${GREEN}$LATEST_RELEASE${NC}"
        DOWNLOAD_URL="https://github.com/$REPO/releases/download/$LATEST_RELEASE/${BINARY_NAME}-${TARGET}"

        echo "Downloading from release..."
        curl -fsSL "$DOWNLOAD_URL" -o "$INSTALL_DIR/$BINARY_NAME"
        chmod +x "$INSTALL_DIR/$BINARY_NAME"
        echo -e "${GREEN}✅ Installed from release${NC}"
    else
        echo -e "${RED}❌ No pre-built binary found and source installation is deprecated.${NC}"
        echo "Please check the repository for manual installation instructions."
        exit 1
    fi
fi

# Check if in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  $INSTALL_DIR is not in your PATH${NC}"
    echo "Add this to your shell profile (.bashrc, .zshrc, etc.):"
    echo ""
    echo -e "  ${CYAN}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    echo ""
fi

# Verify installation
if command -v git-core &> /dev/null; then
    echo ""
    echo -e "${GREEN}✅ Installation complete!${NC}"
    echo ""
    git-core --version
    echo ""
    echo "Run 'git-core --help' to get started"
else
    echo ""
    echo -e "${YELLOW}Installation complete. Restart your terminal or run:${NC}"
    echo "  source ~/.bashrc  # or ~/.zshrc"
fi
