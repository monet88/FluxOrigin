# Phase 1: Extract References

**Date:** 2026-01-05
**Priority:** High
**Status:** Pending

## Context Links

- [Main Plan](plan.md)
- Source: `~/.claude/skills/beads-planner/SKILL.md`

## Overview

Extract content sections from monolithic SKILL.md into modular reference files.

## Key Insights

- Current SKILL.md contains 4 distinct content blocks that can be extracted
- Each extracted file should be <100 lines
- Content remains unchanged, just reorganized

## Requirements

1. Create `references/` directory
2. Extract BD commands reference
3. Extract fields guide
4. Extract output template
5. Extract bv validation guide

## Architecture

```
references/
├── bd-commands.md      # Lines 48-70 (commands reference)
├── fields-guide.md     # Lines 27-45 (all available fields)
├── output-template.md  # Lines 154-214 (ASCII summary)
└── bv-validation.md    # Lines 116-138, 232-241 (validation)
```

## Related Code Files

| File | Action |
|------|--------|
| `SKILL.md` | Source - extract content |
| `references/*.md` | Target - new files |

## Implementation Steps

1. Create `references/` directory
2. Extract lines 27-45 → `fields-guide.md`
3. Extract lines 48-70 → `bd-commands.md`
4. Extract lines 116-138 + 232-241 → `bv-validation.md`
5. Extract lines 154-214 → `output-template.md`
6. Add frontmatter headers to each file

## Todo List

- [ ] Create references directory
- [ ] Create fields-guide.md
- [ ] Create bd-commands.md
- [ ] Create bv-validation.md
- [ ] Create output-template.md

## Success Criteria

- [ ] 4 reference files created
- [ ] Each file < 100 lines
- [ ] All content preserved
- [ ] Proper markdown formatting

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Content loss | Verify line counts after extraction |
| Broken references | Update SKILL.md links in Phase 3 |

## Security Considerations

None - restructuring only, no new functionality.

## Next Steps

Proceed to Phase 2: Create automation scripts.
