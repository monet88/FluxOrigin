# Phase 4: Test and Validate

**Date:** 2026-01-05
**Priority:** High
**Status:** Pending

## Context Links

- [Main Plan](plan.md)
- [Phase 1](phase-01-extract-references.md)
- [Phase 2](phase-02-create-scripts.md)
- [Phase 3](phase-03-rewrite-skill-md.md)

## Overview

Test refactored skill with real usage and validate all components work.

## Key Insights

- Test scripts on Windows
- Verify skill activation triggers
- Check progressive disclosure works
- Validate no functionality lost

## Requirements

1. All scripts execute without errors
2. SKILL.md activates on trigger phrases
3. References load when needed
4. Output matches expected format

## Test Cases

### T1: Script Validation

```bash
# Test validate-plan.cjs
node ~/.claude/skills/beads-planner/scripts/validate-plan.cjs

# Test generate-summary.cjs
bd list --json | node ~/.claude/skills/beads-planner/scripts/generate-summary.cjs
```

### T2: Skill Activation

Trigger phrases to test:
- "tạo epic"
- "create issues"
- "file issues"
- "translate plan to beads"

### T3: Reference Loading

Verify Claude loads references when:
- User asks about BD commands
- User asks about fields
- User needs output template

## Implementation Steps

1. Run scripts manually
2. Fix any errors
3. Test skill activation
4. Verify reference loading
5. Document any issues

## Todo List

- [ ] Run validate-plan.cjs
- [ ] Run generate-summary.cjs
- [ ] Test skill activation
- [ ] Verify references load
- [ ] Fix any issues found

## Success Criteria

- [ ] Scripts run without errors
- [ ] Skill activates on triggers
- [ ] References load correctly
- [ ] Output format matches template
- [ ] Line counts within limits

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Script fails | Debug and fix |
| Skill not activating | Check description keywords |

## Security Considerations

None - testing only.

## Next Steps

After validation passes, skill optimization is complete.
