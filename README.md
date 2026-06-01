# Multi-Agent Workflow (MAW) v6

An autonomous development pipeline driven by Linear issues. Agents pick up work, develop, test, pass CI, and produce PRs ready for review -- no human dispatch required. After merge, changes flow through staging to production, with OTA update support for decentralized deployments.

## How It Works

A human or PM agent creates issues in Linear. From there, the pipeline is autonomous:

```
Linear Issue (Backlog / Todo)
  |
  v
Agent Pickup (In Progress)
  |-- PM elaboration (if scope is unclear)
  |-- Builder implementation
  |     |-- Architect phase (plan changes, model: opus)
  |     +-- Editor phase (apply changes, model: sonnet)
  |
  v
Automated CI (GitHub Actions)
  |-- Typecheck, lint, unit tests, build
  |
  v
Tester Verification
  |-- Code review
  |-- E2E tests
  +-- Chrome CUJ verification (if UI-touching)
  |
  v
PR Ready for Review
  |-- Agent review (code-reviewer) OR human review
  |
  v
Merge to main
  |-- Auto-deploy to staging
  |-- Staging smoke tests
  |-- Promote to production (manual gate, or auto for XS/S)
  +-- OTA update push to decentralized instances
```

## Design Principles

1. **Linear is the single source of truth.** All pipeline state lives in Linear labels and structured attachments. No shadow databases, no local state files.
2. **Autonomous pickup.** Agents watch for ready issues and claim them. No human needed to dispatch work.
3. **Multi-runtime.** Works from Claude Code CLI, Claude Code desktop, Contractor (cloud agent), or any MCP-capable AI coding tool.
4. **CI/CD native.** GitHub Actions handles testing, building, and deploying. Agents trigger pipelines; they do not replace them.
5. **Review is a separate gate.** PRs are created and CI passes before any review happens. Review is performed by an agent (code-reviewer) or a human -- never by the builder who wrote the code.
6. **Staging before production.** Every change validates in staging before reaching users.
7. **OTA updates for decentralized deployments.** Edge instances (Mac minis, VPS, client servers) pull updates from production on a configurable interval.
8. **Structured handoffs.** Agents communicate through JSON schemas stored as Linear attachments. No free-text parsing between pipeline stages.

## Agent Roles

| Agent | Role | Merges? |
|-------|------|---------|
| **Orchestrator** | Routes issues through the pipeline | No |
| **PM** | Elaborates requirements, sizes issues, writes acceptance criteria | No |
| **Builder** | Implements features and fixes (architect/editor split) | No |
| **Tester** | Runs tests, performs code review, verifies CUJs | No |
| **Reviewer** | Independent code review (separate from tester) | No |
| **TPM** | Ships verified PRs, manages staging-to-production promotion | **Yes -- sole merge authority** |
| **Admin** | Deployment management, health checks, OTA coordination | No |

Only the TPM merges. This is enforced by convention and branch protection rules. Every other agent produces artifacts (PRs, test reports, review comments) but never merges.

## Commands

### Development

| Command | Description |
|---------|-------------|
| `/workon <ISSUE>` | Drive a specific issue through the full pipeline |
| `/pm <description>` | Create or elaborate requirements for an issue |
| `/builder` | Auto-pickup the highest priority ready issue |
| `/builder <ISSUE>` | Implement a specific issue |
| `/tester <ISSUE>` | Run test suite and verification for an issue |
| `/reviewer <ISSUE>` | Perform independent code review on a PR |

### Shipping

| Command | Description |
|---------|-------------|
| `/tpm sync` | Ship all reviewed and verified issues |
| `/tpm promote` | Promote staging to production |
| `/tpm ota-status` | Check OTA update status across all instances |

### Operations

| Command | Description |
|---------|-------------|
| `/admin health` | Run service health checks |
| `/admin deploy <env>` | Deploy to a specific environment |

## Environments

| Environment | Purpose | Deploy Trigger |
|-------------|---------|----------------|
| **Development** | Local dev server | Manual (`pnpm dev`) |
| **CI** | Automated testing | PR push to GitHub |
| **Staging** | Pre-production validation | Merge to `main` |
| **Production** | Live users | Manual promote or auto (XS/S issues) |
| **Edge instances** | Client Mac minis, VPS, self-hosted | OTA pull from production |

## Decentralized Deployment and OTA Updates

MAW v6 supports decentralized deployment to infrastructure you do not centrally control:

- **Mac minis** at client sites
- **VPS** instances (DigitalOcean, Hetzner, etc.)
- **Cloud** deployments (Railway, Fly.io, AWS)
- **Self-hosted** on client-managed servers

### OTA Update Flow

OTA uses a pull-based model. Edge instances are never pushed to directly.

1. **Tag and publish.** Production release is tagged with a version and published to the OTA registry.
2. **Poll.** Edge instances check the registry on a configurable interval (default: 5 minutes).
3. **Download and validate.** Update artifact is downloaded and verified against a checksum and cryptographic signature.
4. **Rolling restart.** New version starts alongside the old one. Health check must pass before traffic cuts over.
5. **Automatic rollback.** If the health check fails, the instance reverts to the previous version and reports the failure.

No instance is left in a broken state. Failed updates are logged and surfaced through `/tpm ota-status`.

## Quick Start

### 1. Fork and initialize

```sh
# Fork this repo, then:
git clone <your-fork>
cd maw-v6
./init.sh
```

`init.sh` prompts for project-specific values (see Setup Placeholders below) and writes them into the command templates and CI configuration.

### 2. Install commands

```sh
cp -r commands/ <your-project>/.claude/commands/
```

### 3. Configure integrations

- **Linear webhook** -- see [docs/CICD.md](docs/CICD.md) for the webhook URL and event filters.
- **GitHub Actions** -- copy and customize workflows from `ci/github-actions/`.
- **OTA registry** -- set up the update endpoint (see [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)).

### 4. Start working

```sh
# Drive a specific issue through the pipeline
/workon AGE-123

# Or let an agent auto-pickup the next ready issue
/builder
```

## Setup Placeholders

`init.sh` will prompt for each of these. They are used throughout commands, CI config, and documentation templates.

| Placeholder | Example | Description |
|-------------|---------|-------------|
| `ISSUE_PREFIX` | `AGE` | Linear team prefix for issue IDs |
| `TEAM_NAME` | `AgentDash` | Linear team name |
| `PRODUCTION_URL` | `https://app.agentdash.com` | Production URL |
| `STAGING_URL` | `https://staging.agentdash.com` | Staging URL |
| `GITHUB_REPO` | `thetangstr/agentdash` | GitHub repository (owner/repo) |
| `OTA_REGISTRY_URL` | `https://releases.agentdash.com` | OTA update registry endpoint |

## Pipeline State Machine

Issues move through Linear statuses. Labels encode additional pipeline state.

```
Backlog  -->  Todo  -->  In Progress  -->  In Review  -->  Done
                             |                |
                             |                +-- Review rejected: back to In Progress
                             |
                             +-- CI failed: stays In Progress, agent notified
```

Labels used by the pipeline:

| Label | Meaning |
|-------|---------|
| `size/xs`, `size/s`, `size/m`, `size/l`, `size/xl` | Issue size (affects auto-ship eligibility) |
| `needs-pm` | Requires PM elaboration before build |
| `needs-review` | PR is ready for review |
| `reviewed` | Review passed |
| `ci-passing` | All CI checks green |
| `staged` | Deployed to staging |
| `promoted` | Deployed to production |
| `ota-pushed` | OTA update published for edge instances |

## Structured Handoffs

Agents pass structured data between pipeline stages using JSON schemas stored as Linear issue attachments. This eliminates ambiguity and enables any runtime (CLI, desktop, cloud) to participate in the pipeline.

Schemas live in `schemas/` and cover:

- **Issue elaboration** -- PM output (acceptance criteria, scope, size estimate)
- **Build plan** -- Architect output (files to change, approach, risks)
- **Test report** -- Tester output (pass/fail, coverage, CUJ results)
- **Review verdict** -- Reviewer output (approve/request-changes, findings)
- **Deploy manifest** -- TPM output (version, environment, rollback plan)

Each schema is versioned. Agents validate payloads before writing them.

## Documentation

| Document | Purpose |
|----------|---------|
| [docs/protocol.md](docs/protocol.md) | Label state machine, structured handoff protocol |
| [docs/sop.md](docs/sop.md) | Standard operating procedures for each agent role |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Staging, production promotion, OTA update setup |
| [docs/CICD.md](docs/CICD.md) | CI/CD pipeline design and GitHub Actions config |
| [schemas/](schemas/) | JSON schemas for all handoff payloads |

## License

MIT
