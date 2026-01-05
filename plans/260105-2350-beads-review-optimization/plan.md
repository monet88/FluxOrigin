# Plan: Optimize beads-review Skill

**Date:** 2026-01-05
**Priority:** Medium
**Status:** ✅ Completed

## Overview

Refactor `beads-review` skill from 299-line monolithic SKILL.md to modular structure with progressive disclosure. Target: <100 lines SKILL.md + references + automation scripts.

## Current State

- SKILL.md: 299 lines (3x over limit)
- No references folder
- No automation scripts
- Output templates embedded (80+ lines)
- 5-pass checklists inline

## Target State

```
beads-review/
├── SKILL.md (~80 lines)
├── references/
│   ├── graph-metrics.md
│   ├── pass-checklists.md
│   ├── output-templates.md
│   └── quality-criteria.md
└── scripts/
    ├── health-check.cjs
    └── run-review-pass.cjs
```

## Phases

| # | Phase | Status | File |
|---|-------|--------|------|
| 1 | Extract references | ✅ Done | [phase-01-extract-references.md](phase-01-extract-references.md) |
| 2 | Create automation scripts | ✅ Done | [phase-02-create-scripts.md](phase-02-create-scripts.md) |
| 3 | Rewrite SKILL.md | ✅ Done | [phase-03-rewrite-skill-md.md](phase-03-rewrite-skill-md.md) |
| 4 | Test and validate | ✅ Done | [phase-04-test-validate.md](phase-04-test-validate.md) |

## Success Criteria

- [ ] SKILL.md < 100 lines
- [ ] All reference files < 100 lines each
- [ ] Scripts work on Windows (Node.js)
- [ ] No functionality lost
- [ ] Progressive disclosure enabled

## Quick Commands

```bash
# After implementation, test with:
node ~/.claude/skills/beads-review/scripts/health-check.cjs
```

## Next Steps

Start Phase 1: Extract references from monolithic SKILL.md.
