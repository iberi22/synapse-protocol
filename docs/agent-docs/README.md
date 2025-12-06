---
title: "Agent Documentation System"
type: DOCUMENTATION
id: "doc-agent-docs-readme"
created: 2025-12-01
updated: 2025-12-01
agent: copilot
model: gemini-3-pro
requested_by: system
summary: |
  Documentation for the user-controlled agent documentation system.
keywords: [agent-docs, documentation, user-controlled]
tags: ["#documentation", "#agent-docs", "#system"]
project: Git-Core-Protocol
---

# 📄 Agent Documentation System

## Overview

The `docs/agent-docs/` folder is a **user-controlled space** where AI agents can create persistent documentation **ONLY when explicitly requested by the user**.

---

## ⚠️ Critical Rule

> **Agents should NEVER create files in `agent-docs/` unless the user explicitly asks for a document to be saved.**

All other output (summaries, explanations, code reviews) should be provided directly in chat responses.

---

## 🏷️ YAML Frontmatter (REQUIRED)

Every document in `agent-docs/` **MUST** include YAML frontmatter with meta tags for rapid AI agent scanning. This eliminates the need to read entire documents.

### Required Meta Tags

```yaml
---
# Core Identification
title: "Human-readable document title"
type: PROMPT | RESEARCH | STRATEGY | SPEC | GUIDE | REPORT | ANALYSIS
id: "unique-kebab-case-id"

# Temporal
created: 2025-11-29
updated: 2025-11-29
expires: 2026-11-29  # Optional: when content becomes stale

# Attribution
agent: copilot | cursor | windsurf | claude | jules | human
model: gpt-4o | claude-3.5-sonnet | claude-opus | etc
requested_by: user | system | agent-chain

# Content Summary (for rapid scanning)
summary: |
  One to three sentences describing what this document contains
  and its primary purpose. AI agents read this first.

# Semantic Discovery
keywords:
  - keyword1
  - keyword2
  - keyword3
tags:
  - "#auth"
  - "#oauth"
  - "#security"
topics:
  - authentication
  - security
  - user-management

# Relationships
related_issues:
  - "#42"
  - "#56"
related_docs:
  - "SPEC_API_AUTH.md"
supersedes: "OLD_DOC_NAME.md"  # If this replaces another doc
superseded_by: null            # Filled when doc is deprecated

# Context & Scope
project: project-name
module: auth | api | ui | core | etc
language: typescript | python | rust | etc
framework: react | fastapi | axum | etc
priority: critical | high | medium | low
status: draft | review | approved | deprecated

# AI Processing Hints
confidence: 0.95  # Agent's confidence in content accuracy (0-1)
token_estimate: 1500  # Approximate tokens in document
complexity: simple | moderate | complex
audience: developers | architects | all
---
```

### Minimal Required Tags

At minimum, every document MUST have:

```yaml
---
title: "Document Title"
type: PROMPT
created: 2025-11-29
agent: copilot
summary: "Brief description of document purpose"
keywords: [keyword1, keyword2]
tags: ["#tag1", "#tag2"]
---
```

---

## 📝 Allowed Document Types

| Prefix | Purpose | Example Request |
|--------|---------|-----------------|
| `PROMPT_*.md` | Prompts for other AI systems | "Create a prompt for Jules to..." |
| `RESEARCH_*.md` | Research findings & analysis | "Research and save findings about..." |
| `STRATEGY_*.md` | Business/technical strategies | "Document a monetization strategy for..." |
| `SPEC_*.md` | Technical specifications | "Write a spec document for..." |
| `GUIDE_*.md` | How-to guides | "Create a guide on how to..." |
| `REPORT_*.md` | Analysis reports | "Generate a report on..." |
| `ANALYSIS_*.md` | Deep dive analysis | "Analyze and document..." |

---

## 📁 File Naming Convention

```
<TYPE>_<TOPIC>_<DATE>.md

Examples:
- PROMPT_JULES_AUTH_SYSTEM.md
- RESEARCH_AI_AGENTS_2024.md
- STRATEGY_MONETIZATION_SAAS.md
- SPEC_API_DESIGN.md
```

---

## 🎯 When to Create vs When to Chat

### ✅ CREATE a file when user says:
- "Save this as a document"
- "Create a prompt file for..."
- "Document this strategy"
- "Write a spec for..."
- "Generate a report and save it"
- "I need this as a reference document"

### ❌ DO NOT create a file, just respond in chat:
- "Explain how to..."
- "What is the best approach for..."
- "Summarize this code"
- "Review this PR"
- "Help me understand..."

---

## 📋 Document Template

All agent-docs **MUST** include YAML frontmatter followed by structured content:

```markdown
---
title: "Authentication System Implementation Prompt"
type: PROMPT
id: "prompt-jules-auth-system"
created: 2025-11-29
updated: 2025-11-29
agent: copilot
model: claude-opus-4
requested_by: user
summary: |
  Prompt for Jules AI agent to implement OAuth2 authentication
  with Google and GitHub providers for the SaaS platform.
keywords:
  - oauth2
  - authentication
  - jules
  - google-auth
  - github-auth
tags:
  - "#auth"
  - "#security"
  - "#jules"
topics:
  - authentication
  - ai-agents
  - security
related_issues:
  - "#42"
  - "#56"
related_docs:
  - "SPEC_API_AUTH.md"
project: my-saas-app
module: auth
language: typescript
framework: nextjs
priority: high
status: approved
confidence: 0.92
token_estimate: 800
complexity: moderate
audience: developers
---

# Authentication System Implementation Prompt

## Summary

[Brief overview - AI agents can skip to keywords/tags for quick categorization]

## Content

[Main content here]

## References

- [Source 1](url)
- Related: SPEC_API_AUTH.md

---
*Generated by copilot (claude-opus-4) at user's request | 2025-11-29*
```

---

## 🔍 Meta Tag Reference

### Core Identification

| Tag | Required | Description |
|-----|----------|-------------|
| `title` | ✅ | Human-readable title |
| `type` | ✅ | PROMPT, RESEARCH, STRATEGY, SPEC, GUIDE, REPORT, ANALYSIS |
| `id` | ⚡ | Unique kebab-case identifier |

### Temporal

| Tag | Required | Description |
|-----|----------|-------------|
| `created` | ✅ | ISO date (YYYY-MM-DD) |
| `updated` | ⚡ | Last modification date |
| `expires` | ❌ | When content becomes stale |

### Attribution

| Tag | Required | Description |
|-----|----------|-------------|
| `agent` | ✅ | copilot, cursor, windsurf, claude, jules, human |
| `model` | ⚡ | Specific model used (gpt-4o, claude-opus-4, etc) |
| `requested_by` | ⚡ | user, system, agent-chain |

### Content Summary

| Tag | Required | Description |
|-----|----------|-------------|
| `summary` | ✅ | 1-3 sentences for rapid scanning |
| `keywords` | ✅ | Array of searchable terms |
| `tags` | ✅ | Hashtags for categorization |
| `topics` | ⚡ | Broader topic areas |

### Relationships

| Tag | Required | Description |
|-----|----------|-------------|
| `related_issues` | ⚡ | GitHub issue references |
| `related_docs` | ❌ | Links to other docs |
| `supersedes` | ❌ | Doc this replaces |
| `superseded_by` | ❌ | Doc that replaces this |

### Context & Scope

| Tag | Required | Description |
|-----|----------|-------------|
| `project` | ⚡ | Project name |
| `module` | ⚡ | auth, api, ui, core, etc |
| `language` | ⚡ | Primary programming language |
| `framework` | ❌ | Framework if applicable |
| `priority` | ⚡ | critical, high, medium, low |
| `status` | ✅ | draft, review, approved, deprecated |

### AI Processing Hints

| Tag | Required | Description |
|-----|----------|-------------|
| `confidence` | ❌ | Agent confidence 0-1 |
| `token_estimate` | ⚡ | Approximate token count |
| `complexity` | ⚡ | simple, moderate, complex |
| `audience` | ⚡ | developers, architects, all |

**Legend:** ✅ Required | ⚡ Recommended | ❌ Optional

---

## 🔗 Integration with Git-Core Protocol

1. **Reference in Issues**: When creating a document, reference it in the relevant GitHub Issue
2. **Commit Message**: Use `docs(agent): add <TYPE> document for <topic>`
3. **Never Duplicate**: If similar content exists, update the existing document instead

---

## Example Workflow

**User**: "Create a prompt file for Jules to implement the authentication system"

**Agent Actions**:
1. Create `docs/agent-docs/PROMPT_JULES_AUTH_SYSTEM.md`
2. Add to git: `git add docs/agent-docs/PROMPT_JULES_AUTH_SYSTEM.md`
3. Commit: `git commit -m "docs(agent): add PROMPT for Jules auth implementation"`
4. Comment in related issue with link to the document

---

*This system allows for persistent, user-requested documentation while maintaining the Git-Core Protocol's principle of using GitHub Issues for task management.*

