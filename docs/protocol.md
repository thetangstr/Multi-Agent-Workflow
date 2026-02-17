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

### Tester → PM (Pre-Human Validation)

| Field | Required | Location | Description |
|-------|----------|----------|-------------|
| PR Preview URL | Yes | Linear comment | Vercel preview URL for validation |
| Backend URL | Yes | Linear comment | Staging backend URL |
| `Tests-Passed` label | Yes | Linear labels | Signals tests passed on PR Preview |
| Test results summary | Yes | Linear comment | What tests passed |
| Acceptance criteria | Yes | Issue description | Original requirements to validate |

**Environment:** PR Preview (Vercel preview + staging backend)

### PM → Human (After Validation)

| Field | Required | Location | Description |
|-------|----------|----------|-------------|
| Validation report | Yes | Linear comment | Pass/fail with evidence |
| PR Preview URL | Yes | Linear comment | Where human should verify |
| Screenshots/GIFs | Yes | Linear comment | Visual proof |
| UX observations | Recommended | Linear comment | Any friction points |
| `PM-Validated` label | Yes | Linear labels | Signals PM approval |
| Recommendation | Yes | Linear comment | APPROVED or REQUIRES FIXES |

**Environment:** PR Preview (same as PM validation)

### TPM → Production

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
| `PM-Validated` | PM validates as user | PM |
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

### PM Validation Report

```markdown
## 🔍 PM Pre-Human Validation Report

**Issue:** YAR-<number>
**Environment:** <staging|production>
**Validated:** <timestamp>

### Acceptance Criteria
- [x] <criterion 1> ✅
- [x] <criterion 2> ✅
- [ ] <criterion 3> ❌ Issue: <description>

### CUJ Walkthroughs
| CUJ | Status | Notes |
|-----|--------|-------|
| #<cuj-1> | ✅ Pass | <notes> |
| #<cuj-2> | ✅ Pass | <notes> |

### UX Observations
- <any friction points>
- <suggestions for improvement>

### Screenshots/GIFs
<attach visual evidence of user journey>

### Console Errors
None (or list any issues)

---

### Recommendation

**✅ APPROVED for Human Sign-off**
OR
**❌ REQUIRES FIXES** - See sub-issues

@human Ready for final verification.
```

### TPM → Production Complete

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

    Environment context:
    - PR-Ready through PM-Validated: PR Preview environment
    - On-Staging through Staging-Verified: Staging environment
    - In-Production: Production environment
    """
    labels = {label.name for label in issue.labels}

    # Terminal state - no owner
    if "In-Production" in labels:
        return None

    # L/XL: After staging verification, Admin promotes to production
    if "Staging-Verified" in labels:
        return "admin"

    # L/XL: Tester verifies staging deployment
    if "On-Staging" in labels:
        return "tester"

    # Admin deploys after Human-Verified
    # - XS/S/M: directly to production
    # - L/XL: to staging first
    if "Human-Verified" in labels:
        return "admin"

    # Human owns - awaiting final validation on PR Preview
    if "PM-Validated" in labels:
        return None  # Human must add Human-Verified

    # PM owns - needs pre-human validation on PR Preview
    if "Tests-Passed" in labels:
        return "pm"  # PM validates on PR Preview

    # Tester owns - PR testing on PR Preview
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

**Tester → PM (Pre-Human Validation):**
- [ ] Staging tests passed
- [ ] `Staging-Verified` label added
- [ ] Test results posted

**PM → Human:**
- [ ] Feature validated as real user
- [ ] All acceptance criteria checked
- [ ] CUJ walkthroughs completed
- [ ] Screenshots/GIFs captured
- [ ] Validation report posted
- [ ] `PM-Validated` label added

**Admin → Production:**
- [ ] `Human-Verified` label present
- [ ] Health checks pass
- [ ] Smoke tests pass
- [ ] Rollback command documented
- [ ] `In-Production` label added
- [ ] Issue marked Done

---

## 7. Label State Machine

### XS/S/M Flow (Direct to Production)
```
PR-Ready → Testing → Tests-Passed → PM-Validated → Human-Verified → In-Production
[PR Prev]  [PR Prev]  [PR Preview]   [PR Preview]   [PR Preview]    [Production]
              ↓
         Tests-Failed (back to Builder)
```

### L/XL Flow (Via Staging)
```
PR-Ready → Testing → Tests-Passed → PM-Validated → Human-Verified → On-Staging → Staging-Verified → In-Production
[PR Prev]  [PR Prev]  [PR Preview]   [PR Preview]   [PR Preview]    [Staging]    [Staging]          [Production]
              ↓                                                          ↓
         Tests-Failed                                              Tests-Failed
```

### Complete State Diagram

```
                    ┌────────────────────────────────────────────────────┐
                    │                                                    │
                    ▼                                                    │
┌──────────┐   ┌──────────┐   ┌─────────────┐   ┌──────────────┐        │
│ PR-Ready │──▶│ Testing  │──▶│Tests-Passed │──▶│ PM-Validated │        │
│          │   │          │   │             │   │              │        │
│[PR Prev] │   │[PR Prev] │   │[PR Preview] │   │[PR Preview]  │        │
└──────────┘   └──────────┘   └─────────────┘   └──────────────┘        │
     ▲              │                                  │                │
     │              ▼                                  ▼                │
     │         ┌─────────────┐              ┌──────────────────┐        │
     │         │Tests-Failed │              │ Human-Verified   │        │
     │         └─────────────┘              │                  │        │
     │              │                       │ [PR Preview]     │        │
     └──────────────┘                       └──────────────────┘        │
           (back to Builder)                          │                 │
                                        ┌─────────────┴─────────────┐   │
                                        │                           │   │
                               (XS/S/M) ▼                  (L/XL)   ▼   │
                              ┌──────────────┐         ┌──────────────┐ │
                              │In-Production │         │ On-Staging   │ │
                              │              │         │              │ │
                              │[production]  │         │ [staging]    │ │
                              └──────────────┘         └──────────────┘ │
                                                              │         │
                                                              ▼         │
                                                    ┌─────────────────┐ │
                                                    │Staging-Verified │ │
                                                    │                 │ │
                                                    │ [staging]       │ │
                                                    └─────────────────┘ │
                                                              │         │
                                                              ▼         │
                                                    ┌──────────────┐    │
                                                    │In-Production │    │
                                                    │              │    │
                                                    │[production]  │    │
                                                    └──────────────┘    │
                                                              │         │
                                                              └─────────┘
                                                        (Tests-Failed possible)
```

### Valid Transitions

| From | To | Triggered By | Environment |
|------|----|--------------|-------------|
| (none) | PR-Ready | Builder creates PR | PR Preview created |
| PR-Ready | Testing | Tester starts | PR Preview |
| Testing | Tests-Passed | All tests pass | PR Preview |
| Testing | Tests-Failed | Any test fails | PR Preview |
| Tests-Failed | PR-Ready | Builder fixes | localhost → PR Preview |
| Tests-Passed | PM-Validated | PM validates | PR Preview |
| PM-Validated | Human-Verified | Human approves | PR Preview |
| Human-Verified | In-Production | Admin deploys (XS/S/M) | Production |
| Human-Verified | On-Staging | Admin deploys (L/XL) | Staging |
| On-Staging | Staging-Verified | Tester verifies | Staging |
| On-Staging | Tests-Failed | Staging tests fail | Staging |
| Staging-Verified | In-Production | Admin promotes | Production |

### Invalid Transitions (Blocked)

| From | To | Reason |
|------|----|--------|
| PR-Ready | In-Production | Must pass testing, PM validation, human verification |
| Tests-Failed | In-Production | Must fix and retest |
| Tests-Passed | On-Staging | Must have PM-Validated and Human-Verified first |
| Tests-Passed | In-Production | Must have PM-Validated and Human-Verified first |
| On-Staging | In-Production | L/XL must have Staging-Verified |
| (any) | Human-Verified | Only humans can set |
| (any) | PM-Validated | Only PM agent can set |

---

## 8. Quick Reference

### Agent Ownership by Label

| Labels Present | Owner | Environment |
|----------------|-------|-------------|
| In-Production | None (done) | Production (set by TPM) |
| Staging-Verified | Admin (promote to prod) | Staging |
| On-Staging | Tester (staging verification) | Staging |
| Human-Verified | Admin (deploy) | PR Preview |
| PM-Validated | Human (final approval) | PR Preview |
| Tests-Passed | PM (pre-human validation) | PR Preview |
| PR-Ready, Testing | Tester | PR Preview |
| Tests-Failed | Builder | localhost |
| (has spec, no PR) | Builder | localhost |
| (missing epic/size) | PM | - |

### Required Comment Tags

| Tag | Purpose |
|-----|---------|
| `@pm` | Notify PM agent (for validation) |
| `@builder` | Notify Builder agent |
| `@tester` | Notify Tester agent |
| `@admin` | Notify Admin agent |
| `@human` | Notify human reviewer |

---

## Related Documentation

- [sop.md](./sop.md) - Main workflow SOP
- [../MULTI_AGENT_WORKFLOW.md](../MULTI_AGENT_WORKFLOW.md) - Workflow overview
- [../EPIC_REGISTRY.md](../EPIC_REGISTRY.md) - Epic and CUJ definitions
