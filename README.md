# Multi-Agent Workflow (MAW) v5

A reusable multi-agent CI/CD framework for **Claude Code + Conductor**. Five specialized AI agents coordinate via Linear labels to drive features from intake through production with minimal human intervention.

Battle-tested on a production SaaS application (Yarda AI -- AI-powered landscape design studio).

---

## Pipeline

```
/workon {{ISSUE_PREFIX}}-XXX (continuous, workspace-scoped)
 PM -> Builder -> Deploy + Smoke -> Tester (E2E + code review + Chrome CUJ) -> Locally-Tested
                                                                                    |
                 XS/S: auto-adds Human-Verified (no human gate)                     |
                 M+: human verifies external-system items, adds Human-Verified      |
                                                                                    v
/tpm sync (global, detects Human-Verified)
 Merge PR to main -> Wait 5 min -> Prod smoke test -> In-Production
```

---

## Key Features

| Feature | Description |
|---------|-------------|
| **Two-Phase Orchestration** | `/workon` drives intake-to-tested; `/tpm sync` ships to production |
| **Size-Based Automation** | XS/S auto-ship with no human gate; M+ require human verification of external-system items only |
| **Linear-Native State Machine** | All workflow state tracked via Linear labels -- agents are stateless |
| **Workspace-Scoped** | Each Conductor workspace handles exactly one issue; no cross-workspace awareness |
| **Browser-Verified** | Chrome CUJ verification via `mcp__claude-in-chrome__*` tools before marking tested |
| **Code Review Built-In** | Tester reviews PR diff with `GetWorkspaceDiff` + `DiffComment`; CRITICAL/HIGH findings block merge |
| **Auto-Fix Loop** | Test failures auto-spawn Builder to fix, then re-invoke Tester (max 2 retries before escalation) |
| **Rollback-Ready** | TPM keeps `git revert HEAD` ready; failed prod smoke tests trigger automatic rollback |

---

## Architecture

### Agents

| Agent | Command | Responsibility | Merges to main? |
|-------|---------|----------------|-----------------|
| **PM** | `/pm` | Elaborate requirements, create Linear issues, set size/epic/CUJs | No |
| **Builder** | `/builder` | Implement feature, write E2E tests, create PR (rebased on `main`) | No |
| **Tester** | `/tester` | E2E tests, code review, Chrome CUJ verification, human checklist | No |
| **TPM** | `/tpm` | Project planning, wave execution, **sole merge authority to `main`**, auto-shipping | **YES (sole agent)** |
| **Admin** | `/admin` | Ops-only: health checks, deployment status, database queries | No |

### Label State Machine

```
PR-Ready -> Testing -> Tests-Passed -> Locally-Tested -> Human-Verified -> In-Production
                |                       (Chrome CUJ)     (human/auto)      (TPM merges)
                v
           Tests-Failed (back to Builder)
```

**Staging-Required Flow (XL + `staging-required`):**
```
PR #1->staging -> Testing -> Tests-Passed -> Staging-Tested -> Human-Verified
                                                                     |
                                                              TPM creates PR #2 -> main
                                                                     |
                                                              TPM merges -> Prod Smoke -> In-Production
                                                                     |
                                                              TPM rebases staging on main
```

---

## Size-Based Deployment Policy

| Size | Points | PR Target | Human Gate | Deployment |
|------|--------|-----------|------------|------------|
| XS | 1 | `main` | None (auto-ship) | Direct to production |
| S | 2 | `main` | None (auto-ship) | Direct to production |
| M | 3 | `main` | Human verifies external items | Direct to production |
| L | 5 | `main` | Human verifies external items | Direct to production |
| XL | 8+ | `main` (or `staging` if `staging-required`) | Human verifies external items | Direct or via staging |

**`staging-required`** is set by PM when an XL issue modifies 3+ existing user-facing files AND touches auth/payments/core features/shared UI.

---

## Quick Start

### 1. Copy files to your project

```bash
# Copy commands
mkdir -p .claude/commands
cp commands/*.md .claude/commands/

# Copy skills
mkdir -p .claude/skills
cp -r skills/* .claude/skills/
```

### 2. Customize placeholders

Find and replace these placeholders in all files:

| Placeholder | Replace With | Example |
|-------------|-------------|---------|
| `{{TEAM_NAME}}` | Your Linear team name | `MyApp` |
| `{{ISSUE_PREFIX}}` | Your Linear issue prefix | `APP` |
| `{{PRODUCTION_URL}}` | Production frontend URL | `myapp.com` |
| `{{STAGING_URL}}` | Staging frontend URL | `staging.myapp.com` |
| `{{BACKEND_PROD_URL}}` | Production backend URL | `api.myapp.com` |
| `{{BACKEND_STAGING_URL}}` | Staging backend API URL | `staging-api.myapp.com` |
| `{{EPIC_LIST}}` | Your project epics | `epic:auth, epic:billing, epic:core` |
| `{{TEST_USER_EMAIL}}` | E2E test user email | `test+e2e@myapp.com` |
| `{{TEST_USER_PASSWORD}}` | E2E test user password | `testpass123` |

### 3. Set up Linear labels

Create these labels in your Linear team:

**Workflow Labels:**
- `PR-Ready` (Blue) -- Builder sets when PR is created
- `Testing` (Yellow) -- Tester sets when actively testing
- `Tests-Passed` (Green) -- Tester sets when automated E2E tests pass
- `Tests-Failed` (Red) -- Tester sets when failures found
- `Locally-Tested` (Teal) -- Tester sets after automated + Chrome CUJ verification pass (default path)
- `Staging-Tested` (Teal) -- Tester sets after staging verification (staging-required path)
- `Human-Verified` (Orange) -- Human sets after external-system verification (or auto-set for XS/S)
- `Prod-Smoke-Passed` (Gray) -- TPM sets after production smoke tests pass
- `In-Production` (Gray) -- TPM sets when live in production

**Size Labels:**
- `XS` (1 pt), `S` (2 pt), `M` (3 pt), `L` (5 pt), `XL` (8 pt)

**Epic Labels** (customize for your project):
- `epic:auth`, `epic:billing`, `epic:core`, `epic:admin`, etc.

**Optional Labels:**
- `staging-required` -- PM sets on XL issues that need staging validation
- `PM-Validated` -- PM sets after optional user-perspective validation
- `Builder-Ready` -- PM sets when requirements are clear

### 4. Add MAW section to your CLAUDE.md

```markdown
## Multi-Agent Workflow (MAW)

**MANDATORY:** All development MUST use MAW. No development outside MAW except production hotfixes.

### Quick Start: `/workon {{ISSUE_PREFIX}}-XXX`

### Agent Roles

| Agent | Role | Invoked By |
|-------|------|------------|
| **PM** | Elaborate requirements, set size, create test plan | `/workon` or `/pm` |
| **Builder** | Implement feature, create PR | `/workon` or `/builder` |
| **Tester** | Run E2E tests, code review, Chrome CUJ verification | `/workon` or `/tester` |
| **TPM** | Merge to main, production deployment | `/tpm sync` |

### Deployment Policy

| Size | Path |
|------|------|
| XS/S (1-2 pts) | PR -> `main`, auto-ships (no human gate) |
| M/L (3-5 pts) | PR -> `main`, human verification required |
| XL (8+ pts) | PR -> `main` (or `staging` if `staging-required`), human verification required |
```

---

## Prerequisites

| Tool | Purpose |
|------|---------|
| [Claude Code](https://claude.ai/code) | AI coding agent |
| [Conductor](https://conductor.dev) | Multi-workspace orchestration |
| [Linear](https://linear.app) | Issue tracking and workflow state |
| [GitHub](https://github.com) | Source control, PRs, code review |
| Chrome + Claude-in-Chrome extension | Browser automation for CUJ verification |

### MCP Tools

| MCP Server | Purpose |
|------------|---------|
| **Linear** (`mcp__linear__*`) | Issue tracking, labels, comments, workflow state |
| **GitHub** (`gh` CLI) | PRs, code review, merges |
| **Claude-in-Chrome** (`mcp__claude-in-chrome__*`) | Browser automation for Chrome CUJ verification |
| **Conductor** (`mcp__conductor__*`) | `GetWorkspaceDiff`, `DiffComment`, `AskUserQuestion` |

Optional (project-specific):
| MCP Server | Purpose |
|------------|---------|
| **Railway** | Backend deployment (if using Railway) |
| **Vercel** | Frontend deployment (if using Vercel) |
| **Supabase** | Database queries (if using Supabase) |

---

## Project Structure

```
Multi-Agent-Workflow/
+-- README.md                    # This file
+-- docs/
|   +-- sop.md                   # Standard Operating Procedure (main reference)
|   +-- protocol.md              # Agent communication protocol
|   +-- EPIC_REGISTRY.md         # Epic/CUJ registry template
|   +-- MANUAL_TESTING_GUIDE.md  # Manual testing guide template
|   +-- MULTI_AGENT_WORKFLOW.md  # Redirect to sop.md
+-- commands/
|   +-- README.md                # Commands quick reference
|   +-- workon.md                # Orchestrator (per-issue entry point)
|   +-- pm.md                    # PM agent workflow
|   +-- builder.md               # Builder agent workflow
|   +-- tester.md                # Tester agent workflow
|   +-- tpm.md                   # TPM agent (project orchestrator + auto-shipper)
|   +-- admin.md                 # Admin agent (ops-only)
+-- skills/
|   +-- README.md                # Skills overview
+-- templates/
    +-- test-plan-template.md    # Test plan template for features
```

---

## Safety Rules

### NEVER:
1. **Merge to `main` unless you are the TPM agent** -- TPM is the sole merge authority
2. Do bulk `staging` -> `main` merges -- each feature gets its own PR to `main`
3. Deploy to production without `Human-Verified` label
4. Skip smoke tests after any deployment
5. Auto-fix production issues
6. Run destructive database operations without confirmation
7. Create a PR without rebasing feature branch on `main` first

### ALWAYS:
1. **Rebase feature branch on `main`** before creating any PR
2. **Wait for deployments to finish** before running smoke tests
3. **Run smoke tests after every deployment** -- staging and production
4. Run health checks before/after deployments
5. Document actions in Linear
6. Have rollback command ready (`git revert HEAD`)
7. TPM rebases `staging` on `main` after production deploy (staging-required only)
8. Builder writes E2E tests for S+ features
9. Tester performs code review before Chrome CUJ verification

---

## License

MIT

---

## Related Projects

- [Claude Code](https://claude.ai/code) -- Anthropic's CLI for Claude
- [Linear](https://linear.app) -- Issue tracking
