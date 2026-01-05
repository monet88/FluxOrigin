# Phase 3: Rewrite SKILL.md

**Date:** 2026-01-05
**Priority:** High
**Status:** Pending

## Context Links

- [Main Plan](plan.md)
- [Phase 1](phase-01-extract-references.md)
- [Phase 2](phase-02-create-scripts.md)

## Overview

Rewrite SKILL.md to <100 lines with links to references and scripts.

## Key Insights

- Keep core workflow in SKILL.md
- Link to references for details
- Link to scripts for automation
- Preserve activation triggers in description

## Requirements

1. Frontmatter with rich description (activation triggers)
2. Core philosophy (5 lines)
3. Mission statement (5 lines)
4. Workflow phases with reference links (30 lines)
5. Script usage (10 lines)
6. Best practices (10 lines)
7. Reference table (10 lines)

## Architecture

```markdown
---
name: beads-planner
description: "Create Beads epics/issues from plans. INVOKE WHEN: 'tạo epic', 'create issues', 'file issues', 'translate plan to beads'. Transforms plans into actionable issues with dependencies."
version: 2.0.0
---

# Brief intro (5 lines)
# Workflow (30 lines) - links to references
# Scripts (10 lines)
# Best practices (10 lines)
# Reference table (10 lines)
```

## Related Code Files

| File | Action |
|------|--------|
| `SKILL.md` | Rewrite |
| `references/*.md` | Link to |
| `scripts/*.cjs` | Document usage |

## Implementation Steps

1. Backup current SKILL.md
2. Write new frontmatter (preserve triggers)
3. Write core philosophy section
4. Write workflow with reference links
5. Write script usage section
6. Write reference table
7. Verify < 100 lines

## New SKILL.md Structure

```
Lines 1-6:   Frontmatter
Lines 7-12:  Core Philosophy
Lines 13-18: Mission
Lines 19-50: Workflow (6 phases, 5 lines each)
Lines 51-60: Script Usage
Lines 61-70: Best Practices
Lines 71-80: Reference Table
```

## Todo List

- [ ] Backup current SKILL.md
- [ ] Write new frontmatter
- [ ] Write core sections
- [ ] Write workflow phases
- [ ] Write script/reference sections
- [ ] Verify line count

## Success Criteria

- [ ] SKILL.md < 100 lines
- [ ] All activation triggers preserved
- [ ] Links to references work
- [ ] Script usage documented
- [ ] No functionality lost

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Lost activation triggers | Copy exact description from current |
| Missing workflow steps | Cross-check against current file |

## Security Considerations

None - documentation only.

## Next Steps

Proceed to Phase 4: Test and validate.
