# Multi-Agent Development Workflow

This document describes the 4-agent CI/CD workflow for Yarda v5 development.

## Overview

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                          MULTI-AGENT WORKFLOW                                     │
├──────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  Raw Requirement                                                                 │
│       │                                                                          │
│       ▼                                                                          │
│  ┌─────────────┐  Issue Ready  ┌─────────────┐  PR-Ready  ┌─────────────┐       │
│  │     PM      │ ─────────────▶│   BUILDER   │ ─────────▶│   TESTER    │       │
│  │   Agent     │               │   Agent     │            │   Agent     │       │
│  │             │               │             │            │             │       │
│  │ • Elaborate │               │ • Research  │ ◀────────  │ • E2E tests │       │
│  │ • Size      │               │ • Implement │ Tests-     │ • Reports   │       │
│  │ • Epic/CUJ  │               │ • Unit test │ Failed     │ • Browser   │       │
│  │ • Test plan │               │ • Create PR │            │   automation│       │
│  └─────────────┘               └─────────────┘            └─────────────┘       │
│                                                                  │              │
│                                                     Tests-Passed │              │
│                                                                  ▼              │
│                                                          ┌─────────────┐        │
│                                                          │   ADMIN     │        │
│                                                          │   Agent     │        │
│                                                          │             │        │
│                                                          │ • Deploy    │        │
│                                                          │ • Monitor   │        │
│                                                          │ • Merge     │        │
│                                                          └─────────────┘        │
│                                                                  │              │
│                                                                  ▼              │
│                                                         ┌─────────────────┐     │
│                                                         │   PRODUCTION    │     │
│                                                         │ (Human Approval)│     │
│                                                         └─────────────────┘     │
│                                                                                  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

## Agents

### 1. PM Agent (`/pm`)

**Role:** Requirements elaboration and issue creation

**Responsibilities (Start of Flow):**
- Elaborate raw requirements into comprehensive specs
- Determine appropriate epic (`epic:auth`, `epic:generation`, etc.)
- Assign T-shirt size (XS/S/M/L/XL) with points
- Define CUJs (Critical User Journeys)
- Create test plans for M+ sized issues
- Create well-structured Linear issues
- Maintain EPIC_REGISTRY.md and MANUAL_TESTING_GUIDE.md

**Responsibilities (Pre-Human Validation):**
- Validate features on **PR Preview** as a **real user** using browser
- Walk through each CUJ on PR Preview environment (Vercel preview + staging backend)
- Verify acceptance criteria are met from user perspective
- Recommend for human sign-off or signal Builder for fixes

**Environment:** PR Preview (validation happens BEFORE staging deployment)

**Triggers:**
- `/pm` - Interactive requirements elaboration session
- `/pm <description>` - Elaborate specific feature from description
- `/pm validate YAR-XXX` - Pre-human validation of deployed feature

**Outputs (Requirements):**
- Linear issue with:
  - Epic label (`epic:<name>`)
  - Size label and estimate (XS=1, S=2, M=3, L=5, XL=8)
  - Acceptance criteria (checkboxes)
  - CUJ references
  - Test plan (for M+ sizes)
- Updated EPIC_REGISTRY.md (if new CUJs)

**Outputs (Validation):**
- Validation report with screenshots/GIFs
- `PM-Validated` label (if passed)
- Sub-issues for any UX problems found

---

### 2. Builder Agent (`/builder`)

**Role:** Feature development and implementation

**Responsibilities:**
- Pick up Linear issues with specs from PM
- Research codebase and existing patterns
- **L issues:** Consider SpecKit for structured specification
- **XL issues:** Use full SpecKit workflow (required)
- Implement features on feature branch
- Write unit tests
- Run pre-commit validation
- Create pull request targeting staging (L/XL) or main (XS/S/M)
- Handle test feedback from Tester

**Triggers:**
- `/builder` - Auto-pickup highest priority "Todo" issue
- `/builder YAR-5` - Work on specific issue
- `/speckit.specify` → `/speckit.clarify` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement` (L: optional, XL: required)

**Outputs:**
- Feature branch with implementation
- `specs/<number>-<name>/spec.md` with CUJs
- SpecKit artifacts (for L/XL): `spec.md`, `plan.md`, `tasks.md`
- Unit tests
- Pull request with test plan
- Linear issue updated with "PR-Ready" label

---

### 3. Tester Agent (`/tester`)

**Role:** Automated testing and quality assurance

**Responsibilities:**
- Pick up PRs labeled "PR-Ready"
- Run full E2E test suite
- Execute CUJs from spec
- Perform visual verification
- Check accessibility
- Report failures as sub-issues
- Verify staging deployments

**Execution Environments:**
- **Local:** Claude Code with **agent-browser MCP** (preferred) or Playwright MCP (fallback)
- **CI:** Google Antigravity with Gemini 3 (browser automation)

**Triggers:**
- `/tester` - Auto-pickup oldest "PR-Ready" issue
- `/tester YAR-5` - Test specific issue

**Outputs:**
- Test reports with screenshots
- Sub-issues for any failures
- "Tests-Passed" or "Tests-Failed" label
- Staging verification ("Staging-Verified" label)

---

### 4. Admin Agent (`/admin`)

**Role:** Deployment and production management

**Responsibilities:**
- Review PRs with "Tests-Passed" label
- Validate against DEVOPS_CHECKLIST
- Deploy to staging
- Coordinate staging E2E with Tester
- Request human approval for production
- Execute production deployment
- Monitor health checks

**Command Modes:**
- `/admin` - Review all ready PRs, deploy to staging
- `/admin review` - Review PRs without deploying
- `/admin stage YAR-5` - Deploy specific issue to staging
- `/admin promote YAR-5` - Promote staging to production
- `/admin status` - Show current deployment status
- `/admin health` - Check all service health

**Outputs:**
- Staging deployments
- Production deployments (with human approval)
- Linear issue updated to "Done" with "In-Production" label
- Deployment verification comments

---

## Environments

| Environment | Frontend URL | Backend URL | Purpose |
|-------------|--------------|-------------|---------|
| **PR Preview** | `yarda-v5-frontend-*.vercel.app` | `yardav5-staging-b19c.up.railway.app` | Per-PR testing, PM validation, human verification |
| **Staging** | `staging.yarda.ai` | `yardav5-staging-b19c.up.railway.app` | L/XL staging verification after merge |
| **Production** | `yarda.pro` | `yardav5-production.up.railway.app` | Live production |

---

## Linear Label State Machine

Labels track the state of each issue through the workflow.

### XS/S/M Flow (Direct to Production)
```
PR-Ready → Testing → Tests-Passed → PM-Validated → Human-Verified → In-Production
[PR Prev]  [PR Prev]  [PR Preview]   [PR Preview]   [PR Preview]    [Production]
```

### L/XL Flow (Via Staging)
```
PR-Ready → Testing → Tests-Passed → PM-Validated → Human-Verified → On-Staging → Staging-Verified → In-Production
[PR Prev]  [PR Prev]  [PR Preview]   [PR Preview]   [PR Preview]    [Staging]    [Staging]          [Production]
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
| `PR-Ready` | Blue #2196F3 | Builder | PR Preview | PR created, ready for testing |
| `Testing` | Yellow #FFC107 | Tester | PR Preview | Tester actively testing |
| `Tests-Passed` | Green #4CAF50 | Tester | PR Preview | All tests passed |
| `Tests-Failed` | Red #F44336 | Tester | Any | Failures found, back to Builder |
| `PM-Validated` | Teal #009688 | PM | PR Preview | PM validated as real user |
| `Human-Verified` | Orange #FF9800 | Human | PR Preview | Human approved |
| `On-Staging` | Purple #9C27B0 | Admin | Staging | Deployed to staging (L/XL only) |
| `Staging-Verified` | Light Green #8BC34A | Tester | Staging | Staging E2E passed (L/XL only) |
| `In-Production` | Gray #607D8B | Admin | Production | Live in production |

---

## Workflow Scenarios

### Happy Path - XS/S/M (Direct to Production)

| Step | Agent | Action | Environment |
|------|-------|--------|-------------|
| 1 | **PM** | Creates issue with epic, size, CUJs, test plan | - |
| 2 | **Builder** | Picks up YAR-5, implements, creates PR | localhost:3000 |
| 3 | **Builder** | Adds "PR-Ready" label, signals Tester | - |
| 4 | **Tester** | Runs E2E tests, all pass | PR Preview |
| 5 | **Tester** | Adds "Tests-Passed" label | PR Preview |
| 6 | **PM** | Validates as real user, adds "PM-Validated" | PR Preview |
| 7 | **Human** | Approves, adds "Human-Verified" | PR Preview |
| 8 | **Admin** | Merges to main, deploys | Production |
| 9 | **Admin** | Marks "Done" with "In-Production" | Production |

### Happy Path - L/XL (Via Staging)

| Step | Agent | Action | Environment |
|------|-------|--------|-------------|
| 1 | **PM** | Creates issue with epic, size, CUJs, test plan | - |
| 2 | **Builder** | Runs SpecKit workflow (L: recommended, XL: required) | localhost:3000 |
| 3 | **Builder** | Implements feature, creates PR | localhost:3000 |
| 4 | **Builder** | Adds "PR-Ready" label, signals Tester | - |
| 5 | **Tester** | Runs E2E tests, all pass | PR Preview |
| 6 | **Tester** | Adds "Tests-Passed" label | PR Preview |
| 7 | **PM** | Validates as real user, adds "PM-Validated" | PR Preview |
| 8 | **Human** | Approves, adds "Human-Verified" | PR Preview |
| 9 | **Admin** | Merges to staging, adds "On-Staging" | Staging |
| 10 | **Tester** | Runs staging E2E, adds "Staging-Verified" | Staging |
| 11 | **Admin** | Promotes staging → main | Production |
| 12 | **Admin** | Marks "Done" with "In-Production" | Production |

### Test Failure Scenario

| Step | Action | Environment |
|------|--------|-------------|
| 1 | **Builder** creates PR with "PR-Ready" | PR Preview created |
| 2 | **Tester** runs tests, 2 failures found | PR Preview |
| 3 | **Tester** creates sub-issues, adds "Tests-Failed" | - |
| 4 | **Builder** fixes bugs, pushes to PR | localhost |
| 5 | **Builder** re-adds "PR-Ready" | - |
| 6 | **Tester** re-tests, all pass | PR Preview |
| 7 | Flow continues to PM validation... | PR Preview |

### PM Validation Failure Scenario

| Step | Action | Environment |
|------|--------|-------------|
| 1 | **PM** validates feature as real user | PR Preview |
| 2 | **PM** finds UX issues or unmet criteria | PR Preview |
| 3 | **PM** creates sub-issues, removes "Tests-Passed" | - |
| 4 | **Builder** fixes issues | localhost |
| 5 | **Tester** re-runs tests | PR Preview |
| 6 | **PM** re-validates, adds "PM-Validated" | PR Preview |
| 7 | Flow continues to human verification... | PR Preview |

### Staging Failure Scenario (L/XL only)

| Step | Action | Environment |
|------|--------|-------------|
| 1 | **Admin** deploys to staging | Staging |
| 2 | **Tester** runs staging E2E, failures found | Staging |
| 3 | **Tester** removes "On-Staging", adds "Tests-Failed" | - |
| 4 | **Builder** fixes, pushes to PR | localhost |
| 5 | Workflow restarts from PR testing | PR Preview |

---

## Quick Reference Commands

| Command | Agent | Description |
|---------|-------|-------------|
| `/pm` | PM | Elaborate requirements, create issues |
| `/pm <desc>` | PM | Elaborate specific feature |
| `/pm validate YAR-5` | PM | Pre-human validation of deployed feature |
| `/builder` | Builder | Auto-pickup highest priority issue |
| `/builder YAR-5` | Builder | Work on specific issue |
| `/tester` | Tester | Auto-pickup oldest PR-Ready issue |
| `/tester YAR-5` | Tester | Test specific issue |
| `/tester staging YAR-5` | Tester | Test staging deployment |
| `/admin` | Admin | Review and deploy all ready PRs |
| `/admin stage YAR-5` | Admin | Deploy specific issue to staging |
| `/admin promote YAR-5` | Admin | Promote to production |

---

## Integration Points

### MCP Tools Used

**Linear Integration:**
- `mcp__plugin_linear_linear__get_issue` - Fetch issue details
- `mcp__plugin_linear_linear__list_issues` - Query issues by label
- `mcp__plugin_linear_linear__update_issue` - Update status/labels
- `mcp__plugin_linear_linear__create_comment` - Add handoff comments
- `mcp__plugin_linear_linear__create_issue` - Create bug sub-issues

**GitHub Integration:**
- `mcp__github__create_pull_request` - Create PRs
- `mcp__github__pull_request_read` - Read PR details, **get PR comments for backend URL**
- `mcp__github__merge_pull_request` - Merge to main
- `mcp__github__add_issue_comment` - Add test results

**Agent-Browser Testing (Preferred):**
- `mcp__agent_browser__navigate` - Navigate to pages
- `mcp__agent_browser__click` - Interact with elements (supports semantic locators)
- `mcp__agent_browser__fill` - Fill form fields
- `mcp__agent_browser__snapshot` - Capture accessibility tree with refs
- `mcp__agent_browser__screenshot` - Visual verification
- `mcp__agent_browser__get_console` - Check for errors

**Playwright Browser Testing (Fallback):**
- `mcp__playwright__browser_navigate` - Navigate to pages
- `mcp__playwright__browser_click` - Interact with elements
- `mcp__playwright__browser_snapshot` - Capture accessibility tree
- `mcp__playwright__browser_take_screenshot` - Visual verification
- `mcp__playwright__browser_console_messages` - Check for errors

**Vercel Deployment:**
- `mcp__vercel__list_deployments` - Monitor deployments
- `mcp__vercel__get_access_to_vercel_url` - Access protected previews

**Railway Deployment:**
- `mcp__railway-mcp-server__deploy` - Deploy to environment
- `mcp__railway-mcp-server__create-environment` - **Create PR environments**
- `mcp__railway-mcp-server__list_deployments` - Monitor status
- `mcp__railway-mcp-server__get_logs` - Debug failures

**Stitch UI Generation:**
- `mcp__stitch__list_projects` - List Stitch projects
- `mcp__stitch__list_screens` - Get screens in a project
- `mcp__stitch__get_screen` - Get screen details (HTML, screenshot)
- `mcp__stitch__get_project` - Get project design theme

**Stitch Skills:**
- `/design-md` - Analyze Stitch projects → generate `DESIGN.md`
- `/reactcomponents` - Convert Stitch designs → React components
- `/stitch-loop` - Iterative UI building workflow

### PR Environments (MCP-Based)

Each PR can get its own isolated Railway backend environment via MCP tools:

```
PR Created → Builder/Admin creates Railway env via MCP:
             mcp__railway-mcp-server__create-environment
             - environmentName: "pr-{number}"
             - duplicateEnvironment: "staging"
          → Deploys backend to PR environment:
             mcp__railway-mcp-server__deploy
             - environment: "pr-{number}"
          → Posts comment on PR with backend URL

Tester    → Reads PR comment for backend URL
          → Tests localhost:3000 + PR backend (isolated!)

PR Merged → Builder/Admin deletes Railway env via MCP:
            railway environment delete pr-{number} --yes
```

**MCP Commands for PR Environments:**
```python
# Create PR environment (duplicate from staging)
mcp__railway-mcp-server__create-environment(
    workspacePath="/path/to/backend",
    environmentName="pr-35",
    duplicateEnvironment="staging"
)

# Deploy to PR environment
mcp__railway-mcp-server__deploy(
    workspacePath="/path/to/backend",
    environment="pr-35"
)

# Set CORS for localhost testing
mcp__railway-mcp-server__set-variables(
    workspacePath="/path/to/backend",
    environment="pr-35",
    variables=["CORS_ORIGINS=http://localhost:3000"]
)
```

**Benefits:**
- ✅ Each PR tested in complete isolation
- ✅ No interference between developers
- ✅ Backend and frontend versions always match
- ✅ No GitHub Actions billing required (uses Railway MCP)

---

## Configuration

### Pre-commit Hooks

Both frontend and backend have pre-commit validation:

**Frontend (lint-staged):**
- ESLint auto-fix
- Prettier formatting

**Backend (Ruff):**
- `ruff check --fix src/`
- `ruff format src/`

### CI Quality Gates

GitHub Actions enforces:
- Frontend: ESLint, TypeScript type-check, build
- Backend: Ruff linter, mypy, pytest
- E2E: Playwright smoke tests on PRs

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Builder can't find issues | Check Linear team filter, verify "Todo" state |
| Tester timeout | Increase Playwright timeout, check network |
| Staging deploy fails | Check Railway logs, verify env vars |
| Label not updating | Check Linear API permissions |
| Tests flaky | Add retry logic, check for race conditions |

---

## Related Documentation

- [DEVOPS_PROCESS.md](DEVOPS_PROCESS.md) - CI/CD pipeline details
- [DEVOPS_CHECKLIST.md](DEVOPS_CHECKLIST.md) - Pre-deployment checklist
- [TESTING_STRATEGY.md](TESTING_STRATEGY.md) - Testing approach
- [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md) - All slash commands
