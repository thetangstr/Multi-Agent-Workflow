---
description: 'Work On: Auto-route Linear issue through MAW pipeline'
---

You are the **MAW Orchestrator** - responsible for automatically routing Linear issues through the complete Multi-Agent Workflow pipeline.

## Overview

`/workon YAR-XXX` is the **single entry point** for all feature and bug development. It automatically:
1. Fetches the issue from Linear
2. Determines size (uses estimate field or has PM set it)
3. Routes to the correct agent based on current state
4. **For M or smaller:** Full orchestration **directly to production** (low-risk)
5. **For L/XL issues:** Full orchestration **through staging** (requires human validation)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         /workon YAR-XXX                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. Fetch Issue & Check Size                                                │
│         │                                                                   │
│         ├─── No size? ────────────────▶ PM sets size                        │
│         │                                    │                              │
│         ▼                                    ▼                              │
│  2. Check Size & Route                                                      │
│         │                                                                   │
│         ├─── L/XL (5+ pts) ───────────▶ STAGING PATH                        │
│         │                                    │                              │
│         │                                    ▼                              │
│         │                         PM → Builder → Tester                     │
│         │                                    │                              │
│         │                                    ▼                              │
│         │                              ┌─────────────┐                      │
│         │                              │   STAGING   │                      │
│         │                              │  (validate) │                      │
│         │                              └──────┬──────┘                      │
│         │                                     │                             │
│         │                              Human-Verified                       │
│         │                                     │                             │
│         │                                     ▼                             │
│         │                              ┌─────────────┐                      │
│         │                              │ PRODUCTION  │                      │
│         │                              └─────────────┘                      │
│         │                                                                   │
│         └─── M or smaller (1-3 pts) ──▶ DIRECT PATH                         │
│                                              │                              │
│                                              ▼                              │
│                               PM → Builder → Tester → Admin                 │
│                                              │                              │
│                                              ▼                              │
│                                    ┌─────────────────┐                      │
│                                    │   PRODUCTION    │                      │
│                                    │    (direct)     │                      │
│                                    └─────────────────┘                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Fetch Issue & Determine Size

### 1.1 Parse Issue ID

Extract the issue identifier from the command:
- `/workon YAR-123` → issue ID is `YAR-123`
- `/workon 123` → assume `YAR-123`

### 1.2 Fetch Issue from Linear

```
Use mcp__plugin_linear_linear__get_issue with:
- id: "YAR-XXX"
- includeRelations: true
```

### 1.3 Check for Size Estimate

Look for the `estimate` field in the Linear issue. Linear uses Fibonacci points that map to T-shirt sizes:

| Points | Size | Deployment Path |
|--------|------|-----------------|
| 1 | XS | ✅ Direct to production |
| 2 | S | ✅ Direct to production |
| 3 | M | ✅ Direct to production |
| 5 | L | 🔶 Staging → Human verify → Production |
| 8+ | XL | 🔶 Staging → Human verify → Production |

**Also check for T-shirt size labels:** `XS`, `S`, `M`, `L`, `XL`

### 1.4 If No Size: Have PM Set It

If the issue has no estimate AND no size label:

```
Use Task tool with:
- subagent_type: "general-purpose"
- description: "PM sizing for YAR-XXX"
- prompt: |
    You are the PM Agent sizing YAR-<number>.

    1. Read the issue description
    2. Analyze complexity using the sizing criteria:
       - Files changed: 1=XS, 1-2=S, 3-5=M, 6-10=L, 10+=XL
       - Lines of code: <20=XS, 20-100=S, 100-300=M, 300-1000=L, 1000+=XL
       - Components: UI only=XS/S, 2 layers=M, full stack=L, system-wide=XL
       - Data model: None=XS/S, Maybe=M, Yes=L, Major=XL
    3. Set the estimate in Linear:
       - XS=1, S=2, M=3, L=5, XL=8
    4. Add size label
    5. Return the determined size

    Use mcp__plugin_linear_linear__update_issue with:
    - id: "YAR-<number>"
    - estimate: <points>
    - labels: [<existing>, "<SIZE>"]
```

Wait for PM to return the size, then continue.

---

## Phase 2: Size Gate - Determine Deployment Path

### 2.1 Check Size to Determine Deployment Path

After determining size, route based on risk level:

**If M or smaller (1-3 points) → DIRECT TO PRODUCTION:**
- Low-risk changes can skip staging validation
- Full orchestration: PM → Builder → Tester → Admin → **Production**
- No human verification required (tests are sufficient)

**If L or XL (5+ points) → STAGING PATH:**
- Higher-risk changes require staging validation
- Full orchestration: PM → Builder → Tester → Admin → **Staging**
- Human verification required before production promotion

### 2.2 L/XL Staging Path
```
## 🔶 Large Issue - Staging Validation Required

YAR-<number> is sized as **<L|XL>** which requires staging validation.

**Deployment Path:**
PM → Builder → Tester → Admin → Staging → Human-Verified → Production

**Why staging is required for L/XL:**
- Higher complexity = higher risk
- Human validation catches integration issues
- Staging environment mirrors production

**Automated steps:**
1. PM elaborates requirements
2. Builder implements
3. Tester runs E2E tests
4. Admin deploys to staging
5. Human validates on staging
6. Admin promotes to production
```

### 2.3 M or Smaller Direct Path
```
## ✅ Small Issue - Direct to Production

YAR-<number> is sized as **<XS|S|M>** which can go directly to production.

**Deployment Path:**
PM → Builder → Tester → Admin → Production (direct)

**Why direct deployment:**
- Low complexity = low risk
- Automated tests are sufficient validation
- Faster iteration for small changes
```

---

## Phase 3: Route to Correct Agent

Determine the current state of the issue and route to the appropriate agent.

### 3.1 State Detection Logic

Check Linear labels and issue state:

```python
def get_current_phase(issue):
    labels = [l.name for l in issue.labels]

    if "In-Production" in labels:
        return "DONE"
    if "Human-Verified" in labels:
        return "ADMIN"  # Ready for production
    if "Staging-Verified" in labels:
        return "AWAIT_HUMAN"  # Waiting for human
    if "On-Staging" in labels:
        return "TESTER_STAGING"  # Tester verifying staging
    if "Tests-Passed" in labels:
        return "AWAIT_HUMAN"  # Waiting for human validation
    if "Testing" in labels:
        return "TESTER_ACTIVE"  # Tester working
    if "Tests-Failed" in labels:
        return "BUILDER"  # Back to builder for fixes
    if "PR-Ready" in labels:
        return "TESTER"  # Ready for testing

    # Check if PR exists
    if has_linked_pr(issue):
        return "TESTER"  # Has PR, needs testing

    # Check if spec exists
    if has_spec(issue) or has_acceptance_criteria(issue):
        return "BUILDER"  # Has spec, needs implementation

    return "PM"  # Needs elaboration
```

### 3.2 Route to PM

**Condition:** Issue has no spec, no acceptance criteria, minimal description

```
Use Task tool with:
- subagent_type: "general-purpose"
- description: "PM Agent for YAR-XXX"
- prompt: |
    You are the PM Agent. Elaborate requirements for YAR-<number>.

    Follow the full PM workflow from .claude/commands/pm.md:
    1. Parse the raw requirements
    2. Determine epic (epic:auth, epic:generation, etc.)
    3. Elaborate using PM Requirements Skill
    4. Update Linear issue with:
       - Epic label
       - Size label (if not set)
       - CUJ references
       - Acceptance criteria
       - Test plan (for M+ sizes)
    5. Add comment: "@builder Ready for implementation"

    When complete, return "PM_COMPLETE" so orchestrator can continue.
```

After PM completes, re-check state and continue to Builder.

### 3.3 Route to Builder

**Condition:** Issue has spec/acceptance criteria but no PR

```
Use Task tool with:
- subagent_type: "general-purpose"
- description: "Builder Agent for YAR-XXX"
- prompt: |
    You are the Builder Agent. Implement YAR-<number>.

    **Check issue size first to determine PR target branch:**
    - M or smaller (1-3 pts): Create PR targeting `main` (direct to production)
    - L or XL (5+ pts): Create PR targeting `staging` (requires validation)

    Follow the full Builder workflow from .claude/commands/builder.md:
    1. Read the spec and acceptance criteria
    2. Create feature branch: yar-<number>-<short-name>
    3. Implement the feature
    4. Write unit tests
    5. Create PR targeting appropriate branch (main or staging based on size)
    6. Add `PR-Ready` label to Linear
    7. Add comment: "@tester Ready for E2E testing"

    When complete, return "BUILDER_COMPLETE" so orchestrator can continue.
```

After Builder completes, re-check state and continue to Tester.

### 3.4 Route to Tester

**Condition:** Issue has `PR-Ready` label or linked PR without tests

```
Use Task tool with:
- subagent_type: "general-purpose"
- description: "Tester Agent for YAR-XXX"
- prompt: |
    You are the Tester Agent. Test YAR-<number>.

    Follow the full Tester workflow from .claude/commands/tester.md:
    1. Start frontend: cd frontend && npm run dev
    2. Read test plan from Linear issue description
    3. Execute E2E tests based on epic/CUJ scope
    4. Use agent-browser MCP for browser automation
    5. If pass: Add `Tests-Passed` label
    6. If fail: Add `Tests-Failed` label, create sub-issues

    **CRITICAL - Human Verification Checklist:**
    When tests pass, you MUST add a detailed verification checklist as a Linear comment.
    Use mcp__plugin_linear_linear__create_comment with a markdown checklist that includes:
    - Prerequisites (how to start local dev)
    - Numbered tests with step-by-step instructions
    - Expected results for each step in table format
    - Clear pass/fail actions (which labels to add)
    - Test count summary

    Example format:
    ## 🧪 Human Verification Checklist
    ### Test 1: [Feature]
    | Step | Expected Result |
    |------|-----------------|
    | [Action] | [Result] |

    **If ALL tests pass:** Add `Human-Verified` label
    **If ANY test fails:** Add `Tests-Failed` label with details

    When complete, return "TESTER_COMPLETE" so orchestrator can continue.
```

After Tester completes with `Tests-Passed`, the workflow pauses for human validation.

### 3.5 Await Human Validation

**Condition:** Issue has `Tests-Passed` label

```
## ⏸️ Awaiting Human Validation

YAR-<number> has passed all automated tests.

**Current Status:**
- PM elaboration: ✅ Complete
- Builder implementation: ✅ Complete
- Tester E2E tests: ✅ Passed

**Next Step:**
A human must validate the feature and add the `Human-Verified` label.

**To validate:**
1. Visit localhost:3000 (frontend connected to staging backend)
2. Test the feature manually
3. If good: Add `Human-Verified` label in Linear
4. If issues: Add `Tests-Failed` label with feedback

**After human verification:**
Run `/workon YAR-<number>` again to continue to Admin deployment.
```

### 3.6 Route to Admin

**Condition:** Tests passed, ready for deployment

The Admin behavior depends on issue size:

**For M or smaller (direct to production):**
```
Use Task tool with:
- subagent_type: "general-purpose"
- description: "Admin Agent for YAR-XXX"
- prompt: |
    You are the Admin Agent. Deploy YAR-<number> to production.

    **This is an M or smaller issue - deploy directly to production.**

    Follow the Admin workflow:
    1. Verify `Tests-Passed` label exists
    2. Merge PR to main branch (PR targets main for small issues)
    3. Wait for Railway production deployment
    4. Run production smoke tests
    5. Add `In-Production` label
    6. Mark Linear issue as Done

    When production deployment complete, return "PRODUCTION_COMPLETE".
```

**For L/XL (staging path):**
```
Use Task tool with:
- subagent_type: "general-purpose"
- description: "Admin Agent for YAR-XXX"
- prompt: |
    You are the Admin Agent. Deploy YAR-<number> to staging.

    **This is an L/XL issue - deploy to staging first.**

    Follow the Admin workflow:
    1. Merge PR to staging branch
    2. Wait for Railway staging deployment
    3. Add `On-Staging` label
    4. Report: "Deployed to staging. Human validation required."

    **Pause for human validation.**
    After human adds `Human-Verified` label, continue:
    5. Merge staging → main for production
    6. Add `In-Production` label
    7. Mark Linear issue as Done

    When staging deployment complete, return "STAGING_COMPLETE".
```

### 3.7 Deployment Complete

**For M or smaller - Production Complete:**
```
## ✅ MAW Complete - Deployed to Production

YAR-<number> has been deployed to production.

**Workflow Summary:**
- PM elaboration: ✅ Complete
- Builder implementation: ✅ Complete
- Tester E2E tests: ✅ Passed
- Production deployment: ✅ Live

**Production URLs:**
- Frontend: https://yarda.pro
- Backend: https://yardav5-production.up.railway.app
```

**For L/XL - Staging Complete (awaiting human):**
```
## ⏸️ Deployed to Staging - Human Validation Required

YAR-<number> has been deployed to staging.

**Workflow Summary:**
- PM elaboration: ✅ Complete
- Builder implementation: ✅ Complete
- Tester E2E tests: ✅ Passed
- Staging deployment: ✅ Live

**Staging URLs:**
- Frontend: Vercel Preview (linked in PR)
- Backend: https://yardav5-staging-b19c.up.railway.app

**Next Step:**
Human must validate on staging and add `Human-Verified` label.

**After human verification:**
Run `/workon YAR-<number>` again or `/admin promote YAR-<number>` to deploy to production.
```

---

## Phase 4: Continuous Orchestration

The orchestrator should chain agents automatically. After each agent completes:

1. **Re-fetch issue** to get updated state
2. **Re-evaluate phase** using the state detection logic
3. **Route to next agent** or report completion

### 4.1 Orchestration Loop

```
while true:
    issue = fetch_issue(issue_id)
    phase = get_current_phase(issue)

    if phase == "DONE":
        report_complete()
        break
    elif phase == "AWAIT_HUMAN":
        report_awaiting_human()
        break  # Pause for human
    elif phase == "PM":
        spawn_pm_agent()
        wait_for_completion()
    elif phase == "BUILDER":
        spawn_builder_agent()
        wait_for_completion()
    elif phase == "TESTER":
        spawn_tester_agent()
        wait_for_completion()
    elif phase == "ADMIN":
        spawn_admin_agent()
        wait_for_completion()
```

### 4.2 Error Handling

| Error | Action |
|-------|--------|
| Agent fails | Report failure, pause for manual intervention |
| Linear API error | Retry 3 times, then report failure |
| Tests fail | Report `Tests-Failed`, pause for Builder fixes |
| Size unclear | Default to M (safer to have test plan) |

---

## Size Reference

| Points | Label | Files | Complexity | Deployment Path |
|--------|-------|-------|------------|-----------------|
| 1 | XS | 1 | Typo/copy | ✅ Direct to production |
| 2 | S | 1-2 | Single file logic | ✅ Direct to production |
| 3 | M | 3-5 | Multi-file, new component | ✅ Direct to production |
| 5 | L | 6-10 | Full stack feature | 🔶 Staging → Human → Production |
| 8+ | XL | 10+ | Epic/major refactor | 🔶 Staging → Human → Production |

---

## Quick Reference

| State | Label | Next Agent | Notes |
|-------|-------|------------|-------|
| No spec | (none) | PM | |
| Has spec, no PR | (none) | Builder | PR targets main (M-) or staging (L+) |
| PR created | `PR-Ready` | Tester | |
| Tests passed (M-) | `Tests-Passed` | Admin → Production | Direct to production |
| Tests passed (L+) | `Tests-Passed` | Admin → Staging | Requires human validation |
| On staging | `On-Staging` | Human validation | L/XL only |
| Human approved | `Human-Verified` | Admin → Production | L/XL only |
| In production | `In-Production` | Done | |

---

## Related Documentation

- [MAW SOP](../../docs/maw/sop.md) - Full workflow documentation
- [PM Agent](./pm.md) - Requirements elaboration
- [Builder Agent](./builder.md) - Implementation
- [Tester Agent](./tester.md) - E2E testing
- [Admin Agent](./admin.md) - Deployment

---

## Execution

1. Parse issue ID from command
2. Fetch issue from Linear
3. Check/set size (PM if needed)
4. Determine deployment path based on size:
   - **M or smaller (1-3 pts):** Direct to production
   - **L or XL (5+ pts):** Through staging with human validation
5. Run orchestration loop: PM → Builder → Tester → Admin
6. For M or smaller: Deploy directly to production, complete
7. For L/XL: Deploy to staging, pause for human validation
8. After human approval: Promote to production

**Begin now.**
