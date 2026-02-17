# Multi-Agent Workflow (MAW) v4

A structured CI/CD workflow using **five specialized AI agents** that coordinate via Linear labels. Each agent runs in its own Claude Code session (Conductor workspace), with the **TPM Agent** serving as the human's single command center for orchestrating parallel development.

## Overview

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│                            MULTI-AGENT WORKFLOW v4                                  │
├────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                    │
│  Project Description                                                               │
│       │                                                                            │
│       ▼                                                                            │
│  ┌─────────────┐  Waves + Issues  ┌─────────────┐                                 │
│  │     TPM     │ ────────────────▶│  CONDUCTOR   │                                 │
│  │   Agent     │                  │  WORKSPACES  │                                 │
│  │             │                  │  (parallel)  │                                 │
│  │ • Plan      │                  └──────┬───────┘                                 │
│  │ • Waves     │                         │                                         │
│  │ • Ship      │                 Each workspace runs:                              │
│  └─────────────┘                         │                                         │
│       ▲                                  ▼                                         │
│       │                   ┌──────────────────────────┐                             │
│       │                   │      /workon YAR-XXX     │                             │
│       │                   ├──────────────────────────┤                             │
│       │                   │                          │                             │
│       │                   │  PM → Builder → Tester   │                             │
│       │                   │         │                │                             │
│       │                   │         ▼                │                             │
│       │                   │  Tests-Passed            │                             │
│       │                   │         │                │                             │
│       │                   │         ▼                │                             │
│       │                   │  PM Validation           │                             │
│       │                   │         │                │                             │
│       │                   │         ▼                │                             │
│       │                   │  Human-Verified          │                             │
│       │                   └──────────────────────────┘                             │
│       │                              │                                             │
│       │                    /tpm sync │                                              │
│       │                              ▼                                             │
│       │                   ┌──────────────────────────┐                             │
│       │                   │  TPM AUTO-SHIPS          │                             │
│       │                   │  • Merge to main         │                             │
│       │                   │  • Deploy to production  │                             │
│       │                   │  • Smoke test            │                             │
│       │                   │  • In-Production         │                             │
│       │                   └──────────────────────────┘                             │
│       │                              │                                             │
│       └──── Wave complete? ──────────┘                                             │
│              → Advance to next wave                                                │
│                                                                                    │
│  ┌─────────────┐                                                                   │
│  │   ADMIN     │  (ops-only: health, stats, DB queries)                            │
│  └─────────────┘                                                                   │
│                                                                                    │
└────────────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# TPM: Plan a project into waves of issues
/tpm <project description>

# TPM: Check status and auto-ship verified features
/tpm sync

# Per-workspace: Route issue through PM → Builder → Tester pipeline
/workon YAR-123
```

## Agents

| Agent | Command | Responsibility | Merges to main? |
|-------|---------|----------------|-----------------|
| **TPM** | `/tpm` | Project planning, wave execution, auto-shipping | **YES (sole agent)** |
| **PM** | `/pm` | Elaborate requirements, create Linear issues, pre-human validation | No |
| **Builder** | `/builder` | Research, implement, create PR, write tests | No |
| **Tester** | `/tester` | Run E2E tests, report issues, verify staging | No |
| **Admin** | `/admin` | Health checks, stats, DB queries (ops-only) | No |

## Maximally Automated Flow

```
/tpm <project>  →  TPM creates issues + wave plan + git worktrees
                          ↓
              Human opens workspaces in Conductor
                          ↓
     Each workspace: /workon YAR-XXX → PM → Builder → Tester → Tests-Passed
                          ↓
        Human verifies on staging.yarda.ai → adds Human-Verified
                          ↓
  /tpm sync → TPM auto-detects Human-Verified → merges to main → smoke tests → In-Production
                          ↓
     TPM detects wave complete → creates next worktrees → human opens them
```

**Human only does:**
1. Open workspaces TPM creates
2. Verify features on staging, add `Human-Verified` label
3. Run `/tpm sync` periodically

## Size-Based Deployment

| Size | Points | Deployment Path |
|------|--------|-----------------|
| XS/S/M | 1-3 | Single PR → `main` (direct to production) |
| L/XL | 5-8+ | PR #1 → `staging` → Human verify → PR #2 → `main` → Production |

## Linear Label State Machine

```
PR-Ready → Testing → Tests-Passed → PM-Validated → Human-Verified → In-Production
              ↓
        Tests-Failed (back to Builder)
```

| Label | Color | Set By | Meaning |
|-------|-------|--------|---------|
| `PR-Ready` | Blue | Builder | PR created, ready for testing |
| `Testing` | Yellow | Tester | Actively testing |
| `Tests-Passed` | Green | Tester | All tests passed |
| `Tests-Failed` | Red | Tester | Failures found |
| `PM-Validated` | Teal | PM | PM validated as real user |
| `Human-Verified` | Orange | Human | Ready for production |
| `In-Production` | Gray | **TPM** | Live in production |

## TPM Automation Table

What `/tpm sync` detects and does automatically:

| What TPM Detects | Automated Action | Human Needed? |
|-----------------|-----------------|---------------|
| Issue has no spec | Flag for PM elaboration | No |
| Wave ready to start | Create git worktrees | Human opens workspace |
| `PR-Ready` detected | Note in dashboard | No |
| `Tests-Passed` detected | Notify: "YAR-XXX ready for verification" | Human verifies on staging |
| `Human-Verified` detected | **Auto-merge → deploy → smoke test → In-Production** | **No** |
| All wave N shipped | Advance to wave N+1, create next worktrees | Human opens workspaces |
| `Tests-Failed` 2+ times | Flag as blocked, escalate to human | Human investigates |

## Project Structure

```
├── README.md           # This file
├── DESIGN.md           # Semantic design system for Stitch UI generation
├── docs/
│   ├── sop.md                    # Main Standard Operating Procedure
│   ├── protocol.md               # Agent communication protocol
│   ├── MULTI_AGENT_WORKFLOW.md   # Detailed workflow documentation
│   ├── EPIC_REGISTRY.md          # Epic/CUJ canonical list
│   └── MANUAL_TESTING_GUIDE.md   # Manual testing procedures
├── commands/
│   ├── tpm.md         # TPM agent (project orchestrator + auto-shipper)
│   ├── workon.md      # MAW orchestrator (per-issue entry point)
│   ├── builder.md     # Builder agent workflow
│   ├── tester.md      # Tester agent workflow
│   ├── admin.md       # Admin agent (ops-only)
│   ├── pm.md          # PM agent workflow
│   └── README.md      # Commands quick reference
├── skills/
│   └── pm-requirements/  # PM requirements elaboration skill
└── templates/
    └── test-plan-template.md  # Test plan template
```

## MCP Integrations

| MCP Server | Purpose |
|------------|---------|
| **Linear** (`mcp__linear__`) | Issue tracking, labels, workflow state |
| **GitHub** | PRs, code review, merges |
| **Railway** | Backend deployment, PR environments |
| **Vercel** | Frontend deployment, previews |
| **Supabase** | Database queries, migrations |
| **Claude-in-Chrome** | Browser automation for testing/validation |
| **Stitch** | AI-powered UI generation |

## Stitch UI Generation

MAW integrates with Google Stitch for AI-powered UI generation:

**Skills:**
- `/design-md` - Analyze Stitch projects → generate `DESIGN.md`
- `/reactcomponents` - Convert Stitch designs → React components
- `/stitch-loop` - Iterative UI building workflow

**Workflow:**
```
DESIGN.md (tokens) → Stitch (AI generation) → React components
```

**Setup:**
```bash
# 1. Configure Google Cloud auth
gcloud auth application-default login

# 2. Add Stitch MCP server
claude mcp add stitch -- npx @_davideast/stitch-mcp proxy
```

## Installation

### For Claude Code

Copy the commands to your project's `.claude/commands/` directory:

```bash
mkdir -p .claude/commands
cp commands/*.md .claude/commands/
```

### For Skills

Copy skills to your project:

```bash
mkdir -p .claude/skills
cp -r skills/* .claude/skills/
```

## Safety Rules

### NEVER:
1. **Any agent other than TPM** merges to `main`
2. Deploy to production without `Human-Verified` label
3. Merge multiple PRs without completing full cycle for each (sequential protocol)
4. Auto-fix production issues
5. Run destructive database operations without confirmation

### ALWAYS:
1. Run health checks before/after deployments
2. Document actions in Linear
3. Wait for deployments to complete
4. Have rollback command ready (`git revert HEAD`)
5. Rebase `staging` on `main` after production deploy

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Submit a PR

## License

MIT

## Related Projects

- [Claude Code](https://claude.ai/code) - Anthropic's CLI for Claude
- [Linear](https://linear.app) - Issue tracking
- [Google Stitch](https://stitch.withgoogle.com) - AI UI generation
