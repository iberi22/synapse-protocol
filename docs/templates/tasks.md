---
title: "Task List Template"
type: TEMPLATE
id: "template-tasks"
created: 2025-12-02
updated: 2025-12-02
source: "Extracted from CDE Orchestrator MCP (archived)"
summary: |
  Template for executable task checklists organized by phases.
  Tracks implementation progress and dependencies.
---

# Tasks: [FEATURE NAME]

**Issue**: #[NUMBER]
**Spec**: [link] | **Plan**: [link]

## Legend

- `[P]` = Can run in parallel (no dependencies)
- `[US1]` = Belongs to User Story 1

---

## Phase 1: Setup

- [ ] T001 Create project structure
- [ ] T002 [P] Install dependencies
- [ ] T003 [P] Configure linting/formatting

---

## Phase 2: Foundation (Blocks all stories)

⚠️ **Must complete before user story work**

- [ ] T004 Setup database/storage
- [ ] T005 [P] Implement auth framework (if needed)
- [ ] T006 [P] Configure error handling
- [ ] T007 Create base models/types

**Checkpoint**: ✅ Foundation ready

---

## Phase 3: User Story 1 - [Title] (P1) 🎯 MVP

**Goal**: [What this delivers]

### Tests (write first, should fail)
- [ ] T008 [P] [US1] Unit test for [component]
- [ ] T009 [P] [US1] Integration test for [flow]

### Implementation
- [ ] T010 [US1] Create [model/entity]
- [ ] T011 [US1] Implement [service/logic]
- [ ] T012 [US1] Add [endpoint/UI]
- [ ] T013 [US1] Add validation & error handling

**Checkpoint**: ✅ US1 independently testable

---

## Phase 4: User Story 2 - [Title] (P2)

**Goal**: [What this delivers]

- [ ] T014 [US2] [Task description]
- [ ] T015 [US2] [Task description]

**Checkpoint**: ✅ US2 complete

---

## Phase 5: Polish & Review

- [ ] T016 [P] Update documentation
- [ ] T017 [P] Code review cleanup
- [ ] T018 Final integration test
- [ ] T019 Create PR with conventional commit

---

## Progress

| Phase | Tasks | Done | Status |
|-------|-------|------|--------|
| Setup | 3 | 0 | ⬜ |
| Foundation | 4 | 0 | ⬜ |
| US1 (MVP) | 6 | 0 | ⬜ |
| US2 | 2 | 0 | ⬜ |
| Polish | 4 | 0 | ⬜ |
| **Total** | **19** | **0** | **0%** |

---

*Template source: [Git-Core Protocol](https://github.com/iberi22/Git-Core-Protocol)*
*Originally from CDE Orchestrator MCP (archived)*
