Which app would you like to open?---
title: "Git-Core CLI - Transparency & Trust"
type: DOCUMENTATION
id: "doc-cli-trust"
created: 2025-12-01
updated: 2025-12-01
agent: copilot
model: claude-opus-4
requested_by: user
summary: |
  Complete transparency documentation for the Git-Core CLI.
  Explains what the CLI does, how it was built, and where to find the source code.
keywords: [cli, trust, transparency, security, open-source]
tags: ["#security", "#trust", "#cli", "#documentation"]
project: Git-Core-Protocol
---

<!-- markdownlint-disable MD025 -->

# 🔐 Git-Core CLI - Transparency & Trust

> **⚠️ DEPRECATED: The Rust CLI is no longer the recommended way to use Git-Core Protocol. Please use the shell scripts instead.**

> **Before you install anything, you deserve to know exactly what it does.**

This document explains everything about the Git-Core CLI: what it does, how it was built, and where you can verify every line of code.

---

## 📖 Table of Contents

1. [What is Git-Core CLI?](#-what-is-git-core-cli)
2. [What Does It Do? (Plain English)](#-what-does-it-do-plain-english)
3. [What It Does NOT Do](#-what-it-does-not-do)
4. [Where Is The Source Code?](#-where-is-the-source-code)
5. [How Was It Built?](#-how-was-it-built)
6. [Installation Options (By Trust Level)](#️-installation-options-by-trust-level)
7. [How To Verify The Binary](#-how-to-verify-the-binary)
8. [Ask An AI To Explain The Code](#-ask-an-ai-to-explain-the-code)
9. [FAQ](#-faq)

---

## 🤔 What is Git-Core CLI?

Git-Core CLI (`git-core`) is a command-line tool that helps you install and manage the Git-Core Protocol in your projects.

**Think of it like:**

- `npm init` for Node.js projects
- `cargo init` for Rust projects
- `git init` for Git repositories

But instead of initializing a programming language project, it sets up a structure for AI-assisted development.

---

## 📝 What Does It Do? (Plain English)

When you run `git-core install`, the CLI does these things:

### 1. Downloads Template Files

```text
Downloads files from: github.com/iberi22/Git-Core-Protocol
These are configuration files, not executable code.
```

### 2. Creates Folders

```text
Creates these folders in YOUR project:
├── .✨/              (AI context folder)
├── .github/          (GitHub configuration)
├── scripts/          (Helper scripts)
└── docs/             (Documentation)
```

### 3. Copies Configuration Files

```text
Copies files like:
- AGENTS.md           (Rules for AI assistants)
- .cursorrules        (Rules for Cursor editor)
- .github/copilot-instructions.md (Rules for GitHub Copilot)
```

### 4. That's It

The CLI does NOT:

- Run any code on your machine
- Install any dependencies
- Modify your existing code
- Send data anywhere
- Require internet after installation

---

## 🚫 What It Does NOT Do

| ❌ Does NOT | Explanation |
|------------|-------------|
| Execute arbitrary code | Only copies files |
| Install dependencies | No npm, pip, or package managers |
| Require root/admin | Works in user space |
| Phone home | No telemetry, no analytics |
| Modify your code | Only adds new files |
| Run background processes | Exits immediately after use |
| Store credentials | No login, no tokens |

---

## 📂 Where Is The Source Code?

**Everything is open source. You can read every line.**

### Main Repository

```text
https://github.com/iberi22/Git-Core-Protocol
```

### CLI Source Code (Rust)

```text
https://github.com/iberi22/Git-Core-Protocol/tree/main/tools/git-core-cli
```

### File-by-File Breakdown

| File | Purpose | Lines | Link |
|------|---------|-------|------|
| `src/main.rs` | Entry point, CLI argument parsing | ~150 | [View](https://github.com/iberi22/Git-Core-Protocol/blob/main/tools/git-core-cli/src/main.rs) |
| `src/config.rs` | Configuration constants | ~120 | [View](https://github.com/iberi22/Git-Core-Protocol/blob/main/tools/git-core-cli/src/config.rs) |
| `src/utils.rs` | Helper functions (print, copy files) | ~100 | [View](https://github.com/iberi22/Git-Core-Protocol/blob/main/tools/git-core-cli/src/utils.rs) |
| `src/commands/install.rs` | Install command logic | ~80 | [View](https://github.com/iberi22/Git-Core-Protocol/blob/main/tools/git-core-cli/src/commands/install.rs) |
| `src/commands/upgrade.rs` | Upgrade command logic | ~80 | [View](https://github.com/iberi22/Git-Core-Protocol/blob/main/tools/git-core-cli/src/commands/upgrade.rs) |
| `src/commands/migrate.rs` | Migration from .ai/ to .✨/ | ~70 | [View](https://github.com/iberi22/Git-Core-Protocol/blob/main/tools/git-core-cli/src/commands/migrate.rs) |
| `src/commands/check.rs` | Integrity verification | ~150 | [View](https://github.com/iberi22/Git-Core-Protocol/blob/main/tools/git-core-cli/src/commands/check.rs) |
| `src/commands/status.rs` | Status display | ~80 | [View](https://github.com/iberi22/Git-Core-Protocol/blob/main/tools/git-core-cli/src/commands/status.rs) |
| `src/installer/download.rs` | Download from GitHub | ~100 | [View](https://github.com/iberi22/Git-Core-Protocol/blob/main/tools/git-core-cli/src/installer/download.rs) |
| `src/installer/backup.rs` | Backup user files | ~80 | [View](https://github.com/iberi22/Git-Core-Protocol/blob/main/tools/git-core-cli/src/installer/backup.rs) |
| `src/installer/install.rs` | File installation logic | ~120 | [View](https://github.com/iberi22/Git-Core-Protocol/blob/main/tools/git-core-cli/src/installer/install.rs) |

**Total: ~1,100 lines of Rust code** - Small enough to read in 30 minutes.

### Dependencies (Cargo.toml)

```text
https://github.com/iberi22/Git-Core-Protocol/blob/main/tools/git-core-cli/Cargo.toml
```

All dependencies are from crates.io (Rust's official package registry):

- `clap` - Command line argument parsing
- `tokio` - Async runtime
- `reqwest` - HTTP client (to download from GitHub)
- `serde` - Serialization
- `indicatif` - Progress bars
- `console` - Terminal colors
- `dialoguer` - Interactive prompts

---

## 🔨 How Was It Built?

### Technology

- **Language:** Rust (memory-safe, no runtime)
- **Build System:** Cargo (Rust's official build tool)
- **CI/CD:** GitHub Actions (builds are reproducible)

### Build Process

```yaml
# The CLI is built by GitHub Actions, not on someone's laptop
# See: .github/workflows/build-cli.yml

1. GitHub Actions runner starts (clean Ubuntu/Windows/macOS)
2. Rust toolchain installed (official rustup)
3. `cargo build --release` compiles the code
4. Binary is uploaded to GitHub Releases
5. SHA256 checksum is generated
```

### Reproducible Builds

You can build the exact same binary yourself:

```bash
git clone https://github.com/iberi22/Git-Core-Protocol
cd Git-Core-Protocol/tools/git-core-cli
cargo build --release
# Binary is at: target/release/git-core
```

---

## 🛡️ Installation Options (By Trust Level)

### Level 1: Maximum Trust (Build From Source)

**You compile it yourself. You see everything.**

```bash
# Clone the repository
git clone https://github.com/iberi22/Git-Core-Protocol
cd Git-Core-Protocol/tools/git-core-cli

# Read the code first if you want
cat src/main.rs

# Build it yourself
cargo build --release

# Use your own binary
./target/release/git-core install
```

### Level 2: High Trust (Cargo Install)

**Cargo downloads source from crates.io and compiles locally.**

```bash
# Cargo fetches source code and compiles on YOUR machine
cargo install git-core-cli

# The binary is compiled locally, not downloaded pre-built
```

### Level 3: Medium Trust (Shell Scripts)

**You can read the script before running it.**

```bash
# FIRST: Read what the script does
curl -fsSL https://raw.githubusercontent.com/iberi22/Git-Core-Protocol/main/install.sh

# THEN: If you trust it, run it
curl -fsSL https://raw.githubusercontent.com/iberi22/Git-Core-Protocol/main/install.sh | bash
```

### Level 4: Convenience (Pre-built Binary)

**For users who trust the project and want quick setup.**

```bash
# Downloads pre-built binary from GitHub Releases
curl -fsSL https://raw.githubusercontent.com/iberi22/Git-Core-Protocol/main/scripts/install-cli.sh | bash
```

---

## ✅ How To Verify The Binary

If you download a pre-built binary, verify it:

### 1. Check the SHA256 Checksum

```bash
# Download the checksum file
curl -fsSL https://github.com/iberi22/Git-Core-Protocol/releases/latest/download/git-core-x86_64-unknown-linux-gnu.sha256

# Compare with your download
sha256sum git-core-x86_64-unknown-linux-gnu
```

### 2. Verify GitHub Actions Built It

Every release shows which GitHub Actions workflow built it:

```text
https://github.com/iberi22/Git-Core-Protocol/actions
```

### 3. Compare With Your Own Build

```bash
# Build locally
cargo build --release

# Compare binaries (they should be very similar in size)
ls -la target/release/git-core
ls -la ~/downloaded-git-core
```

---

## 🤖 Ask An AI To Explain The Code

If you're not technical, you can ask an AI to explain the code:

### Option 1: GitHub Copilot

1. Open the repository in VS Code
2. Select any file
3. Ask Copilot: "Explain what this code does"

### Option 2: ChatGPT / Claude

Copy-paste the code and ask:

```text
Explain this Rust code in simple terms.
Is it safe? Does it do anything suspicious?

[paste code here]
```

### Option 3: Use Context7 or Similar

```text
Fetch the documentation for github.com/iberi22/Git-Core-Protocol
and explain what the CLI does
```

### Key Questions To Ask An AI

1. "Does this code access the network? When and why?"
2. "Does this code read or write files outside the current directory?"
3. "Does this code execute any shell commands?"
4. "Could this code be malicious in any way?"

---

## ❓ FAQ

### Q: Why should I trust this?

**A:** You don't have to trust it. You can:

1. Read the source code (it's ~1,100 lines)
2. Build it yourself from source
3. Use the shell scripts instead (visible code)
4. Not use it at all and manually copy files

### Q: Why a CLI instead of just scripts?

**A:** The CLI provides:

- Cross-platform support (one tool for all OS)
- Better error messages
- Interactive prompts
- Integrity checking
- Self-update capability

But the scripts still work if you prefer them.

### Q: Is this CLI required to use Git-Core Protocol?

**A:** No! You can:

- Use the shell scripts (`install.sh`, `install.ps1`)
- Use the GitHub template and clone manually
- Copy files manually from the repository

The CLI is just a convenience tool.

### Q: Who built this?

**A:** The Git-Core Protocol is maintained by [@iberi22](https://github.com/iberi22).
All contributions are visible in the repository's commit history.

### Q: Can I contribute or report issues?

**A:** Yes!

- Issues: <https://github.com/iberi22/Git-Core-Protocol/issues>
- Pull Requests welcome

---

## 📞 Contact & Support

- **Repository:** <https://github.com/iberi22/Git-Core-Protocol>
- **Issues:** <https://github.com/iberi22/Git-Core-Protocol/issues>
- **Discussions:** <https://github.com/iberi22/Git-Core-Protocol/discussions>

---

*Last updated: December 2025*
*Document version: 1.0.0*
