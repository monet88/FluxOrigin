# Plan: Optimize beads-planner Skill

**Date:** 2026-01-05
**Priority:** Medium
**Status:** ✅ Completed

## Overview

Refactor `beads-planner` skill from 242-line monolithic SKILL.md to modular structure with progressive disclosure. Target: <100 lines SKILL.md + references + automation scripts.

## Current State

- SKILL.md: 242 lines (2.4x over limit)
- No references folder
- No automation scripts
- Output template embedded in main file

## Target State

```
beads-planner/
├── SKILL.md (~80 lines)
├── references/
│   ├── bd-commands.md
│   ├── fields-guide.md
│   ├── output-template.md
│   └── bv-validation.md
└── scripts/
    ├── validate-plan.cjs
    └── generate-summary.cjs
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
bd list --json | node ~/.claude/skills/beads-planner/scripts/generate-summary.cjs
```

## Next Steps

After approval, start Phase 1: Extract references from monolithic SKILL.md.
