# Agent Communication Protocol

**Version:** 1.0
**Last Updated:** 2026-02-03

This document formalizes how MAW agents communicate with each other through Linear issues, PR comments, and labels.

---

## 1. Handoff Payloads

Each agent transition requires specific data to be passed. Missing required data blocks the receiving agent.

### PM → Builder

| Field | Required | Location | Description |
|-------|----------|----------|-------------|
| Epic label | Yes | Linear labels | `epic:<name>` (auth, generation, payments, etc.) |
| Size label | Yes | Linear labels | `XS`, `S`, `M`, `L`, or `XL` |
| Estimate | Yes | Linear estimate | Fibonacci points (1, 2, 3, 5, 8) |
| Summary | Yes | Issue description | What and why |
| Acceptance criteria | Yes | Issue description | Checkbox list |
| CUJ references | M+ | Issue description | `#cuj-name` tags |
| Test plan | M+ | Issue description | Exact commands to run |

### Builder → Tester

| Field | Required | Location | Description |
|-------|----------|----------|-------------|
| PR number | Yes | Linear comment | GitHub PR reference |
| Branch name | Yes | Linear comment | Feature branch name |
| Spec path | M+ | Linear comment | `specs/<num>-<name>/spec.md` |
| Test plan path | M+ | Linear comment | `specs/<num>-<name>/test-plan.md` |
| Test scope | Yes | PR body | Commands or CUJ list |
| `PR-Ready` label | Yes | Linear labels | Signals handoff complete |

### Tester → Admin

| Field | Required | Location | Description |
|-------|----------|----------|-------------|
| Test results | Yes | Linear comment | Pass/fail with counts |
| Screenshots | Yes | Linear comment | Visual evidence |
| Verification checklist | Yes | Linear comment | Human test steps |
| `Tests-Passed` label | Yes | Linear labels | Signals tests complete |
| Console errors | If any | Linear comment | Any JS/API errors |

### Tester → Builder (Failure)

| Field | Required | Location | Description |
|-------|----------|----------|-------------|
| Failure list | Yes | Linear comment | What failed |
| Sub-issues | Yes | Linear sub-issues | One per failure |
| Screenshots | Yes | Sub-issues | Visual evidence |
| Steps to reproduce | Yes | Sub-issues | How to trigger |
| `Tests-Failed` label | Yes | Linear labels | Signals failure |

### Admin → Production

| Field | Required | Location | Description |
|-------|----------|----------|-------------|
| Deployment URLs | Yes | Linear comment | Frontend + Backend |
| Health check results | Yes | Linear comment | Pass/fail |
| Smoke test results | Yes | Linear comment | Critical path tests |
| Rollback command | Yes | Linear comment | How to revert |
| `In-Production` label | Yes | Linear labels | Signals live |

---

## 2. Linear Issue Schema

### Required Structure

```markdown
# YAR-XXX: <Imperative verb> <object>

## Summary
<1-2 sentences: What this does and why>

## Acceptance Criteria
- [ ] <Criterion 1>
- [ ] <Criterion 2>
- [ ] <Criterion 3>

## CUJs
- #<cuj-1>: <description>
- #<cuj-2>: <description>

## Test Plan

**Epic:** epic:<name>
**Size:** <XS|S|M|L|XL>

### Automated Tests
```bash
<exact command to run>
```

### Manual Verification
- [ ] <manual check 1>
- [ ] <manual check 2>
```

### Required Labels

| Label | When Required | Set By |
|-------|---------------|--------|
| `epic:<name>` | Always | PM |
| `<XS\|S\|M\|L\|XL>` | Always | PM or Builder |
| `PR-Ready` | After PR created | Builder |
| `Testing` | During test run | Tester |
| `Tests-Passed` | All tests pass | Tester |
| `Tests-Failed` | Any test fails | Tester |
| `On-Staging` | After staging deploy | Admin |
| `Staging-Verified` | Staging tests pass | Tester |
| `Human-Verified` | Human approves | Human |
| `In-Production` | Live in prod | Admin |

### Required Estimate

| Size | Points | Meaning |
|------|--------|---------|
| XS | 1 | Typo, single-line fix |
| S | 2 | Single-file change |
| M | 3 | Multi-file, new component |
| L | 5 | Full-stack feature |
| XL | 8 | Epic, major refactor |

---

## 3. Handoff Comment Templates

### Builder → Tester Handoff

```markdown
## 🔄 Handoff: Builder → Tester

**Issue:** YAR-<number>
**PR:** #<pr_number>
**Branch:** `yar-<number>-<short-name>`

### Issue Context
- **Size:** <XS|S|M|L|XL>
- **Epic:** epic:<name>
- **CUJs:** #<cuj-1>, #<cuj-2>

### Artifacts
- Spec: `specs/<number>-<name>/spec.md`
- Test Plan: `specs/<number>-<name>/test-plan.md`

### Test Scope
```bash
<exact test command>
```

### What to Verify
1. <key behavior 1>
2. <key behavior 2>
3. <key behavior 3>

@tester Ready for E2E testing.
```

### Tester → Admin Handoff (Pass)

```markdown
## ✅ Tests Passed

**Issue:** YAR-<number>
**PR:** #<pr_number>

### Test Results
- **Total:** X tests
- **Passed:** X
- **Failed:** 0
- **Skipped:** 0

### Coverage
- [x] #<cuj-1>: <description>
- [x] #<cuj-2>: <description>

### Screenshots
<attach key screenshots>

### Console Errors
None

---

## 🧪 Human Verification Checklist

**Staging URL:** https://staging.yarda.ai?x-vercel-protection-bypass=<token>&x-vercel-set-bypass-cookie=true

### Test 1: <Feature Name>
| Step | Expected Result |
|------|-----------------|
| Navigate to <url> | Page loads |
| Click <element> | <action occurs> |
| Verify <state> | <expected state> |

### Test 2: <Feature Name>
| Step | Expected Result |
|------|-----------------|
| <action> | <result> |

---

**If ALL tests pass:** Add `Human-Verified` label
**If ANY test fails:** Add `Tests-Failed` label with details

@human Ready for validation.
```

### Tester → Builder Handoff (Failure)

```markdown
## ❌ Tests Failed

**Issue:** YAR-<number>
**PR:** #<pr_number>

### Summary
- **Total:** X tests
- **Passed:** X
- **Failed:** Y

### Failures

#### 1. <Test Name>
- **CUJ:** #<cuj-name>
- **Expected:** <expected behavior>
- **Actual:** <actual behavior>
- **Screenshot:** <link>
- **Sub-issue:** YAR-<number>-1

#### 2. <Test Name>
- **CUJ:** #<cuj-name>
- **Expected:** <expected behavior>
- **Actual:** <actual behavior>
- **Screenshot:** <link>
- **Sub-issue:** YAR-<number>-2

### Console Errors
```
<any relevant errors>
```

@builder Fixes needed. See sub-issues for details.
```

### Admin → Production Complete

```markdown
## ✅ Production Deployment Complete

**Issue:** YAR-<number>
**Deployed:** <timestamp>

### URLs
- **Frontend:** https://yarda.pro
- **Backend:** https://yardav5-production.up.railway.app

### Verification
- [x] Health check passed
- [x] Smoke tests passed
- [x] No console errors

### Rollback Command
```bash
git revert <commit_sha> && git push origin main
```

Feature is now live in production.
```

---

## 4. State Detection Logic

Agents use this logic to determine which agent owns an issue:

```python
def get_owner(issue) -> str | None:
    """
    Determine which agent should act on this issue.
    Returns: 'pm', 'builder', 'tester', 'admin', or None (human/done)
    """
    labels = {label.name for label in issue.labels}

    # Terminal state - no owner
    if "In-Production" in labels:
        return None

    # Admin owns - ready for production
    if "Human-Verified" in labels:
        return "admin"

    # Human owns - awaiting validation (no agent)
    if "Staging-Verified" in labels:
        return None  # Human must add Human-Verified
    if "Tests-Passed" in labels:
        return None  # Human must validate

    # Tester owns - staging verification
    if "On-Staging" in labels:
        return "tester"

    # Tester owns - PR testing
    if "PR-Ready" in labels:
        return "tester"
    if "Testing" in labels:
        return "tester"

    # Builder owns - fix failures
    if "Tests-Failed" in labels:
        return "builder"

    # Builder owns - has spec, needs implementation
    if has_spec_or_criteria(issue) and not has_linked_pr(issue):
        return "builder"

    # PM owns - needs elaboration
    if not has_epic_label(labels):
        return "pm"
    if not has_size_label(labels):
        return "pm"
    if not has_acceptance_criteria(issue):
        return "pm"

    # Default to builder if has epic/size but no PR
    return "builder"


def has_epic_label(labels: set) -> bool:
    return any(l.startswith("epic:") for l in labels)


def has_size_label(labels: set) -> bool:
    return bool(labels & {"XS", "S", "M", "L", "XL"})


def has_spec_or_criteria(issue) -> bool:
    desc = issue.description or ""
    return "## Acceptance Criteria" in desc or "## Summary" in desc


def has_acceptance_criteria(issue) -> bool:
    desc = issue.description or ""
    return "## Acceptance Criteria" in desc and "- [ ]" in desc


def has_linked_pr(issue) -> bool:
    # Check for PR link in description or attachments
    return "github.com" in (issue.description or "") and "/pull/" in (issue.description or "")
```

---

## 5. Error Communication

### Error Comment Template

```markdown
## ❌ Agent Error: <Agent Name>

**Issue:** YAR-<number>
**Phase:** <current phase>
**Timestamp:** <ISO timestamp>

### Error Type
<One of: Test Failure, Deployment Failure, API Error, Timeout, Unknown>

### Details
<Specific error message or description>

### Context
```
<Stack trace, logs, or additional context>
```

### Recovery Action
<What the next agent/human should do>

### Blocking
- [ ] This error blocks further progress
- [ ] Manual intervention required
```

### Error Types

| Error Type | Set By | Recovery |
|------------|--------|----------|
| Test Failure | Tester | Builder fixes, re-adds PR-Ready |
| Deployment Failure | Admin | Check logs, retry or rollback |
| API Error | Any | Retry or escalate to human |
| Timeout | Any | Retry with longer timeout |
| Linear API Error | Any | Retry 3x, then manual tracking |
| GitHub API Error | Any | Retry 3x, then manual PR |

---

## 6. Validation Rules

### Before Handoff Validation

Each agent MUST validate before handing off:

**PM → Builder:**
- [ ] Epic label exists
- [ ] Size label or estimate exists
- [ ] Summary section exists
- [ ] Acceptance criteria exist (with checkboxes)
- [ ] CUJs listed (for M+)
- [ ] Test plan included (for M+)

**Builder → Tester:**
- [ ] PR created and linked
- [ ] Branch pushed to origin
- [ ] Unit tests pass locally
- [ ] Spec committed (for M+)
- [ ] Test plan committed (for M+)
- [ ] Handoff comment posted
- [ ] `PR-Ready` label added

**Tester → Admin:**
- [ ] All tests executed
- [ ] Results documented with screenshots
- [ ] Sub-issues created for failures (if any)
- [ ] Human verification checklist posted
- [ ] Correct label set (`Tests-Passed` or `Tests-Failed`)

**Admin → Production:**
- [ ] `Human-Verified` label present
- [ ] Health checks pass
- [ ] Smoke tests pass
- [ ] Rollback command documented
- [ ] `In-Production` label added
- [ ] Issue marked Done

---

## 7. Label State Machine

```
                                    ┌────────────────┐
                                    │                │
                                    ▼                │
┌──────────┐   ┌──────────┐   ┌─────────────┐   ┌───┴──────────┐
│ (no      │──▶│ PR-Ready │──▶│   Testing   │──▶│ Tests-Passed │
│  label)  │   └──────────┘   └─────────────┘   └──────────────┘
└──────────┘         ▲              │                   │
     │               │              ▼                   │
     │               │        ┌─────────────┐           │
     │               └────────│Tests-Failed │           │
     │                        └─────────────┘           │
     │                                                  │
     │         ┌────────────────────────────────────────┘
     │         │
     │         ▼
     │   ┌──────────────┐   ┌─────────────────┐   ┌──────────────┐
     │   │  On-Staging  │──▶│Staging-Verified │──▶│Human-Verified│
     │   └──────────────┘   └─────────────────┘   └──────────────┘
     │         │                                         │
     │         ▼                                         │
     │   ┌─────────────┐                                 │
     └───│Tests-Failed │                                 │
         └─────────────┘                                 │
                                                         ▼
                                                  ┌──────────────┐
                                                  │In-Production │
                                                  └──────────────┘
```

### Valid Transitions

| From | To | Triggered By |
|------|----|--------------|
| (none) | PR-Ready | Builder creates PR |
| PR-Ready | Testing | Tester starts |
| Testing | Tests-Passed | All tests pass |
| Testing | Tests-Failed | Any test fails |
| Tests-Failed | PR-Ready | Builder fixes |
| Tests-Passed | On-Staging | Admin deploys (L/XL) |
| Tests-Passed | In-Production | Admin deploys (XS/S/M) |
| On-Staging | Staging-Verified | Tester verifies staging |
| On-Staging | Tests-Failed | Staging tests fail |
| Staging-Verified | Human-Verified | Human approves |
| Human-Verified | In-Production | Admin promotes |

### Invalid Transitions (Blocked)

| From | To | Reason |
|------|----|--------|
| PR-Ready | In-Production | Must pass testing |
| Tests-Failed | In-Production | Must fix and retest |
| On-Staging | In-Production | Must have Human-Verified |
| (any) | Human-Verified | Only humans can set |

---

## 8. Quick Reference

### Agent Ownership by Label

| Labels Present | Owner |
|----------------|-------|
| In-Production | None (done) |
| Human-Verified | Admin |
| Staging-Verified | Human |
| Tests-Passed | Human |
| On-Staging | Tester |
| PR-Ready, Testing | Tester |
| Tests-Failed | Builder |
| (has spec, no PR) | Builder |
| (missing epic/size) | PM |

### Required Comment Tags

| Tag | Purpose |
|-----|---------|
| `@builder` | Notify Builder agent |
| `@tester` | Notify Tester agent |
| `@admin` | Notify Admin agent |
| `@human` | Notify human reviewer |

---

## Related Documentation

- [sop.md](./sop.md) - Main workflow SOP
- [../MULTI_AGENT_WORKFLOW.md](../MULTI_AGENT_WORKFLOW.md) - Workflow overview
- [../EPIC_REGISTRY.md](../EPIC_REGISTRY.md) - Epic and CUJ definitions
