# Multi-Agent Workflow (MAW) - Standard Operating Procedure

**Version:** 2.2
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
> - Consistent quality gates (PM → Builder → Tester → PM Validation → Human → Admin)
> - Proper test coverage for all changes
> - Audit trail via Linear labels
> - Predictable deployment pipeline

---

## Environments

| Environment | Frontend URL | Backend URL | Purpose |
|-------------|--------------|-------------|---------|
| **PR Preview** | `yarda-v5-frontend-*.vercel.app` | `yardav5-staging-b19c.up.railway.app` | Per-PR testing, PM validation, human verification |
| **Staging** | `staging.yarda.ai` | `yardav5-staging-b19c.up.railway.app` | L/XL staging verification after merge |
| **Production** | `yarda.pro` | `yardav5-production.up.railway.app` | Live production |

**Environment Usage by Phase:**

| Phase | Environment | Who |
|-------|-------------|-----|
| Development | Local (`localhost:3000`) + staging backend | Builder |
| E2E Testing | PR Preview + staging backend | Tester |
| PM Validation | PR Preview + staging backend | PM |
| Human Verification | PR Preview + staging backend | Human |
| Staging Verification (L/XL only) | Staging | Tester |
| Production | Production | Admin |

**Vercel Protection Bypass Token:** `jJPRaVtjzk2gtqGRvwbzyMaJVJmzJTeh`
- Access staging: `https://staging.yarda.ai?x-vercel-protection-bypass=<token>&x-vercel-set-bypass-cookie=true`

---

## Quick Start: `/workon YAR-XXX`

The **recommended entry point** for all development:

```bash
/workon YAR-123   # Auto-routes issue through MAW pipeline
```

**What `/workon` does:**
1. Fetches issue from Linear
2. Checks size (estimate field, or has PM set it)
3. Routes through full validation (PM + Human) on PR Preview
4. **M or smaller** → Direct to production after Human-Verified
5. **L or XL** → Staging deployment, then production after Staging-Verified

**Size-Based Deployment Policy:**
| Size | Points | PR Preview Validation | Staging Required | Production |
|------|--------|----------------------|------------------|------------|
| XS/S/M | 1-3 | Yes (PM + Human) | No | Direct after Human-Verified |
| L/XL | 5-8+ | Yes (PM + Human) | Yes | After Staging-Verified |

---

## Overview

The Multi-Agent Workflow (MAW) is Yarda's CI/CD system using four specialized AI agents that coordinate via Linear labels. Each agent runs in its own Claude Code session.

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              MULTI-AGENT WORKFLOW                                        │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  Raw Requirement                                                                        │
│       │                                                                                 │
│       ▼                                                                                 │
│  ┌─────────────┐  Issue Ready  ┌─────────────┐  PR-Ready   ┌─────────────┐             │
│  │     PM      │ ─────────────▶│   BUILDER   │ ──────────▶│   TESTER    │             │
│  │   Agent     │               │   Agent     │             │   Agent     │             │
│  │             │               │             │             │             │             │
│  │ • Elaborate │               │ • Research  │  ◀────────  │ • E2E tests │             │
│  │ • Size      │               │ • Implement │  Tests-     │ • Reports   │             │
│  │ • Epic/CUJ  │               │ • Create PR │  Failed     │             │             │
│  │ • Test plan │               │             │             │             │             │
│  └─────────────┘               │ [localhost] │             │[PR Preview] │             │
│                                └─────────────┘             └─────────────┘             │
│                                                                   │                    │
│                                                                   │ Tests-Passed       │
│                                                                   ▼                    │
│                                                          ┌─────────────┐               │
│                                                          │     PM      │               │
│                                                          │ VALIDATION  │               │
│                                                          │             │               │
│                                                          │ • Real user │               │
│                                                          │ • UX check  │               │
│                                                          │[PR Preview] │               │
│                                                          └─────────────┘               │
│                                                                   │                    │
│                                                                   │ PM-Validated       │
│                                                                   ▼                    │
│                                                          ┌─────────────┐               │
│                                                          │   HUMAN     │               │
│                                                          │ VALIDATION  │               │
│                                                          │             │               │
│                                                          │ • Final OK  │               │
│                                                          │[PR Preview] │               │
│                                                          └─────────────┘               │
│                                                                   │                    │
│                                                                   │ Human-Verified     │
│                                                                   ▼                    │
│                                                          ┌─────────────┐               │
│                                                          │   ADMIN     │               │
│                                                          │   Agent     │               │
│                                                          │             │               │
│                                                          │ • Deploy    │               │
│                                                          │ • Merge     │               │
│                                                          └─────────────┘               │
│                                                                   │                    │
│                                                     ┌─────────────┴─────────────┐      │
│                                                     │                           │      │
│                                            (XS/S/M) ▼                  (L/XL)   ▼      │
│                                          ┌───────────────┐        ┌──────────────┐    │
│                                          │  PRODUCTION   │        │   STAGING    │    │
│                                          │   (direct)    │        │  [staging]   │    │
│                                          │               │        └──────┬───────┘    │
│                                          │ [production]  │               │            │
│                                          └───────────────┘               ▼            │
│                                                                  ┌──────────────┐     │
│                                                                  │   TESTER     │     │
│                                                                  │   Staging    │     │
│                                                                  │  Verification│     │
│                                                                  │  [staging]   │     │
│                                                                  └──────┬───────┘     │
│                                                                         │             │
│                                                                         │ Staging-    │
│                                                                         │ Verified    │
│                                                                         ▼             │
│                                                                  ┌──────────────┐     │
│                                                                  │  PRODUCTION  │     │
│                                                                  │[production]  │     │
│                                                                  └──────────────┘     │
│                                                                                        │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

**Key Flow:**
1. All testing, PM validation, and human verification happen on **PR Preview**
2. Admin deploys after Human-Verified
3. L/XL requires additional **Staging** verification before production

---

## Agents

### 1. PM Agent (`/pm`)

**Command:** `.claude/commands/pm.md`
**Skill:** `.claude/skills/pm-requirements/skill.md`

**Responsibilities (Start of Flow):**
- Elaborate raw requirements into comprehensive specs
- Determine epic (`epic:auth`, `epic:generation`, etc.)
- Assign T-shirt size (XS/S/M/L/XL) with points
- Define CUJs (Critical User Journeys)
- Create/update Linear issues with:
  - Epic label (`epic:<name>`)
  - Size label (XS/S/M/L/XL)
  - CUJ references (`#cuj-name`)
  - Test plan (for M+ sizes)
- Maintain `docs/EPIC_REGISTRY.md`
- Update `docs/MANUAL_TESTING_GUIDE.md`

**Responsibilities (Pre-Human Validation):**
- Validate features on **PR Preview** as a **real user** using browser
- Walk through each CUJ end-to-end
- Verify acceptance criteria are met from user perspective
- Identify UX issues automated tests might miss
- Recommend feature for human sign-off or signal Builder for fixes

**Environment:** PR Preview (Vercel preview URL + staging backend)

**Commands:**
```bash
/pm                    # Interactive requirements session
/pm <description>      # Elaborate specific feature
/pm-requirements <desc> # Alias for /pm <description>
/pm validate YAR-XXX   # Pre-human validation on PR Preview
```

**Outputs (Requirements):**
- Linear issue with epic, size, CUJs, acceptance criteria
- Test plan (for M+ sizes)
- Updated EPIC_REGISTRY.md (if new CUJs)

**Outputs (Validation):**
- Validation report with screenshots/GIFs
- `PM-Validated` label (if passed)
- Sub-issues for any UX problems found

---

### 2. Builder Agent (`/builder`)

**Command:** `.claude/commands/builder.md`

**Responsibilities:**
- Pick up Linear issues with specs from PM
- Research codebase and existing patterns
- **L issues:** Consider using SpecKit for structured specification
- **XL issues:** Use full SpecKit workflow (required)
- Implement feature on feature branch
- Write unit tests (pytest for backend)
- Create PR (auto-creates Vercel preview)
- Auto-spawn Tester for M/L/XL issues

**Environment:** Local development (`localhost:3000` + staging backend)

**Commands:**
```bash
/builder         # Auto-pickup highest priority Todo issue
/builder YAR-5   # Work on specific issue

# SpecKit commands (L: optional, XL: required)
/speckit.specify    # Create specification from description
/speckit.clarify    # Resolve ambiguities in spec
/speckit.plan       # Generate implementation plan
/speckit.tasks      # Create task breakdown
/speckit.implement  # Execute tasks
```

**Outputs:**
- Feature branch with implementation
- `specs/<number>-<name>/spec.md` (for M+ sizes)
- SpecKit artifacts (for L/XL): `spec.md`, `plan.md`, `tasks.md`
- Unit tests
- PR with test plan (creates PR Preview automatically)
- Linear issue with `PR-Ready` label

---

### 3. Tester Agent (`/tester`)

**Command:** `.claude/commands/tester.md`

**Responsibilities:**
- Pick up issues with `PR-Ready` label
- Read test plan from Linear issue description
- Run scoped E2E tests on **PR Preview**
- Use Chrome browser automation or Playwright MCP
- Report results with screenshots
- Verify staging deployments (L/XL only)
- Create Human Verification Checklist

**Environment:**
- PR testing: PR Preview (Vercel preview + staging backend)
- Staging testing: Staging (`staging.yarda.ai` + staging backend)

**Commands:**
```bash
/tester              # Auto-pickup oldest PR-Ready issue
/tester YAR-5        # Test specific issue on PR Preview
/tester staging YAR-5  # Test staging deployment (L/XL)
```

**Test Scope by Size:**
| Size | Test Command | Environment |
|------|--------------|-------------|
| XS | `npm run test:smoke` | PR Preview |
| S | `npx playwright test --grep "#<cuj>"` | PR Preview |
| M | `npx playwright test --grep "@<epic>"` | PR Preview |
| L/XL | `npm run test:full` | PR Preview, then Staging |

**Outputs:**
- Test report with screenshots
- Sub-issues for any failures
- `Tests-Passed` or `Tests-Failed` label
- `Staging-Verified` label (after staging tests, L/XL only)
- **Human Verification Checklist** (Linear comment with PR Preview URLs)

---

### 4. Admin Agent (`/admin`)

**Command:** `.claude/commands/admin.md`

**Responsibilities:**
- Review PRs with `Human-Verified` label
- Deploy to production (XS/S/M) or staging (L/XL)
- Monitor deployment
- Spawn Tester for staging verification (L/XL)
- Merge staging → main for production (L/XL)
- Run production smoke tests
- Mark issues as Done

**Environment:**
- Staging deployment: `staging.yarda.ai`
- Production deployment: `yarda.pro`

**Commands:**
```bash
/admin                  # Review all ready PRs
/admin review           # Review PRs without deploying
/admin stage YAR-5      # Deploy specific issue to staging (L/XL)
/admin promote YAR-5    # Promote to production
/admin status           # Show deployment status
/admin health           # Check service health
```

**Outputs:**
- Staging deployments (L/XL)
- Production deployments
- `In-Production` label
- Linear issue marked "Done"

---

## Linear Label State Machine

### XS/S/M Flow (Direct to Production)

```
PR-Ready → Testing → Tests-Passed → PM-Validated → Human-Verified → In-Production
             ↓
        Tests-Failed (back to Builder)
```

### L/XL Flow (Via Staging)

```
PR-Ready → Testing → Tests-Passed → PM-Validated → Human-Verified → On-Staging → Staging-Verified → In-Production
             ↓                                                          ↓
        Tests-Failed (back to Builder)                           Tests-Failed
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

| Label | Color | Set By | Environment | Meaning |
|-------|-------|--------|-------------|---------|
| `PR-Ready` | Blue | Builder | PR Preview | PR created, ready for testing |
| `Testing` | Yellow | Tester | PR Preview | Tester actively testing |
| `Tests-Passed` | Green | Tester | PR Preview | All tests passed |
| `Tests-Failed` | Red | Tester | Any | Failures found, back to Builder |
| `PM-Validated` | Teal | PM | PR Preview | PM validated as real user |
| `Human-Verified` | Orange | Human | PR Preview | Human approved |
| `On-Staging` | Purple | Admin | Staging | Deployed to staging (L/XL only) |
| `Staging-Verified` | Light Green | Tester | Staging | Staging E2E passed (L/XL only) |
| `In-Production` | Gray | Admin | Production | Live in production |

---

## Human Verification Checklist Requirements

**MANDATORY:** When tests pass, provide a detailed verification checklist with **PR Preview URLs**.

### Checklist Template

```markdown
## 🧪 Human Verification Checklist

**PR #XXX is ready for verification on the PR Preview environment.**

### PR Preview URLs
- **Frontend:** <Vercel preview URL from PR comments>
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
| Navigate to <PR Preview URL> | Page loads |
| [Action to take] | [What should happen] |

### Test 2: [Feature Name]
| Step | Expected Result |
|------|-----------------|
| [Action to take] | [What should happen] |

---

### Verification Actions

**If ALL tests pass:**
1. Add `Human-Verified` label to this issue
2. Comment: "Verified ✅ on PR Preview"

**If ANY test fails:**
1. Add `Tests-Failed` label
2. Comment with: Which test failed, expected vs actual, screenshot if applicable

---

*Automated tests passed: X/X on PR Preview*
*Environment: PR Preview (Vercel + Staging Backend)*
```

---

## Workflow Scenarios

### Happy Path - XS/S/M (Direct to Production)

| Step | Agent | Action | Environment |
|------|-------|--------|-------------|
| 1 | **PM** | Creates issue with epic, size, CUJs, test plan | - |
| 2 | **Builder** | Implements feature, creates PR | localhost:3000 |
| 3 | **Builder** | Adds `PR-Ready`, signals Tester | - |
| 4 | **Tester** | Runs E2E tests on PR Preview | PR Preview |
| 5 | **Tester** | Passes → adds `Tests-Passed` | PR Preview |
| 6 | **PM** | Validates as real user, adds `PM-Validated` | PR Preview |
| 7 | **Human** | Verifies, adds `Human-Verified` | PR Preview |
| 8 | **Admin** | Merges PR to main → Production deploys | Production |
| 9 | **Admin** | Verifies production, adds `In-Production` | Production |

### Happy Path - L/XL (Via Staging)

| Step | Agent | Action | Environment |
|------|-------|--------|-------------|
| 1 | **PM** | Creates issue with epic, size, CUJs, test plan | - |
| 2 | **Builder** | Runs SpecKit workflow (L: recommended, XL: required) | localhost:3000 |
| 3 | **Builder** | Implements feature, creates PR | localhost:3000 |
| 4 | **Builder** | Adds `PR-Ready`, signals Tester | - |
| 5 | **Tester** | Runs E2E tests on PR Preview | PR Preview |
| 6 | **Tester** | Passes → adds `Tests-Passed` | PR Preview |
| 7 | **PM** | Validates as real user, adds `PM-Validated` | PR Preview |
| 8 | **Human** | Verifies, adds `Human-Verified` | PR Preview |
| 9 | **Admin** | Merges to staging, adds `On-Staging` | Staging |
| 10 | **Tester** | Runs staging E2E, adds `Staging-Verified` | Staging |
| 11 | **Admin** | Merges staging → main → Production | Production |
| 12 | **Admin** | Verifies production, adds `In-Production` | Production |

### Test Failure

| Step | Action | Environment |
|------|--------|-------------|
| 1 | **Tester** finds failures | PR Preview |
| 2 | **Tester** creates sub-issues, adds `Tests-Failed` | - |
| 3 | **Builder** fixes issues, pushes to PR | localhost:3000 |
| 4 | **Builder** re-adds `PR-Ready` | - |
| 5 | Workflow continues from step 4 | PR Preview |

### PM Validation Failure

| Step | Action | Environment |
|------|--------|-------------|
| 1 | **PM** validates feature as real user | PR Preview |
| 2 | **PM** finds UX issues or unmet requirements | PR Preview |
| 3 | **PM** creates sub-issues, removes `Tests-Passed` | - |
| 4 | **Builder** fixes issues | localhost:3000 |
| 5 | **Tester** re-runs tests | PR Preview |
| 6 | **PM** re-validates, workflow continues | PR Preview |

### Staging Failure (L/XL only)

| Step | Action | Environment |
|------|--------|-------------|
| 1 | **Admin** deploys to staging | Staging |
| 2 | **Tester** runs staging tests, finds failures | Staging |
| 3 | **Tester** adds `Tests-Failed`, removes `On-Staging` | - |
| 4 | **Builder** fixes, pushes to PR | localhost:3000 |
| 5 | Workflow restarts from PR testing | PR Preview |

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

### Automated Tests (on PR Preview)
Run the following command:
```bash
npx playwright test --grep "@<epic>"
```

### CUJs to Verify
- [ ] #<cuj-1>: <description>
- [ ] #<cuj-2>: <description>

### Manual Verification (on PR Preview)
- [ ] <manual check 1>
- [ ] <manual check 2>
```

---

## Branch-Based Deployment

| Branch | Deploys To | Stripe Mode |
|--------|------------|-------------|
| PR branch | Vercel Preview (auto) | TEST |
| `staging` | Railway Staging + Vercel Staging | TEST |
| `main` | Railway Production + Vercel Production | LIVE |

**Deployment Rules by Size:**
| Size | Validation Environment | Merge Flow | Production Trigger |
|------|----------------------|------------|-------------------|
| XS/S/M (1-3 pts) | PR Preview | Feature → `main` | Human-Verified |
| L/XL (5-8+ pts) | PR Preview → Staging | Feature → `staging` → `main` | Staging-Verified |

---

## Quick Reference

| Task | Command | Environment |
|------|---------|-------------|
| **Start any issue (recommended)** | `/workon YAR-XXX` | Auto |
| Start feature work (manual) | `/builder YAR-XXX` | localhost |
| **SpecKit workflow (L: recommended, XL: required)** | `/speckit.specify` → `.clarify` → `.plan` → `.tasks` → `.implement` | localhost |
| Test a PR | `/tester YAR-XXX` | PR Preview |
| **Pre-human validation** | `/pm validate YAR-XXX` | PR Preview |
| Deploy to staging (L/XL) | `/admin stage YAR-XXX` | Staging |
| Test staging (L/XL) | `/tester staging YAR-XXX` | Staging |
| Deploy to production | `/admin promote YAR-XXX` | Production |
| Check service health | `/admin health` | All |

### When to Use Each Command

| Scenario | Command | Environment |
|----------|---------|-------------|
| New issue, any size | `/workon YAR-XXX` | Auto-routes |
| Resume paused work | `/workon YAR-XXX` | Auto-detects |
| Skip PM elaboration | `/builder YAR-XXX` | localhost |
| L issue (structured spec) | `/speckit.specify` | localhost |
| XL issue (full workflow) | `/speckit.specify` → `.clarify` → `.plan` → `.tasks` → `.implement` | localhost |
| Test PR before merge | `/tester YAR-XXX` | PR Preview |
| PM validate before human | `/pm validate YAR-XXX` | PR Preview |
| L/XL staging deploy | `/admin stage YAR-XXX` | Staging |
| L/XL staging test | `/tester staging YAR-XXX` | Staging |
| Production deploy | `/admin promote YAR-XXX` | Production |

---

## Tools & Integrations

### MCP Tools

| MCP Server | Purpose |
|------------|---------|
| **Linear** | Issue tracking, labels, comments, workflow state |
| **GitHub** | PRs, code review, merges |
| **Railway** | Backend deployment, PR environments |
| **Vercel** | Frontend deployment, PR previews (auto) |
| **Supabase** | Database queries, migrations |
| **Stitch** | AI-powered UI generation from DESIGN.md |
| **Claude-in-Chrome** | Browser automation for PM validation |

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
1. Deploy L/XL to production without `Staging-Verified` label
2. Skip PM validation (all sizes require PM-Validated before Human-Verified)
3. Auto-fix production issues
4. Run DELETE/UPDATE on production database without confirmation

### ALWAYS:
1. Test on PR Preview before any deployment
2. Run PM validation on PR Preview (not staging or production)
3. Run health checks before/after deployments
4. Document actions in Linear
5. Wait for each deployment to complete before next
6. Have rollback command ready
7. For L/XL: Complete full PR Preview → Staging → Production cycle
8. For XS/S/M: Complete PR Preview validation → Production
