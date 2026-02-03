# Test Plan: {FEATURE_NAME}

**Linear Issue:** {ISSUE_ID}
**Branch:** {BRANCH_NAME}
**Test Environment:** `http://localhost:3000`
**Spec Document:** `specs/{NUMBER}-{FEATURE}/spec.md`

> 📝 **For Tester:** Run `cd frontend && npm run dev` before testing.

---

## Feature Scope Definition

> ⚠️ **IMPORTANT:** Only test what's listed in "In Scope". Do NOT report issues for "Out of Scope" items.

### What This Feature Does
{1-2 sentence description of the feature's purpose}

### In Scope (MUST Test)
These are the specific changes introduced by this PR:

| Area | What Changed | Pages Affected |
|------|--------------|----------------|
| {UI/API/DB} | {Specific change} | `/page1`, `/page2` |
| {UI/API/DB} | {Specific change} | `/page3` |

**Components Modified:**
- `frontend/src/components/{Component1}.tsx`
- `frontend/src/components/{Component2}.tsx`
- `backend/src/api/endpoints/{endpoint}.py`

**New Functionality:**
- [ ] {New feature 1}
- [ ] {New feature 2}

**Modified Behavior:**
- [ ] {Changed behavior 1} - was: {old}, now: {new}

### Out of Scope (Do NOT Test)
These areas are NOT part of this PR. If you find issues here, note them but do NOT fail the test:

- ❌ {Unrelated feature 1} - Not modified in this PR
- ❌ {Unrelated feature 2} - Separate issue YAR-XX
- ❌ {Pre-existing bug} - Known issue, tracked in YAR-XX
- ❌ Performance optimization - Not a goal of this PR
- ❌ {Page/feature} - No changes made

### Dependencies
Features this PR depends on (should already work):
- {Feature A} - Required for {reason}
- {Feature B} - Required for {reason}

### Regression Risk
Areas that COULD break due to these changes (quick sanity check):
| Risk Area | Why | Quick Check |
|-----------|-----|-------------|
| {Area 1} | Shares {component/API} | Verify {action} still works |
| {Area 2} | Database migration | Verify old data displays |

---

## Test Configuration

### Environment
| Environment | Frontend URL | Backend URL |
|-------------|--------------|-------------|
| **Local Testing** | `http://localhost:3000` | `https://yardav5-staging-b19c.up.railway.app` |
| Production | `https://yarda.pro` | `https://yardav5-production.up.railway.app` |

> **Note:** All testing happens on localhost:3000. Production URLs listed for reference only.

### Test Credentials
| Role | Email | Password | When to Use |
|------|-------|----------|-------------|
| Standard User | `test+e2e@yarda.app` | `yarda123` | Default for most tests |
| Pro User | `test+pro@yarda.app` | `yarda123` | Pro Mode features only |
| Admin | `test+admin@yarda.app` | `yarda123` | Admin features only |

### Prerequisites
Before starting tests, verify:
- [ ] Frontend running at localhost:3000 (`cd frontend && npm run dev`)
- [ ] User is logged in with correct role
- [ ] {Feature-specific prerequisite}
- [ ] {Feature-specific prerequisite}

---

## Critical User Journeys

> 📋 **CUJs are ordered by priority.** CUJ 1 is the primary happy path. If CUJ 1 fails, stop testing and report immediately.

### CUJ 1: {Primary Happy Path Name}

**Purpose:** {What user goal does this test?}

**User Story:** As a {role}, I want to {action}, so that {benefit}.

**Preconditions:**
- User is logged in as {role}
- User is on `/{starting-page}`
- {Other precondition}

**Steps:**
| Step | Action | Expected Result | Screenshot |
|------|--------|-----------------|------------|
| 1 | Navigate to `/{page}` | Page loads, no console errors | `cuj1-01-page-load.png` |
| 2 | Click "{button/element}" | {Expected behavior} | |
| 3 | Enter "{value}" in {field} | Input accepted, no validation error | |
| 4 | Click "{submit}" | {Success state} | `cuj1-04-success.png` |
| 5 | Refresh page | Data persists | |

**Verification Checklist:**
- [ ] Success message: "{exact expected message}"
- [ ] URL changed to: `/{expected-path}`
- [ ] Console: No errors (warnings OK)
- [ ] Data persisted (verify after refresh)
- [ ] {Feature-specific verification}

**Pass Criteria:** All checkboxes must be checked.

---

### CUJ 2: {Secondary Path or Variation}

**Purpose:** {What alternative flow does this test?}

**Preconditions:**
- {Precondition specific to this variation}

**Steps:**
| Step | Action | Expected Result | Screenshot |
|------|--------|-----------------|------------|
| 1 | {Action} | {Expected} | |
| 2 | {Action} | {Expected} | |

**Verification Checklist:**
- [ ] {Verification 1}
- [ ] {Verification 2}

**Pass Criteria:** All checkboxes must be checked.

---

### CUJ 3: {Error Handling / Edge Case}

**Purpose:** {What error scenario does this test?}

**Preconditions:**
- {Setup to trigger error state}

**Steps:**
| Step | Action | Expected Result | Screenshot |
|------|--------|-----------------|------------|
| 1 | {Action that triggers error} | Error handled gracefully | `cuj3-01-error.png` |
| 2 | {Recovery action} | User can continue | |

**Verification Checklist:**
- [ ] Error message is user-friendly (not technical)
- [ ] User is not stuck (can retry or navigate away)
- [ ] No console errors (error was caught)

**Pass Criteria:** Error is handled gracefully, user can recover.

---

## Edge Cases

> Only test edge cases if all CUJs pass.

| ID | Scenario | Steps | Expected | Priority |
|----|----------|-------|----------|----------|
| E1 | {Edge case name} | {Brief steps} | {Expected behavior} | High |
| E2 | {Edge case name} | {Brief steps} | {Expected behavior} | Medium |
| E3 | {Edge case name} | {Brief steps} | {Expected behavior} | Low |

---

## Visual & Responsive Testing

> Only test if all CUJs pass.

### Viewport Testing
| Viewport | Width | Checklist |
|----------|-------|-----------|
| Desktop | 1920px | [ ] Layout correct [ ] No overflow [ ] All elements visible |
| Laptop | 1366px | [ ] Layout adapts [ ] No horizontal scroll |
| Tablet | 768px | [ ] Responsive layout [ ] Touch targets adequate |
| Mobile | 375px | [ ] Mobile layout [ ] No horizontal scroll [ ] Text readable |

### Visual States
- [ ] Loading state displays correctly
- [ ] Empty state displays correctly (if applicable)
- [ ] Error state displays correctly
- [ ] Success state displays correctly

---

## Accessibility Checklist

> Only test if all CUJs pass.

- [ ] **Keyboard:** Can complete CUJ 1 using only keyboard (Tab, Enter, Escape)
- [ ] **Focus:** Focus indicators visible on all interactive elements
- [ ] **Labels:** Form inputs have associated labels (click label focuses input)
- [ ] **Alt text:** Images have meaningful alt text
- [ ] **Contrast:** Text is readable (no light gray on white, etc.)

---

## Console Health Check

After completing all CUJs, check browser console for:

| Check | Status | Notes |
|-------|--------|-------|
| React errors | [ ] None | |
| API 4xx errors | [ ] None | |
| API 5xx errors | [ ] None | |
| CORS errors | [ ] None | |
| Unhandled rejections | [ ] None | |

**Acceptable warnings (ignore these):**
- DevTools source map warnings
- React StrictMode double-render warnings
- Third-party script warnings

---

## Regression Quick Check

> Only if regression risks were identified in Scope section.

| Risk Area | Quick Check | Status |
|-----------|-------------|--------|
| {Area from scope} | {What to verify} | [ ] OK |
| {Area from scope} | {What to verify} | [ ] OK |

---

## Test Results Template

### ✅ Pass Report
```markdown
## ✅ All Tests Passed - {ISSUE_ID}

**Environment:** localhost:3000
**Tested:** {DATE}
**Tester:** Tester Agent

### Scope Tested
- {In-scope item 1} ✅
- {In-scope item 2} ✅

### Results
| Test | Status | Notes |
|------|--------|-------|
| CUJ 1: {name} | ✅ Pass | |
| CUJ 2: {name} | ✅ Pass | |
| CUJ 3: {name} | ✅ Pass | |
| Edge Cases | ✅ Pass | {X}/{Y} tested |
| Visual/Responsive | ✅ Pass | All viewports OK |
| Accessibility | ✅ Pass | Keyboard nav works |
| Console Health | ✅ Clean | No errors |
| Regression Check | ✅ Pass | No regressions found |

### Recordings
- [CUJ 1 Recording](link)
- [CUJ 2 Recording](link)

### Notes
{Any observations, minor issues noted but not blocking}

---
**Recommendation:** ✅ Ready for staging deployment.
@admin Please proceed with merge.
```

### ❌ Fail Report
```markdown
## ❌ Tests Failed - {ISSUE_ID}

**Environment:** localhost:3000
**Tested:** {DATE}
**Tester:** Tester Agent

### Scope Tested
- {In-scope item 1} ✅
- {In-scope item 2} ❌ FAILED

### Results Summary
| Test | Status | Blocking? |
|------|--------|-----------|
| CUJ 1: {name} | ✅ Pass | |
| CUJ 2: {name} | ❌ Fail | YES |
| Visual | ❌ Fail | NO |

### Failure Details

#### Failure 1: CUJ 2 Step 3 (BLOCKING)
- **Step:** Click "Export" button
- **Expected:** Modal opens with format options
- **Actual:** Button unresponsive on mobile viewport
- **Severity:** 🔴 Blocking - Core feature broken
- **Recording:** [CUJ 2 Recording](link)
- **Console Error:**
  ```
  TypeError: Cannot read property 'map' of undefined
    at ExportModal.tsx:45
  ```

#### Failure 2: Visual - Mobile Header (NON-BLOCKING)
- **Viewport:** 375px
- **Expected:** Header fits within viewport
- **Actual:** Title text overflows right edge by ~20px
- **Severity:** 🟡 Non-blocking - Visual polish issue
- **Screenshot:** [attached]

### Out of Scope Issues Noticed
> These are NOT blocking this PR but should be tracked:
- {Unrelated issue noticed} → Recommend creating YAR-XX

---
**Recommendation:** ❌ Fixes required before merge.
@builder Please address blocking issues above.
```

---

## Notes for Tester Agent

### Execution Order
1. **Read entire test plan first** - Understand scope before testing
2. **Verify scope** - Only test In Scope items
3. **Execute CUJs in order** - Stop if CUJ 1 fails
4. **One browser_subagent call per CUJ** - Keep recordings focused
5. **Check console after each CUJ** - Errors may appear async
6. **Complete visual/a11y only if CUJs pass**
7. **Do regression quick check last**

### Severity Guide
| Severity | Meaning | Action |
|----------|---------|--------|
| 🔴 Blocking | Core feature broken | FAIL test, stop testing |
| 🟡 Non-blocking | Visual/minor issue | Note in report, continue testing |
| 🟢 Observation | Not a bug, just noting | Note in report, does not affect pass/fail |

### When to STOP Testing
- CUJ 1 fails completely (page won't load, crash, etc.)
- 3+ blocking issues found (diminishing returns)
- Environment is broken (backend down, auth broken)

### When to PASS Despite Issues
- Only non-blocking visual issues found
- Pre-existing issues (documented in Out of Scope)
- Issues in unrelated features
