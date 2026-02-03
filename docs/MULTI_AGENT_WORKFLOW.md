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

**Responsibilities:**
- Elaborate raw requirements into comprehensive specs
- Determine appropriate epic (`epic:auth`, `epic:generation`, etc.)
- Assign T-shirt size (XS/S/M/L/XL) with points
- Define CUJs (Critical User Journeys)
- Create test plans for M+ sized issues
- Create well-structured Linear issues
- Maintain EPIC_REGISTRY.md and MANUAL_TESTING_GUIDE.md

**Triggers:**
- `/pm` - Interactive requirements elaboration session
- `/pm <description>` - Elaborate specific feature from description

**Outputs:**
- Linear issue with:
  - Epic label (`epic:<name>`)
  - Size label and estimate (XS=1, S=2, M=3, L=5, XL=8)
  - Acceptance criteria (checkboxes)
  - CUJ references
  - Test plan (for M+ sizes)
- Updated EPIC_REGISTRY.md (if new CUJs)

---

### 2. Builder Agent (`/builder`)

**Role:** Feature development and implementation

**Responsibilities:**
- Pick up Linear issues with specs from PM
- Research codebase and existing patterns
- Implement features on feature branch
- Write unit tests
- Run pre-commit validation
- Create pull request targeting staging (L/XL) or main (XS/S/M)
- Handle test feedback from Tester

**Triggers:**
- `/builder` - Auto-pickup highest priority "Todo" issue
- `/builder YAR-5` - Work on specific issue

**Outputs:**
- Feature branch with implementation
- `specs/<number>-<name>/spec.md` with CUJs
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

## Linear Label State Machine

Labels track the state of each issue through the workflow:

```
                    ┌─────────────────────────────────────────┐
                    │                                         │
                    ▼                                         │
┌──────────┐   ┌──────────┐   ┌─────────────┐   ┌──────────────┐
│ PR-Ready │──▶│ Testing  │──▶│Tests-Passed │──▶│ On-Staging   │
└──────────┘   └──────────┘   └─────────────┘   └──────────────┘
     │              │                                  │
     │              ▼                                  ▼
     │         ┌─────────────┐              ┌─────────────────┐
     │         │Tests-Failed │              │Staging-Verified │
     │         └─────────────┘              └─────────────────┘
     │              │                                  │
     │              │                                  ▼
     │              │                       ┌──────────────────┐
     └──────────────┘                       │ Human-Verified   │
           (back to Builder)                └──────────────────┘
                                                       │
                                                       ▼
                                            ┌─────────────────┐
                                            │  In-Production  │
                                            └─────────────────┘
```

| Label | Color | Set By | Meaning |
|-------|-------|--------|---------|
| `PR-Ready` | Blue #2196F3 | Builder | PR created, ready for testing |
| `Testing` | Yellow #FFC107 | Tester | Tester actively testing |
| `Tests-Passed` | Green #4CAF50 | Tester | All tests passed |
| `Tests-Failed` | Red #F44336 | Tester | Failures found, back to Builder |
| `On-Staging` | Purple #9C27B0 | Admin | Deployed to staging |
| `Staging-Verified` | Light Green #8BC34A | Tester | Staging E2E passed |
| `Human-Verified` | Orange #FF9800 | Human | Human approved, ready for production |
| `In-Production` | Gray #607D8B | Admin | Live in production |

---

## Workflow Scenarios

### Happy Path

1. **Builder** picks up YAR-5 from "Todo"
2. **Builder** researches, implements, creates PR
3. **Builder** adds "PR-Ready" label, signals Tester
4. **Tester** runs E2E tests, all pass
5. **Tester** adds "Tests-Passed" label, signals Admin
6. **Admin** reviews, deploys to staging
7. **Admin** adds "On-Staging" label, signals Tester
8. **Tester** runs staging E2E, passes
9. **Tester** adds "Staging-Verified" label
10. **Admin** requests human approval
11. **Human** approves
12. **Admin** deploys to production
13. **Admin** marks "Done" with "In-Production"

### Test Failure Scenario

1. **Builder** creates PR with "PR-Ready"
2. **Tester** runs tests, 2 failures found
3. **Tester** creates sub-issues YAR-5-bug-1, YAR-5-bug-2
4. **Tester** removes "PR-Ready", adds "Tests-Failed"
5. **Builder** receives feedback, fixes bugs
6. **Builder** pushes fixes, re-adds "PR-Ready"
7. **Tester** re-tests, all pass
8. Flow continues to Admin...

### Staging Failure Scenario

1. **Admin** deploys to staging
2. **Tester** runs staging E2E, failures found
3. **Tester** removes "On-Staging", adds "Tests-Failed"
4. **Builder** fixes, **Tester** re-tests
5. **Admin** re-deploys to staging
6. Flow continues...

---

## Quick Reference Commands

| Command | Agent | Description |
|---------|-------|-------------|
| `/pm` | PM | Elaborate requirements, create issues |
| `/pm <desc>` | PM | Elaborate specific feature |
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
