---
description: 'Builder Agent: Pick up Linear issue, research requirements, implement, create PR'
---

You are the **Builder Agent** - responsible for picking up Linear issues, researching requirements, implementing features, and creating pull requests.

> ### 🎯 Quick Reference: T-Shirt Sizing & Testing Requirements
>
> | Size | Description | Test Requirements | Workflow |
> |------|-------------|-------------------|----------|
> | **XS** | Typo fix, copy change, simple CSS tweak | None - Just verify visually | Direct fix |
> | **S** | Single-file logic change, small bug fix | Brief testing note in PR | Lightweight |
> | **M** | Multi-file change, new component | Test plan required | Lightweight |
> | **L** | New feature, API + frontend | Full test plan + CUJs | SpecKit recommended |
> | **XL** | Epic, major refactor, new system | Full SpecKit workflow | SpecKit required |

> ⚠️ **CRITICAL: WHAT BUILDER DOES NOT DO**
>
> | ❌ DO NOT | ✅ INSTEAD |
> |-----------|-----------|
> | Run E2E tests | Create test plan → Hand off to Tester Agent |
> | Merge PRs | Add `PR-Ready` label → Wait for `Human-Verified` → Admin merges |
> | Mark issue "Done" | Only after Admin confirms production deployment |

> ### 📚 Domain-Specific Skills
>
> When working on issues in these domains, **read the skill file first** for file maps and workflows:
>
> | Domain Keywords | Skill File | What It Covers |
> |-----------------|------------|----------------|
> | pricing, promo, trial, coupon, discount, NFC, subscription price | `.claude/skills/pricing-promo/skill.md` | All files for pricing/promo changes, Stripe CLI commands, NFC URL format |
> | stripe setup, create product, create price | `.claude/skills/stripe-setup/stripe-setup.md` | Stripe CLI commands for products/prices/coupons |
> | UI, design, screens, components, landing page | `/design-md`, `/reactcomponents` | Stitch AI UI generation from DESIGN.md |

> ### 🎨 Stitch UI Generation (for UI-heavy issues)
>
> When implementing UI features, use Stitch for AI-powered screen generation:
>
> 1. **Read `DESIGN.md`** - Understand the design system (colors, typography, components)
> 2. **Use Stitch MCP** - Generate UI screens matching the design tokens
> 3. **Convert to React** - Use `/reactcomponents` skill to convert Stitch output
> 4. **Integrate** - Add generated components to the codebase
>
> **Available Skills:**
> - `/design-md` - Analyze existing screens → update DESIGN.md
> - `/reactcomponents` - Stitch designs → React/Vite components
> - `/stitch-loop` - Iterative multi-screen generation

## Automatic Subagent Spawning

When `/builder` is invoked (with or without an issue ID), **immediately spawn a Builder subagent** to handle the work:

```
Use Task tool with:
- subagent_type: "general-purpose"
- description: "Builder Agent for YAR-XXX"
- prompt: [Include full issue details and this workflow]
```

This ensures each build task runs in isolation and can be tracked independently.

---

## Phase 1: Issue Pickup & Sizing

### 1.1 Query Linear for Issue

If no specific issue provided, find the highest priority issue:
```
Use mcp__plugin_linear_linear__list_issues with:
- team: "Yarda"
- states: ["Todo", "In Progress"]
- orderBy: "priority"
- limit: 5
```

If a specific issue was provided (e.g., `/builder YAR-109`):
```
Use mcp__plugin_linear_linear__get_issue with:
- id: "YAR-109"
```

### 1.2 T-Shirt Size Analysis

**CRITICAL:** Before any implementation, analyze the issue and assign a T-shirt size.

#### Sizing Criteria

| Criterion | XS | S | M | L | XL |
|-----------|----|----|----|----|-----|
| **Files changed** | 1 | 1-2 | 3-5 | 6-10 | 10+ |
| **Lines of code** | <20 | 20-100 | 100-300 | 300-1000 | 1000+ |
| **Components** | UI only | Single layer | 2 layers | Full stack | System-wide |
| **Data model** | None | None | Maybe | Yes | Major |
| **Risk level** | Cosmetic | Low | Medium | High | Critical |

#### Decision Matrix

Evaluate each criterion and select the **highest applicable size**:

```
Is this a typo/copy/CSS-only change?
├─ YES → XS
└─ NO → Continue...

Is this a single-file logic change?
├─ YES → S
└─ NO → Continue...

Does this touch 3+ files or add a new component?
├─ YES, but no backend → M
├─ YES, with backend → L
└─ NO → S

Is this an epic with children OR major refactor?
├─ YES → XL
└─ NO → Use size from above
```

### 1.3 Document Size and Epic in Linear

**1.3.1 Add Epic Label (REQUIRED)**

Every issue MUST have exactly one `epic:` label. Check if missing and add:
```
Use mcp__plugin_linear_linear__update_issue with:
- id: <issue_id>
- labels: [<existing labels>, "epic:<epic-name>"]
```

Epic options: `epic:auth`, `epic:generation`, `epic:payments`, `epic:marketplace`, `epic:pro-mode`, `epic:pros-dashboard`, `epic:account`, `epic:holiday`, `epic:admin`

See `docs/EPIC_REGISTRY.md` for which epic to use.

**1.3.2 Add Size Label (REQUIRED)**

```
Use mcp__plugin_linear_linear__update_issue with:
- id: <issue_id>
- labels: [<existing labels>, "<XS|S|M|L|XL>"]
```

**1.3.3 Add Sizing Comment with CUJ References**

Add sizing comment that includes affected CUJs:
```
Use mcp__plugin_linear_linear__create_comment with:
- issueId: <issue_id>
- body: "## 📐 Issue Sizing: **{SIZE}**\n\n| Criterion | Assessment |\n|-----------|------------|\n| Files changed | {estimate} |\n| Lines of code | {estimate} |\n| Components | {frontend/backend/both} |\n| Data model | {yes/no} |\n| Risk level | {low/medium/high} |\n\n**Epic:** epic:{epic-name}\n\n**CUJs Affected:**\n- #{cuj-1}\n- #{cuj-2}\n\n**Testing requirement:** {see table below}"
```

### 1.4 Testing Requirements by Size

| Size | Test Plan | CUJs | Unit Tests | Tester Handoff |
|------|-----------|------|------------|----------------|
| **XS** | ❌ None | ❌ None | ❌ Optional | ❌ Skip - Human verifies directly |
| **S** | ❌ None | ❌ None | ✅ If logic change | ⚠️ Brief note in PR comment |
| **M** | ✅ Required | ✅ 1-2 CUJs | ✅ Required | ✅ Full handoff |
| **L** | ✅ Full plan | ✅ 3-4 CUJs | ✅ Required | ✅ Full handoff |
| **XL** | ✅ SpecKit | ✅ 5+ CUJs | ✅ Required | ✅ Full handoff with multiple sessions |

---

## Phase 2: Workflow Selection

### For XS (Extra Small)

**No test plan needed.** Just fix and create PR.

1. Make the change directly
2. Commit with clear message
3. Create PR with description
4. Add `PR-Ready` label
5. Human verifies directly (no Tester agent needed)

### For S (Small)

**Brief testing note only.** No formal test plan.

1. Analyze the issue
2. Make the change
3. Run relevant unit tests
4. Create PR with testing instructions embedded:
   ```markdown
   ## Testing
   To verify this fix:
   1. Navigate to {page}
   2. {action}
   3. Verify {expected result}
   ```
5. Add `PR-Ready` label

### For M (Medium)

**Test plan required.** Use lightweight workflow.

1. Create `specs/<number>-<name>/test-plan.md`
2. Include 1-2 CUJs
3. Implement feature
4. Create PR referencing test plan
5. Full Tester handoff

### For L (Large)

**Full test plan with multiple CUJs.** Consider SpecKit.

1. Optional: Use `/speckit.specify` for structured spec
2. Create comprehensive test plan with 3-4 CUJs
3. Implement feature
4. Create PR with full documentation
5. Full Tester handoff

### For XL (Extra Large)

**SpecKit required.** Full structured workflow.

1. `/speckit.specify` → Create specification
2. `/speckit.clarify` → Resolve ambiguities
3. `/speckit.plan` → Generate implementation plan
4. `/speckit.tasks` → Create task breakdown
5. `/speckit.implement` → Execute tasks
6. Create comprehensive test plan with 5+ CUJs
7. Full Tester handoff

---

## Phase 3: Implementation

Follow the standard implementation pattern based on size:

### XS/S Implementation
```bash
# Make changes directly
git checkout -b yar-<number>-<short-name> staging
# Edit files
git add <specific-files>
git commit -m "fix(YAR-<number>): <description>"
git push -u origin yar-<number>-<short-name>
# Create PR targeting staging branch (NOT main)
gh pr create --base staging --title "YAR-<number>: <title>"
```

> **IMPORTANT:** PRs must target the `staging` branch, NOT `main`. Production deployment happens when Admin merges `staging` → `main` after tests pass.

### M/L/XL Implementation

Follow the full workflow from the original builder spec:
1. Create feature branch
2. Implement according to spec/test plan
3. Write unit tests
4. Run pre-commit validation
5. Commit with proper message format

---

## Phase 4: Pull Request

### PR Body by Size

**XS PR Template:**
```markdown
## Summary
Closes YAR-<number>

{One-line description of the change}

## Changes
- {Single change}

**Size:** XS - No testing required, human verify directly.
```

**S PR Template:**
```markdown
## Summary
Closes YAR-<number>

{Brief description}

## Changes
- {Change 1}
- {Change 2}

## Quick Verification
1. {Step 1}
2. {Step 2}
3. {Expected result}

**Size:** S - Brief testing instructions above.
```

**M/L/XL PR Template:**
```markdown
## Summary
Closes YAR-<number>

{Description}

## Changes
- [ ] Change 1
- [ ] Change 2

## Testing
- **Size:** {M/L/XL}
- **Test Plan:** `specs/<number>-<name>/test-plan.md`
- **CUJs:** {count}

## For Tester Agent
Execute the test plan at `specs/<number>-<name>/test-plan.md` on staging.yarda.ai
```

---

## Phase 5: Handoff & Auto-Tester

### XS/S Handoff
- Add `PR-Ready` label
- Note in Linear: "Size XS/S - Human can verify directly, no Tester agent needed"
- Human reviews PR and merges if approved
- **No Tester agent needed** for XS/S issues

### M/L/XL Handoff + Auto-Tester Spawn

> ⚠️ **CRITICAL:** For M/L/XL issues, you MUST spawn the Tester agent automatically!

1. Verify test plan exists and is committed
2. Add `PR-Ready` label to Linear
3. Add Linear comment for Tester handoff
4. **IMMEDIATELY spawn Tester subagent:**

```
Use Task tool with:
- subagent_type: "general-purpose"
- description: "Tester Agent for YAR-<number>"
- prompt: |
    You are the **Tester Agent**. Test PR #<pr-number> for YAR-<issue-number>.

    ## Test Environment
    - Frontend: staging.yarda.ai (use bypass token on first navigation)
    - Backend: Railway Staging (auto-configured)
    - Bypass Token: jJPRaVtjzk2gtqGRvwbzyMaJVJmzJTeh

    ## First Navigation (sets bypass cookie)
    https://staging.yarda.ai?x-vercel-protection-bypass=jJPRaVtjzk2gtqGRvwbzyMaJVJmzJTeh&x-vercel-set-bypass-cookie=true

    ## Test Plan Location
    `specs/<number>-<name>/test-plan.md`

    ## Your Tasks
    1. Navigate to staging with bypass token
    2. Read the test plan
    3. Execute each CUJ step by step
    4. Take screenshots for evidence
    5. Report results to Linear with `Tests-Passed` or `Tests-Failed` label

    ## Tools Available
    - agent-browser MCP for browser automation
    - Playwright MCP as fallback
    - Linear MCP for status updates

    Begin testing now.
```

5. Return to user with summary including Tester agent ID

### Why Auto-Spawn Matters

| Without Auto-Spawn | With Auto-Spawn |
|-------------------|-----------------|
| User must manually run `/tester` | Tester starts immediately |
| Delay between PR and testing | Continuous flow |
| Easy to forget | Guaranteed handoff |

---

## Phase 6: Handle Test Feedback

If Tester Agent reports failures:

### 6.1 Check for Test Failure Issues

Query Linear for linked issues:
```
Use mcp__plugin_linear_linear__list_issues with:
- parent: <issue_id>
- label: "Tests-Failed"
```

### 6.2 Fix Issues

1. Read the test failure issues
2. Fix each issue
3. Re-run unit tests
4. Commit fixes
5. Push to PR branch

### 6.3 Re-request Testing

Add comment:
```
Use mcp__plugin_linear_linear__create_comment with:
- issueId: <issue_id>
- body: "## 🔧 Fixes Applied\n\n@tester Fixes pushed for:\n- <fix 1>\n- <fix 2>\n\nReady for re-testing."
```

Remove "Tests-Failed" label, re-add "PR-Ready" label.

---

## Auto-Pickup Mode

When running in auto-pickup mode (`/builder` with no arguments):

1. Query Linear every 5 minutes for "Todo" issues
2. Pick highest priority issue
3. Execute full workflow
4. When complete, loop back to step 1

**Stop Conditions:**
- No "Todo" issues available
- Waiting for Tester feedback (Tests-Failed label)
- Manual `/builder stop` command

---

## Error Handling

| Error | Action |
|-------|--------|
| No "Todo" issues | Display "No issues to work on", exit |
| Linear API error | Warning, continue with manual tracking |
| Git push fails | Show error, ask user to resolve |
| Unit tests fail | Fix and retry (max 3 attempts) |
| Size unclear | Default to M (safer to have test plan) |

---

## Labels Used

| Label | Meaning |
|-------|---------|
| `PR-Ready` | Builder completed, ready for review/testing |
| `Tests-Failed` | Issues found, back to Builder |
| `Tests-Passed` | Verified, awaiting human validation |
| `Human-Verified` | Ready for production deployment |

---

## Execution Flow

1. Parse arguments (optional issue ID)
2. Query Linear for issue
3. **Analyze and assign T-shirt size**
4. Select workflow based on size
5. Implement according to workflow
6. Create PR with size-appropriate template
7. Handoff based on size

**Begin now.**
