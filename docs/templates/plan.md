---
title: "Implementation Plan Template"
type: TEMPLATE
id: "template-plan"
created: 2025-12-02
updated: 2025-12-02
source: "Extracted from CDE Orchestrator MCP (archived)"
summary: |
  Template for technical implementation plans with architecture, 
  design decisions, and testing strategy. Defines HOW.
---

# Implementation Plan: [FEATURE]

**Issue**: #[NUMBER] | **Date**: [DATE] | **Spec**: [link to spec.md]

## Summary

[Primary requirement + technical approach]

## Technical Context

| Aspect | Decision |
|--------|----------|
| **Language/Version** | [e.g., Python 3.11, Rust 1.75] |
| **Dependencies** | [e.g., FastAPI, React] |
| **Storage** | [e.g., PostgreSQL, files, N/A] |
| **Testing** | [e.g., pytest, jest] |
| **Target Platform** | [e.g., Linux, Web, iOS] |

## Architecture Decision

[Brief description of the chosen approach]

**Why this approach**:
- [Reason 1]
- [Reason 2]

**Alternatives considered**:
- [Alternative 1] - Rejected because [reason]
- [Alternative 2] - Rejected because [reason]

## Project Structure

```
src/
├── [module]/
│   ├── [file].py
│   └── [file].py
└── tests/
    └── test_[module].py
```

## Complexity Estimate

| Component | Effort | Risk |
|-----------|--------|------|
| [Component 1] | [hours/days] | [Low/Medium/High] |
| [Component 2] | [hours/days] | [Low/Medium/High] |

**Total Estimate**: [X days]

## Testing Strategy

- **Unit Tests**: [what to test]
- **Integration Tests**: [what to test]
- **Manual Verification**: [steps]

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk 1] | [High/Medium/Low] | [Strategy] |

---

*Template source: [Git-Core Protocol](https://github.com/iberi22/Git-Core-Protocol)*
*Originally from CDE Orchestrator MCP (archived)*
