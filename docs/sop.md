# Multi-Agent Workflow (MAW) - Standard Operating Procedure

**Version:** 2.1
**Last Updated:** 2026-02-03
**Owner:** Engineering Team

---

## Mandatory MAW Policy

> **ALL feature and bug development MUST use the MAW workflow.**
>
> **Exceptions:**
> - Production hotfixes (critical bugs requiring immediate deployment)
> - Infrastructure/DevOps changes (CI/CD, environment config)
>
> **No development should happen outside MAW.** This ensures:
> - Consistent quality gates (PM → Builder → Tester → Admin)
> - Proper test coverage for all changes
> - Audit trail via Linear labels
> - Predictable deployment pipeline

---

## Quick Start: `/workon YAR-XXX`

The **recommended entry point** for all development:

```bash
/workon YAR-123   # Auto-routes issue through MAW pipeline
```

**What `/workon` does:**
1. Fetches issue from Linear
2. Checks size (estimate field, or has PM set it)
3. **M or smaller** → Full autonomous orchestration **directly to production**
4. **L or XL** → Full orchestration **through staging** for validation

**Size-Based Deployment Policy:**
| Size | Points | Pipeline | Deployment Target |
|------|--------|----------|-------------------|
| XS/S/M | 1-3 | Full auto | **Direct to production** |
| L/XL | 5-8+ | Full auto | **Staging → Human verify → Production** |

**Rationale:** Small changes (M or less) are low-risk and can skip staging validation. Large changes (L or bigger) require staging deployment and human verification before production.

See `.claude/commands/workon.md` for full orchestration logic.

---

## Overview

The Multi-Agent Workflow (MAW) is Yarda's CI/CD system using four specialized AI agents that coordinate via Linear labels. Each agent runs in its own Claude Code session.

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│                            MULTI-AGENT WORKFLOW                                     │
├────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                    │
│  Raw Requirement                                                                   │
│       │                                                                            │
│       ▼                                                                            │
│  ┌─────────────┐  Issue Ready  ┌─────────────┐  PR-Ready  ┌─────────────┐         │
│  │     PM      │ ─────────────▶│   BUILDER   │ ─────────▶│   TESTER    │         │
│  │   Agent     │               │   Agent     │            │   Agent     │         │
│  │             │               │             │            │             │         │
│  │ • Elaborate │               │ • Research  │ ◀────────  │ • E2E tests │         │
│  │ • Size      │               │ • Implement │ Tests-     │ • Reports   │         │
│  │ • Epic/CUJ  │               │ • Create PR │ Failed     │ • Validate  │         │
│  │ • Test plan │               └─────────────┘            └─────────────┘         │
│  └─────────────┘                                                 │                │
│                                                                  │ Tests-Passed   │
│                                                                  ▼                │
│                                                         ┌─────────────┐           │
│                                                         │   ADMIN     │           │
│                                                         │   Agent     │           │
│                                                         │             │           │
│                                                         │ • Deploy    │           │
│                                                         │ • Merge     │           │
│                                                         └─────────────┘           │
│                                                                  │                │
│                                                    ┌─────────────┴─────────────┐  │
│                                                    │                           │  │
│                                           (XS/S/M) ▼                  (L/XL)   ▼  │
│                                         ┌───────────────┐        ┌──────────────┐│
│                                         │  PRODUCTION   │        │   STAGING    ││
│                                         │   (direct)    │        │  (validate)  ││
│                                         └───────────────┘        └──────┬───────┘│
│                                                                         │        │
│                                                                         ▼        │
│                                                                ┌────────────────┐│
│                                                                │HUMAN VALIDATION││
│                                                                │(Human-Verified)││
│                                                                └───────┬────────┘│
│                                                                        │         │
│                                                                        ▼         │
│                                                                ┌───────────────┐ │
│                                                                │  PRODUCTION   │ │
│                                                                │(In-Production)│ │
│                                                                └───────────────┘ │
│                                                                                   │
└───────────────────────────────────────────────────────────────────────────────────┘
```

---

## Agents

### 1. Builder Agent (`/builder`)

**Command:** `.claude/commands/builder.md`

**Responsibilities:**
- Pick up Linear issues from "Todo" state
- Analyze and assign T-shirt size (XS/S/M/L/XL)
- Add epic label and CUJ references
- Implement feature on feature branch
- Write unit tests (pytest for backend)
- Create PR targeting `staging` branch
- Auto-spawn Tester for M/L/XL issues

**Commands:**
```bash
/builder         # Auto-pickup highest priority Todo issue
/builder YAR-5   # Work on specific issue
```

**Outputs:**
- Feature branch with implementation
- `specs/<number>-<name>/spec.md` (for M+ sizes)
- Unit tests
- PR with test plan
- Linear issue with `PR-Ready` label

---

### 2. Tester Agent (`/tester`)

**Command:** `.claude/commands/tester.md`

**Responsibilities:**
- Pick up issues with `PR-Ready` label
- Read test plan from Linear issue description
- Run scoped E2E tests (playwright)
- Use agent-browser MCP (preferred) or Playwright MCP
- Report results with screenshots
- Verify staging deployments

**Commands:**
```bash
/tester              # Auto-pickup oldest PR-Ready issue
/tester YAR-5        # Test specific issue
/tester staging YAR-5  # Test staging deployment
```

**Test Scope by Size:**
| Size | Test Command |
|------|--------------|
| XS | `npm run test:smoke` |
| S | `npx playwright test --grep "#<cuj>"` |
| M | `npx playwright test --grep "@<epic>"` |
| L/XL | `npm run test:full` |

**Outputs:**
- Test report with screenshots
- Sub-issues for any failures
- `Tests-Passed` or `Tests-Failed` label
- `Staging-Verified` label (after staging tests)
- **Human Verification Checklist** (Linear comment with step-by-step instructions)

---

### 3. Admin Agent (`/admin`)

**Command:** `.claude/commands/admin.md`

**Responsibilities:**
- Review PRs with `Human-Verified` label
- Merge PR to staging branch
- Monitor staging deployment
- Spawn Tester for staging verification
- Merge staging → main for production
- Run production smoke tests
- Mark issues as Done

**Commands:**
```bash
/admin                  # Review all ready PRs
/admin review           # Review PRs without deploying
/admin stage YAR-5      # Deploy specific issue to staging
/admin promote YAR-5    # Promote to production
/admin status           # Show deployment status
/admin health           # Check service health
```

**Outputs:**
- Staging deployments
- Production deployments (after human approval)
- `In-Production` label
- Linear issue marked "Done"

---

### 4. PM Agent (`/pm`)

**Command:** `.claude/commands/pm.md`
**Skill:** `.claude/skills/pm-requirements/skill.md`

**Responsibilities:**
- Elaborate raw requirements into comprehensive specs
- Create/update Linear issues with:
  - Epic label (`epic:<name>`)
  - Size label (XS/S/M/L/XL)
  - CUJ references (`#cuj-name`)
  - Test plan (for M+ sizes)
- Maintain `docs/EPIC_REGISTRY.md`
- Update `docs/MANUAL_TESTING_GUIDE.md`

**Commands:**
```bash
/pm                    # Interactive requirements session
/pm-requirements <desc> # Elaborate specific feature
```

---

## Linear Label State Machine

```
┌──────────┐   ┌──────────┐   ┌─────────────┐   ┌──────────────┐
│ PR-Ready │──▶│ Testing  │──▶│Tests-Passed │──▶│ On-Staging   │
└──────────┘   └──────────┘   └─────────────┘   └──────────────┘
     │              │                                  │
     │              ▼                                  ▼
     │         ┌─────────────┐              ┌─────────────────┐
     │         │Tests-Failed │              │Staging-Verified │
     │         └─────────────┘              └─────────────────┘
     │              │                                  │
     └──────────────┘                                  ▼
           (back to Builder)                ┌──────────────────┐
                                            │ Human-Verified   │
                                            └──────────────────┘
                                                       │
                                                       ▼
                                            ┌─────────────────┐
                                            │  In-Production  │
                                            └─────────────────┘
```

| Label | Color | Set By | Meaning |
|-------|-------|--------|---------|
| `PR-Ready` | Blue | Builder | PR created, ready for testing |
| `Testing` | Yellow | Tester | Tester actively testing |
| `Tests-Passed` | Green | Tester | All local tests passed |
| `Tests-Failed` | Red | Tester | Failures found, back to Builder |
| `On-Staging` | Purple | Admin | Deployed to staging |
| `Staging-Verified` | Light Green | Tester | Staging E2E passed |
| `Human-Verified` | Orange | Human | Human approved, ready for production |
| `In-Production` | Gray | Admin | Live in production |

---

## Human Verification Checklist Requirements

**MANDATORY:** When requesting human verification (`Tests-Passed` label), the Tester agent MUST add a detailed verification checklist as a Linear comment.

### Checklist Template

```markdown
## 🧪 Human Verification Checklist

**PR #XXX is merged to staging. Please verify the following on the staging environment.**

### Staging URLs
- **Frontend:** [Get Vercel Preview URL - see instructions below]
- **Backend:** https://yardav5-staging-b19c.up.railway.app

### How to Find Vercel Preview URL
Run this command to get the Vercel preview URL for the PR:
```bash
gh pr view <PR_NUMBER> --json comments --jq '.comments[] | select(.body | contains("vercel.app")) | .body' | grep -oE 'https://[^)]+\.vercel\.app'
```
Or check the PR page on GitHub for the Vercel bot comment with the preview link.

---

### Test 1: [Feature Name]
| Step | Expected Result |
|------|-----------------|
| [Action to take] | [What should happen] |
| [Action to take] | [What should happen] |

### Test 2: [Feature Name]
| Step | Expected Result |
|------|-----------------|
| [Action to take] | [What should happen] |

... (repeat for all key features)

---

### Verification Actions

**If ALL tests pass:**
1. Add `Human-Verified` label to this issue
2. Comment: "Verified ✅"

**If ANY test fails:**
1. Add `Tests-Failed` label
2. Comment with: Which test failed, expected vs actual, screenshot if applicable

---

*Automated tests passed: X/X on localhost + staging backend*
```

### Why This Matters

- **Clear expectations** - Human validators know exactly what to test
- **Reproducible verification** - Step-by-step instructions eliminate guesswork
- **Pass/fail clarity** - Explicit actions for each outcome
- **Audit trail** - Verification steps documented in Linear

---

## Workflow Scenarios

### Happy Path

1. **PM** creates issue with epic, size, CUJs, test plan
2. **Builder** picks up issue, implements, creates PR
3. **Builder** adds `PR-Ready`, auto-spawns Tester (M+)
4. **Tester** reads test plan, runs E2E tests
5. **Tester** passes → adds `Tests-Passed`
6. **Admin** merges to staging, adds `On-Staging`
7. **Tester** runs staging tests, adds `Staging-Verified`
8. **Human** reviews staging, adds `Human-Verified`
9. **Admin** merges staging → main
10. **Admin** verifies production, adds `In-Production`

### Test Failure

1. **Tester** finds failures
2. **Tester** creates sub-issues, adds `Tests-Failed`
3. **Builder** fixes issues, pushes to PR
4. **Builder** re-adds `PR-Ready`
5. Workflow continues from step 4

### Staging Failure

1. **Admin** deploys to staging
2. **Tester** runs staging tests, finds failures
3. **Tester** adds `Tests-Failed`, removes `On-Staging`
4. **Builder** fixes, workflow restarts

---

## Epic & CUJ System

All issues must be tagged with epics and CUJs for scoped testing.

**Epic Labels:**
- `epic:auth` - Authentication
- `epic:generation` - AI landscape generation
- `epic:payments` - Tokens, subscriptions
- `epic:marketplace` - Estimates, proposals
- `epic:pro-mode` - 2D site plans
- `epic:pros-dashboard` - Pros dashboard
- `epic:account` - User account
- `epic:holiday` - Seasonal campaigns
- `epic:admin` - Admin tools

**CUJ Format:** `#cuj-name` (e.g., `#gen-first`, `#pay-tokens`)

**Reference:** See `docs/EPIC_REGISTRY.md` for complete list.

---

## Test Plan Template

Every M/L/XL issue MUST include in description:

```markdown
## Test Plan

**Epic:** epic:<name>
**Size:** <XS|S|M|L|XL>

### Automated Tests
Run the following command after staging deployment:
```bash
npx playwright test --grep "@<epic>"
```

### CUJs to Verify
- [ ] #<cuj-1>: <description>
- [ ] #<cuj-2>: <description>

### Manual Verification
- [ ] <manual check 1>
- [ ] <manual check 2>
```

---

## Branch-Based Deployment

| Branch | Deploys To | Stripe Mode |
|--------|------------|-------------|
| `staging` | Railway Staging + Vercel Preview | TEST |
| `main` | Railway Production + Vercel Production | LIVE |

**Deployment Rules by Size:**
| Size | Branch Flow | Human Verification |
|------|-------------|-------------------|
| XS/S/M (1-3 pts) | Feature → `main` (direct) | Not required |
| L/XL (5-8+ pts) | Feature → `staging` → `main` | Required before production |

**Rationale:** Small changes are low-risk and can be deployed directly to production. Large changes require staging validation.

---

## Quick Reference

| Task | Command |
|------|---------|
| **Start any issue (recommended)** | `/workon YAR-XXX` |
| Start feature work (manual) | `/builder YAR-XXX` |
| Test a PR | `/tester YAR-XXX` |
| Deploy to staging | `/admin stage YAR-XXX` |
| Deploy to production | `/admin promote YAR-XXX` |
| Elaborate requirements | `/pm <description>` |
| Check service health | `/admin health` |

### When to Use Each Command

| Scenario | Command | Why |
|----------|---------|-----|
| New issue, any size | `/workon YAR-XXX` | Auto-routes to correct agent |
| Resume paused work | `/workon YAR-XXX` | Detects state, continues |
| Skip PM elaboration | `/builder YAR-XXX` | Direct to implementation |
| Manual testing | `/tester YAR-XXX` | Specific test run |
| Production deploy | `/admin promote YAR-XXX` | After staging verified |

---

## Tools & Integrations

### MCP Tools

| MCP Server | Purpose |
|------------|---------|
| **Linear** | Issue tracking, labels, comments, workflow state |
| **GitHub** | PRs, code review, merges |
| **Railway** | Backend deployment, PR environments |
| **Vercel** | Frontend deployment, previews |
| **Supabase** | Database queries, migrations |
| **Stitch** | AI-powered UI generation from DESIGN.md |

### Stitch Integration (UI Generation)

The MAW workflow integrates with Google Stitch for AI-powered UI generation:

**Skills Available:**
- `/design-md` - Analyze Stitch projects → generate `DESIGN.md` semantic design system
- `/reactcomponents` - Convert Stitch designs → modular React components
- `/stitch-loop` - Iterative UI building with autonomous baton-passing

**Workflow:**
```
DESIGN.md (design tokens) → Stitch (AI UI generation) → React components
```

**Builder Agent UI Generation:**
1. Read `DESIGN.md` for design tokens (colors, typography, components)
2. Use Stitch MCP to generate UI screens matching the design system
3. Use `/reactcomponents` to convert Stitch output to React code
4. Integrate generated components into the codebase

**Prerequisites:**
- Stitch MCP server connected (`claude mcp add stitch`)
- `DESIGN.md` in project root documenting the design system
- Google Cloud auth configured (`gcloud auth application-default login`)

---

## Related Documentation

- [protocol.md](./protocol.md) - Agent communication protocol (handoffs, schemas, state machine)
- [EPIC_REGISTRY.md](../EPIC_REGISTRY.md) - Epic/CUJ canonical list
- [MANUAL_TESTING_GUIDE.md](../MANUAL_TESTING_GUIDE.md) - Manual test procedures
- [MULTI_AGENT_WORKFLOW.md](../MULTI_AGENT_WORKFLOW.md) - Detailed workflow docs
- [TESTING.md](../TESTING.md) - Testing strategy
- [DESIGN.md](../../DESIGN.md) - Semantic design system for Stitch

---

## Safety Rules

### NEVER:
1. Push L/XL issues directly to `main` branch (must go through staging)
2. Deploy L/XL to production without `Human-Verified` label
3. Auto-fix production issues
4. Run DELETE/UPDATE on production database without confirmation

### ALWAYS:
1. Run health checks before/after deployments
2. Document actions in Linear
3. Wait for each deployment to complete before next
4. Have rollback command ready
5. For L/XL: Complete full staging → human verify → production cycle
6. For XS/S/M: Can deploy directly to production after tests pass
