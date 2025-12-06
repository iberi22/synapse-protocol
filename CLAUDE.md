# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository follows the **Git-Core Protocol** for AI-assisted development.
It contains the protocol definition, documentation, helper scripts, and the official CLI tool.

### Components

- `scripts/` - PowerShell and Shell scripts for protocol management (sync-issues, ai-report, etc.)
- `docs/` - Documentation and specifications (agent-docs, prompts, etc.)
- `tools/deprecated/git-core-cli/` - Deprecated Rust CLI
- `.github/` - GitHub configuration, workflows, and issue templates
- `.✨/` - AI Context folder (ARCHITECTURE.md, AGENT_INDEX.md)

## Development Commands

### Quick Actions

- `./scripts/sync-issues.ps1` - Sync local .md issues with GitHub
- `./scripts/ai-report.ps1` - Generate AI report for current PR

### GitHub Workflows

- Workflows are located in `.github/workflows/`
- `sync-issues.yml` - Automatically syncs issues on push

## Technical Guidelines

### Scripts (PowerShell/Bash)

- Maintain cross-platform compatibility (always provide .ps1 and .sh)
- Use `run_in_terminal` tool to execute them
- Follow the "Proactive Execution" protocol

### Rust CLI (Deprecated)

- Located in `tools/deprecated/git-core-cli/`
- No longer maintained

## Development Conventions

### TODO Annotations

- `TODO(0)`: Critical - never merge
- `TODO(1)`: High - architectural flaws, major bugs
- `TODO(2)`: Medium - minor bugs, missing features
- `TODO(3)`: Low - polish, tests, documentation

### Agent Behavior

- **State**: Always use GitHub Issues for state (Stateless Reducer)
- **Context**: Read `.✨/ARCHITECTURE.md` before starting
- **Commits**: Use Conventional Commits with `#issue` reference
