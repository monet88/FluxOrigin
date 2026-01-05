# Phase 2: Create Automation Scripts

**Date:** 2026-01-05
**Priority:** High
**Status:** Pending

## Context Links

- [Main Plan](plan.md)
- [Phase 1](phase-01-extract-references.md)

## Overview

Create Node.js scripts to automate plan validation and summary generation.

## Key Insights

- Scripts replace manual verification steps
- Node.js for Windows compatibility
- Read from `bd` CLI JSON output

## Requirements

1. `validate-plan.cjs` - Check dependency graph
2. `generate-summary.cjs` - Generate ASCII summary

## Architecture

```
scripts/
├── validate-plan.cjs    # Validate graph, detect cycles
└── generate-summary.cjs # Generate output from bd list --json
```

## Related Code Files

| File | Purpose |
|------|---------|
| `validate-plan.cjs` | Run `bv --robot-insights`, parse cycles |
| `generate-summary.cjs` | Parse `bd list --json`, format summary |

## Implementation Steps

### validate-plan.cjs

```javascript
// Input: none (reads from bv command)
// Output: validation report (cycles, ready issues, suggestions)
// Usage: node validate-plan.cjs
```

Features:
- Run `bv --robot-insights` and parse JSON
- Check for cycles (must be empty)
- Run `bv --robot-suggest` for missing deps
- Exit code 0 if valid, 1 if issues

### generate-summary.cjs

```javascript
// Input: stdin (bd list --json)
// Output: formatted ASCII summary
// Usage: bd list --json | node generate-summary.cjs
```

Features:
- Parse issues from stdin
- Group by epic (parent)
- Build dependency layers
- Output ASCII table format

## Todo List

- [ ] Create scripts directory
- [ ] Implement validate-plan.cjs
- [ ] Implement generate-summary.cjs
- [ ] Test on Windows
- [ ] Add error handling

## Success Criteria

- [ ] Scripts run on Windows (Node.js)
- [ ] validate-plan.cjs detects cycles
- [ ] generate-summary.cjs formats output
- [ ] No external dependencies (stdlib only)

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| BD CLI not installed | Check and show helpful error |
| JSON parse errors | Try-catch with clear messages |

## Security Considerations

- Scripts only read from CLI tools
- No network access
- No file modifications

## Next Steps

Proceed to Phase 3: Rewrite SKILL.md.
