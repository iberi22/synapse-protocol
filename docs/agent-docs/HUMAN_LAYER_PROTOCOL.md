---
title: "HumanLayer Protocol - High Stakes Operations"
type: SPECIFICATION
id: "spec-human-layer"
created: 2025-12-03
updated: 2025-12-03
agent: copilot
model: gemini-3-pro
requested_by: user
summary: |
  Protocol for handling High Stakes operations with Human-in-the-Loop.
  Defines what constitutes a high stakes action and the required approval flow.
keywords: [human-layer, high-stakes, approval, security]
tags: ["#security", "#human-in-the-loop", "#protocol"]
project: Git-Core-Protocol
protocol_version: 1.5.0
---

# 🛡️ HumanLayer Protocol

> **"Even with state-of-the-art agentic reasoning, LLMs are not sufficiently reliable to be given access to high-stakes functions without human oversight."**

## Classification of Stakes

Agents must classify every tool call or action into one of these categories:

### 🟢 Low Stakes (Autonomous)

*Action can proceed without interruption.*

- **Read Access (Public)**: Searching docs, reading public repos.
- **Communication (Internal)**: Sending logs, updating internal metrics.
- **Local Read**: Reading files, listing directories.

### 🟡 Medium Stakes (Notify)

*Action proceeds, but notifies the user.*

- **Read Access (Private)**: Reading .env templates (never secrets), reading user emails.
- **Strict Communication**: Sending templated updates.
- **Local Write (Non-Destructive)**: Creating new files, appending to logs.

### 🔴 High Stakes (Require Approval)

*Action MUST PAUSE and wait for explicit user confirmation.*

- **Write Access (Private/Prod)**: Updating databases, changing billing, deploying to production.
- **External Communication**: Sending emails, posting to Slack/Social Media.
- **Destructive Local Write**: Deleting files, overwriting critical config, `rm -rf`.
- **Auth/Secrets**: Handling API keys, login flows.

## The Approval Flow

When a **High Stakes** action is identified:

1. **PAUSE**: Do not execute the tool/command.
2. **REQUEST**: Display a clear warning to the user.
    > "⚠️ **HIGH STAKES ACTION DETECTED**
    > I am about to [describe action].
    > This is considered High Stakes because [reason].
    >
    > Responde **'Proceder'** para continuar o **'Cancelar'** para abortar."
3. **WAIT**: Wait for user input.
4. **VERIFY**:
    - If user says "Proceder" (or "Proceed", "Yes", "Go"): **EXECUTE**.
    - If user says anything else: **ABORT**.

## Implementation in Agents

All agents operating under Git-Core Protocol must implement this check before:

1. Running shell commands that delete/overwrite.
2. Calling tools that deploy or publish.
3. Modifying `AGENTS.md` or `.✨/ARCHITECTURE.md`.

## Future: HumanLayer SDK

In the future, this protocol will be enforced programmatically using the HumanLayer SDK (`@require_approval` decorators). For now, it is a behavioral protocol enforced by system prompts.
