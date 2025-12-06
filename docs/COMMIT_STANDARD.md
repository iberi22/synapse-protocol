---
title: "Extended Commit Message Standard"
type: STANDARD
id: "std-commit-message"
created: 2025-12-01
updated: 2025-12-01
agent: copilot
model: gemini-3-pro
requested_by: system
summary: |
  Standard for extended conventional commits in AI-assisted development.
keywords: [git, commits, standard, conventional-commits]
tags: ["#standard", "#git", "#convention"]
project: Git-Core-Protocol
---

# 📝 Extended Commit Message Standard

## Overview

This standard extends [Conventional Commits](https://conventionalcommits.org) for AI-assisted development, providing rich context in commit messages for both humans and AI agents.

---

## 📋 Commit Message Structure

```
<type>(<scope>): <subject> [#issue]

[body - WHAT and WHY]

[AI-Context: <context for future AI sessions>]

[footer]
```

---

## 🏷️ Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(auth): add OAuth2 login` |
| `fix` | Bug fix | `fix(api): resolve null pointer in user fetch` |
| `docs` | Documentation | `docs(readme): update installation steps` |
| `docs(agent)` | Agent-generated docs | `docs(agent): add PROMPT for Jules` |
| `style` | Code style (no logic change) | `style: format with prettier` |
| `refactor` | Code restructuring | `refactor(db): extract query builder` |
| `perf` | Performance improvement | `perf(cache): implement Redis caching` |
| `test` | Tests | `test(auth): add unit tests for login` |
| `chore` | Maintenance | `chore(deps): update dependencies` |
| `ci` | CI/CD changes | `ci: add GitHub Actions workflow` |
| `revert` | Revert previous commit | `revert: feat(auth): add OAuth2 login` |

---

## 🎯 Scope Examples

```
feat(auth): ...        # Authentication module
feat(api): ...         # API layer
feat(ui): ...          # User interface
feat(db): ...          # Database
feat(core): ...        # Core business logic
fix(validation): ...   # Input validation
docs(agent): ...       # AI-generated documentation
chore(protocol): ...   # Git-Core Protocol files
```

---

## 📖 Body Guidelines

The body should answer:
1. **WHAT** changed (brief description)
2. **WHY** it changed (motivation, problem being solved)
3. **IMPACT** on the system (if significant)

### Example:

```
feat(payments): implement Stripe subscription billing #42

Adds subscription management with Stripe integration including:
- Monthly/yearly billing cycles
- Automatic invoice generation
- Webhook handling for payment events

This enables the SaaS monetization strategy outlined in the
business requirements. Users can now upgrade/downgrade plans
without manual intervention.

AI-Context: Payment system uses Stripe SDK v3. Webhook endpoint
at /api/webhooks/stripe. Test mode keys in .env.example.

Closes #42
Refs: #38, #39
```

---

## 🤖 AI-Context Section

The `AI-Context:` section is **optional** but highly valuable for AI-assisted development. It provides quick context for future AI sessions.

### When to include AI-Context:

- Complex architectural decisions
- Non-obvious implementation choices
- Important file locations
- Environment/config requirements
- Related issues or PRs

### Format:

```
AI-Context: <one-liner or multi-line context>
```

### Examples:

```
AI-Context: Uses singleton pattern for DB connection. Config in src/config/db.ts

AI-Context: This is a temporary fix. Proper solution requires #56 to be completed first.

AI-Context:
- Auth flow: JWT stored in httpOnly cookie
- Refresh token rotation enabled
- Session timeout: 15min access, 7d refresh
```

---

## 🔗 Footer Tokens

| Token | Purpose | Example |
|-------|---------|---------|
| `Closes` | Auto-close issue on merge | `Closes #42` |
| `Fixes` | Same as Closes | `Fixes #42` |
| `Refs` | Reference without closing | `Refs: #38, #39` |
| `BREAKING CHANGE` | Breaking API change | `BREAKING CHANGE: renamed /api/v1 to /api/v2` |
| `Co-authored-by` | Credit co-authors | `Co-authored-by: Name <email>` |
| `Reviewed-by` | Credit reviewers | `Reviewed-by: @username` |

---

## 📏 Length Guidelines

| Section | Max Length | Notes |
|---------|-----------|-------|
| Subject line | 72 chars | Include type, scope, description |
| Body lines | 80 chars | Wrap longer lines |
| AI-Context | 200 chars | Keep concise, can be multi-line |

---

## ✅ Good Examples

### Simple fix:
```
fix(auth): prevent session timeout on active users #15

Users were being logged out even during active sessions.
Added heartbeat mechanism to extend session on activity.

Closes #15
```

### Feature with AI-Context:
```
feat(notifications): add real-time push notifications #28

Implements WebSocket-based notification system with:
- Connection pooling for scalability
- Automatic reconnection with exponential backoff
- Message queuing for offline users

AI-Context: Uses Socket.io v4. Redis adapter for horizontal scaling.
Notification types defined in src/types/notifications.ts

Closes #28
Refs: #24
```

### Breaking change:
```
feat(api)!: migrate to REST API v2 #50

Complete API redesign following OpenAPI 3.0 spec.
All endpoints now use consistent response format.

BREAKING CHANGE: All /api/v1/* endpoints removed.
Migrate to /api/v2/* with new authentication headers.

AI-Context: Migration guide in docs/API_MIGRATION.md.
Old endpoints return 301 redirect until v3.0.

Closes #50
```

---

## ❌ Bad Examples

```
# Too vague
fix: fixed stuff

# No context
update code

# No issue reference
feat: add new feature

# Subject too long
feat(authentication-system): implement OAuth2 login with Google, Facebook, and GitHub providers including refresh token rotation
```

---

## 🔄 Integration with Git-Core Protocol

1. **Always reference issues** in commits
2. **Use `Closes #X`** to auto-close issues
3. **Add AI-Context** for complex changes
4. **Keep commits atomic** - one logical change per commit (see [Atomic Commits Guide](./ATOMIC_COMMITS.md))
5. **Commit often, perfect later, publish once**

---

## 🏷️ YAML Frontmatter for Agent Docs

When creating documents in `docs/agent-docs/`, always include YAML frontmatter meta tags for rapid AI scanning. See `docs/agent-docs/README.md` for the complete specification.

### Quick Reference

```yaml
---
title: "Document Title"
type: PROMPT | RESEARCH | STRATEGY | SPEC | GUIDE | REPORT | ANALYSIS
created: 2025-11-29
agent: copilot | cursor | windsurf | claude | jules
model: gpt-4o | claude-opus-4 | etc
summary: "1-3 sentences describing content"
keywords: [auth, oauth, security]
tags: ["#auth", "#security"]
status: draft | review | approved | deprecated
priority: critical | high | medium | low
confidence: 0.95
---
```

This enables AI agents to scan document metadata without reading full content.

---

*This standard ensures rich, searchable commit history that benefits both human developers and AI agents.*

