# Multi-Agent Workflow (MAW) v4 - Standard Operating Procedure

**Version:** 4.0
**Last Updated:** 2026-02-17
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
> - Consistent quality gates (PM → Builder → Tester → PM Validation → Human → TPM ships)
> - Proper test coverage for all changes
> - Audit trail via Linear labels
> - Predictable deployment pipeline

---

## What Changed in v4

| Aspect | v3 (Old) | v4 (New) |
|--------|----------|----------|
| **Who merges to main** | Admin Agent | **TPM Agent (sole merger)** |
| **Admin role** | PR review + merge + deploy | **Ops-only: health, stats, DB** |
| **Project orchestration** | Manual per-issue | **TPM plans waves, creates workspaces** |
| **Shipping** | Manual `/admin promote` | **Auto-ship on `/tpm sync`** |
| **Agent count** | 4 (PM, Builder, Tester, Admin) | **5 (TPM, PM, Builder, Tester, Admin)** |
| **MCP tool name** | `mcp__plugin_linear_linear__` | **`mcp__linear__`** |

---

## Environments

| Environment | Frontend URL | Backend URL | Purpose |
|-------------|--------------|-------------|---------|
| **PR Preview** | `yarda-v5-frontend-*.vercel.app` | `yardav5-staging-b19c.up.railway.app` | Per-PR testing, PM validation, human verification |
| **Staging** | `staging.yarda.ai` | `yardav5-staging-b19c.up.railway.app` | L/XL staging verification after merge |
| **Production** | `yarda.pro` | `yardav5-production.up.railway.app` | Live production |

**Vercel Protection Bypass Token:** `jJPRaVtjzk2gtqGRvwbzyMaJVJmzJTeh`

---

## Quick Start

### For a new project:

```bash
/tpm <project description>   # TPM creates issues + waves + workspaces
# Open workspaces in Conductor → run /workon YAR-XXX in each
/tpm sync                     # Periodically check status + auto-ship
```

### For a single issue:

```bash
/workon YAR-123   # Auto-routes through PM → Builder → Tester
```

---

## Overview

MAW v4 uses five specialized AI agents coordinated via Linear labels. The **TPM Agent** serves as the human's single command center.

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              MULTI-AGENT WORKFLOW v4                                     │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  Project Description                                                                    │
│       │                                                                                 │
│       ▼                                                                                 │
│  ┌─────────────┐  Creates Issues  ┌─────────────┐  /workon    ┌─────────────┐          │
│  │     TPM     │ ────────────────▶│  CONDUCTOR   │ ──────────▶│     PM      │          │
│  │   Agent     │  + Wave Plan     │  WORKSPACES  │             │   Agent     │          │
│  │             │  + Worktrees     │  (parallel)  │             └──────┬──────┘          │
│  │ • Plan      │                  └──────────────┘                    │                  │
│  │ • Sync      │                                              Issue Ready                │
│  │ • Ship      │                                                     │                  │
│  └──────┬──────┘                                                     ▼                  │
│         │                                                    ┌─────────────┐             │
│         │                                                    │   BUILDER   │             │
│         │                                                    │   Agent     │             │
│         │                                                    └──────┬──────┘             │
│         │                                                           │ PR-Ready           │
│         │                                                           ▼                    │
│         │                                                    ┌─────────────┐             │
│         │                                                    │   TESTER    │             │
│         │                                                    │   Agent     │             │
│         │                                                    └──────┬──────┘             │
│         │                                                           │ Tests-Passed       │
│         │                                                           ▼                    │
│         │                                                    ┌─────────────┐             │
│         │                                                    │     PM      │             │
│         │                                                    │ VALIDATION  │             │
│         │                                                    └──────┬──────┘             │
│         │                                                           │ PM-Validated       │
│         │                                                           ▼                    │
│         │                                                    ┌─────────────┐             │
│         │                                                    │   HUMAN     │             │
│         │                                                    │ VALIDATION  │             │
│         │                                                    └──────┬──────┘             │
│         │                                                           │ Human-Verified     │
│         │                                                           ▼                    │
│         │ ◀───── /tpm sync detects Human-Verified ──────────────────┘                   │
│         │                                                                                │
│         ▼                                                                                │
│  ┌─────────────┐                                                                        │
│  │ TPM SHIPS   │  Merge → Deploy → Smoke Test → In-Production                          │
│  └─────────────┘                                                                        │
│                                                                                          │
│  ┌─────────────┐                                                                        │
│  │   ADMIN     │  (ops-only: health, stats, DB queries)                                 │
│  └─────────────┘                                                                        │
│                                                                                          │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Agents

### 1. TPM Agent (`/tpm`) — **Project Orchestrator + Auto-Shipper**

**Command:** `.claude/commands/tpm.md`

The human's single command center. Runs in 1 dedicated Conductor workspace.

**Responsibilities:**
- Break projects into independently shippable Linear issues
- Map dependencies, plan execution waves (topological sort)
- Create git worktrees for Conductor workspaces
- **Auto-ship** verified features: merge → deploy → smoke test → In-Production
- Rebase `staging` on `main` after each production deploy
- Track wave progress, advance waves when complete

**Key Rule:** TPM is the **ONLY** agent that merges to `main`.

**Commands:**

| Command | What it does |
|---------|-------------|
| `/tpm <description>` | Break project into issues, plan waves, create workspaces |
| `/tpm sync` | **THE main command.** Poll, dashboard, auto-ship |
| `/tpm wave` | Show current wave, create workspaces |
| `/tpm status` | Quick read-only summary |

---

### 2. PM Agent (`/pm`)

**Command:** `.claude/commands/pm.md`

**Responsibilities (Start of Flow):**
- Elaborate raw requirements into comprehensive specs
- Determine epic, assign size, define CUJs
- Create/update Linear issues with test plans

**Responsibilities (Pre-Human Validation):**
- Validate features on PR Preview as a real user using browser automation
- Walk through each CUJ end-to-end
- Recommend for human sign-off or signal Builder for fixes

---

### 3. Builder Agent (`/builder`)

**Command:** `.claude/commands/builder.md`

**Responsibilities:**
- Pick up Linear issues with specs from PM
- Implement feature on feature branch
- **Always rebase on `main`** before creating PR
- Write unit tests, create PR
- Auto-spawn Tester for M/L/XL issues

---

### 4. Tester Agent (`/tester`)

**Command:** `.claude/commands/tester.md`

**Responsibilities:**
- Pick up issues with `PR-Ready` label
- Run scoped E2E tests on PR Preview
- Create Human Verification Checklist
- Report results with screenshots
- Verify staging deployments (L/XL only)

---

### 5. Admin Agent (`/admin`) — **Ops-Only**

**Command:** `.claude/commands/admin.md`

**Responsibilities:**
- Service health monitoring (production + staging)
- Usage statistics and database queries (read-only)
- Deployment status checks

**Note:** Admin does NOT merge PRs or deploy. TPM handles all shipping.

---

## Linear Label State Machine

### All Sizes Flow

```
PR-Ready → Testing → Tests-Passed → PM-Validated → Human-Verified → In-Production
              ↓
        Tests-Failed (back to Builder)
```

### L/XL Additional States

```
Human-Verified → On-Staging → Staging-Verified → In-Production
                                    ↓
                              Tests-Failed
```

| Label | Set By | Meaning |
|-------|--------|---------|
| `PR-Ready` | Builder | PR created, ready for testing |
| `Testing` | Tester | Tester actively testing |
| `Tests-Passed` | Tester | All E2E tests passed |
| `Tests-Failed` | Tester | Failures found, back to Builder |
| `PM-Validated` | PM | PM validated as real user |
| `Human-Verified` | Human | Human approved |
| `On-Staging` | TPM | Deployed to staging (L/XL only) |
| `Staging-Verified` | Tester | Staging E2E passed (L/XL only) |
| `In-Production` | **TPM** | Live in production |

---

## Workflow Scenarios

### Happy Path - XS/S/M (Direct to Production)

| Step | Agent | Action | Environment |
|------|-------|--------|-------------|
| 1 | **PM** | Creates issue with epic, size, CUJs, test plan | - |
| 2 | **Builder** | Implements feature, rebases on main, creates PR → main | localhost |
| 3 | **Builder** | Adds `PR-Ready`, auto-spawns Tester | - |
| 4 | **Tester** | Runs E2E tests on PR Preview | PR Preview |
| 5 | **Tester** | Passes → adds `Tests-Passed` | PR Preview |
| 6 | **PM** | Validates as real user, adds `PM-Validated` | PR Preview |
| 7 | **Human** | Verifies, adds `Human-Verified` | PR Preview |
| 8 | **TPM** | `/tpm sync` → merges PR to main → deploys | Production |
| 9 | **TPM** | Smoke tests pass → adds `In-Production` | Production |

### Happy Path - L/XL (Via Staging)

| Step | Agent | Action | Environment |
|------|-------|--------|-------------|
| 1 | **PM** | Creates issue with epic, size, CUJs, test plan | - |
| 2 | **Builder** | Implements, rebases on main, creates PR #1 → staging | localhost |
| 3 | **Tester** | Runs E2E tests on PR Preview | PR Preview |
| 4 | **PM** | Validates as real user | PR Preview |
| 5 | **Human** | Verifies, adds `Human-Verified` | PR Preview |
| 6 | **TPM** | Merges to staging, adds `On-Staging` | Staging |
| 7 | **Tester** | Runs staging E2E, adds `Staging-Verified` | Staging |
| 8 | **Builder** | Creates PR #2 → main | - |
| 9 | **TPM** | Merges PR #2 to main → deploys | Production |
| 10 | **TPM** | Smoke tests → `In-Production`, rebases staging on main | Production |

### Test Failure (Auto-Fix Loop)

| Step | Action |
|------|--------|
| 1 | **Tester** finds failures on PR Preview |
| 2 | **Tester** auto-spawns Builder with failure details |
| 3 | **Builder** fixes issues, pushes to PR branch |
| 4 | **Builder** auto-spawns Tester for re-verification |
| 5 | Max 2 fix attempts → escalate to human |

---

## Wave Execution (TPM)

### Wave Planning

TPM breaks projects into waves using topological sort of dependency DAG:

- **Wave 1:** Issues with no dependencies (foundation)
- **Wave 2:** Issues that depend only on Wave 1
- **Wave N+1** starts after ALL Wave N issues reach `In-Production`

### TPM Automation on `/tpm sync`

| What TPM Detects | Automated Action | Human Needed? |
|-----------------|-----------------|---------------|
| Issue has no spec | Flag for PM elaboration | No |
| Wave ready to start | Create git worktrees | Human opens workspace |
| `PR-Ready` detected | Note in dashboard | No |
| `Tests-Passed` detected | Notify human | Human verifies on staging |
| `Human-Verified` detected | **Auto-merge → deploy → smoke test → In-Production** | **No** |
| All wave N shipped | Advance to wave N+1, create next worktrees | Human opens workspaces |
| `Tests-Failed` 2+ times | Flag as blocked | Human investigates |

---

## Size-Based Deployment Policy

| Size | Points | PR Target | Staging Required | Production |
|------|--------|-----------|------------------|------------|
| XS | 1 | `main` | No | Direct after Human-Verified |
| S | 2 | `main` | No | Direct after Human-Verified |
| M | 3 | `main` | No | Direct after Human-Verified |
| L | 5 | `staging` | Yes | After Staging-Verified |
| XL | 8+ | `staging` | Yes | After Staging-Verified |

**Critical Rules:**
- Builder **rebases on `main`** before creating any PR
- **TPM is the ONLY agent that merges to `main`**
- After production deploy (L/XL): TPM rebases `staging` on `main`

---

## Branch-Based Deployment

| Branch | Deploys To | Stripe Mode |
|--------|------------|-------------|
| PR branch | Vercel Preview (auto) | TEST |
| `staging` | Railway Staging + Vercel Staging | TEST |
| `main` | Railway Production + Vercel Production | LIVE |

---

## Quick Reference

| Task | Command | Agent |
|------|---------|-------|
| **Plan project** | `/tpm <description>` | TPM |
| **Sync & ship** | `/tpm sync` | TPM |
| **Start any issue** | `/workon YAR-XXX` | Orchestrator |
| Elaborate requirements | `/pm <description>` | PM |
| Implement feature | `/builder YAR-XXX` | Builder |
| Test a PR | `/tester YAR-XXX` | Tester |
| PM validation | `/pm validate YAR-XXX` | PM |
| Service health | `/admin health` | Admin |
| Usage stats | `/admin stats` | Admin |

---

## Safety Rules

### NEVER:
1. **Any agent other than TPM** merges to `main`
2. Skip PM validation (all sizes require PM-Validated before Human-Verified)
3. Auto-fix production issues
4. Run DELETE/UPDATE on production database without confirmation
5. Merge multiple PRs without completing full cycle for each

### ALWAYS:
1. TPM is the sole merger to `main`
2. Run health checks before/after deployments
3. Document all actions in Linear
4. Wait for each deployment to complete before next
5. Have rollback ready (`git revert HEAD`)
6. Rebase `staging` on `main` after every production deploy
7. Complete full validation cycle per merge

---

## Related Documentation

- [protocol.md](./protocol.md) - Agent communication protocol
- [EPIC_REGISTRY.md](./EPIC_REGISTRY.md) - Epic/CUJ canonical list
- [MANUAL_TESTING_GUIDE.md](./MANUAL_TESTING_GUIDE.md) - Manual test procedures
