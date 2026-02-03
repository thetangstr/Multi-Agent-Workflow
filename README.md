# Multi-Agent Workflow (MAW)

A structured CI/CD workflow using four specialized AI agents that coordinate via Linear labels. Each agent runs in its own Claude Code session, enabling parallel development with clear handoffs and quality gates.

## Overview

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         MULTI-AGENT WORKFLOW                                  │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Linear Issue (Todo)                                                         │
│       │                                                                      │
│       ▼                                                                      │
│  ┌─────────────┐    PR-Ready    ┌─────────────┐   Tests-Passed   ┌────────┐ │
│  │   BUILDER   │ ──────────────▶│   TESTER    │ ────────────────▶│ ADMIN  │ │
│  │   Agent     │                │   Agent     │                  │ Agent  │ │
│  │             │                │             │                  │        │ │
│  │ • Research  │ ◀────────────  │ • E2E tests │                  │• Deploy│ │
│  │ • Implement │  Tests-Failed  │ • Reports   │                  │• Merge │ │
│  │ • Create PR │                │ • Validate  │                  │        │ │
│  └─────────────┘                └─────────────┘                  └────────┘ │
│                                       │                               │      │
│                                       │ Staging-Verified              │      │
│                                       ▼                               │      │
│                              ┌─────────────────┐                      │      │
│                              │ HUMAN VALIDATION │                     │      │
│                              │ (Human-Verified) │◀────────────────────┘      │
│                              └────────┬────────┘                             │
│                                       │                                      │
│                                       ▼                                      │
│                              ┌─────────────────┐                             │
│                              │   PRODUCTION    │                             │
│                              │  (In-Production)│                             │
│                              └─────────────────┘                             │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Single entry point for all development
/workon YAR-123   # Auto-routes issue through entire pipeline
```

## Agents

| Agent | Command | Responsibility |
|-------|---------|----------------|
| **PM** | `/pm` | Elaborate requirements, create Linear issues with epics/CUJs |
| **Builder** | `/builder` | Research, implement, create PR, write tests |
| **Tester** | `/tester` | Run E2E tests, report issues, verify staging |
| **Admin** | `/admin` | Deploy to staging/production, merge PRs |

## Size-Based Deployment

| Size | Points | Deployment Path |
|------|--------|-----------------|
| XS/S/M | 1-3 | Direct to production (low-risk) |
| L/XL | 5-8+ | Staging → Human verify → Production |

## Linear Label State Machine

```
PR-Ready → Testing → Tests-Passed → On-Staging → Staging-Verified → Human-Verified → In-Production
              ↓
        Tests-Failed (back to Builder)
```

| Label | Color | Set By | Meaning |
|-------|-------|--------|---------|
| `PR-Ready` | Blue | Builder | PR created, ready for testing |
| `Testing` | Yellow | Tester | Actively testing |
| `Tests-Passed` | Green | Tester | All tests passed |
| `Tests-Failed` | Red | Tester | Failures found |
| `On-Staging` | Purple | Admin | Deployed to staging |
| `Staging-Verified` | Light Green | Tester | Staging E2E passed |
| `Human-Verified` | Orange | Human | Ready for production |
| `In-Production` | Gray | Admin | Live in production |

## Project Structure

```
├── README.md           # This file
├── DESIGN.md           # Semantic design system for Stitch UI generation
├── docs/
│   ├── sop.md                    # Main Standard Operating Procedure
│   ├── MULTI_AGENT_WORKFLOW.md   # Detailed workflow documentation
│   ├── EPIC_REGISTRY.md          # Epic/CUJ canonical list
│   └── MANUAL_TESTING_GUIDE.md   # Manual testing procedures
├── commands/
│   ├── workon.md       # MAW orchestrator (entry point)
│   ├── builder.md      # Builder agent workflow
│   ├── tester.md       # Tester agent workflow
│   ├── admin.md        # Admin agent workflow
│   ├── pm.md           # PM agent workflow
│   └── README.md       # Commands quick reference
├── skills/
│   └── pm-requirements/  # PM requirements elaboration skill
└── templates/
    └── test-plan-template.md  # Test plan template
```

## MCP Integrations

| MCP Server | Purpose |
|------------|---------|
| **Linear** | Issue tracking, labels, workflow state |
| **GitHub** | PRs, code review, merges |
| **Railway** | Backend deployment, PR environments |
| **Vercel** | Frontend deployment, previews |
| **Supabase** | Database queries, migrations |
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
1. Push L/XL issues directly to `main` (must go through staging)
2. Deploy to production without `Human-Verified` label
3. Auto-fix production issues
4. Run destructive database operations without confirmation

### ALWAYS:
1. Run health checks before/after deployments
2. Document actions in Linear
3. Wait for deployments to complete
4. Have rollback command ready

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
