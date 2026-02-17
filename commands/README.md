# Slash Commands

## Multi-Agent Workflow (MAW) v4 Commands

> **MANDATORY:** All feature and bug development MUST use MAW. No development outside MAW except production hotfixes.

The core workflow uses 5 agents that coordinate via Linear labels. **TPM is the sole agent that merges to `main`.**

### ⭐ `/tpm` - TPM Agent (Project Command Center)

- **`/tpm <project description>`** - Break project into Linear issues, plan execution waves, create workspaces
- **`/tpm sync`** - **THE main command.** Poll Linear, show dashboard, auto-ship verified features
- **`/tpm wave`** - Show current wave details, create workspaces for next wave
- **`/tpm status`** - Quick read-only summary: issues by state, blockers, wave progress

**What `/tpm sync` does:**
1. Polls Linear for all active issues
2. Auto-ships any `Human-Verified` issues (merge → deploy → smoke test → In-Production)
3. Checks wave completion, advances to next wave
4. Creates workspaces for new waves
5. Displays dashboard with action items

---

### ⭐ `/workon` - Per-Issue Orchestrator

- **`/workon YAR-XXX`** - Auto-route issue through MAW pipeline in a single workspace

**What it does:**
1. Fetches issue from Linear, checks size
2. Routes to correct agent based on current state (PM → Builder → Tester)
3. Pauses at `Tests-Passed` for human verification
4. After `Human-Verified`, TPM handles shipping via `/tpm sync`

---

### 📋 PM Agent
- **`/pm`** - Interactive requirements elaboration session
- **`/pm <description>`** - Elaborate specific feature into Linear issue
- **`/pm validate YAR-XXX`** - Pre-human validation on PR Preview

Creates issues with: epic labels, size labels, CUJ references, test plans

### 🔨 Builder Agent
- **`/builder`** - Auto-pickup highest priority "Builder-Ready" issue
- **`/builder YAR-5`** - Work on specific issue

Implements features, creates PRs (rebases on `main` first)

### 🧪 Tester Agent
- **`/tester`** - Auto-pickup oldest "PR-Ready" issue
- **`/tester YAR-5`** - Test specific issue
- **`/tester staging YAR-5`** - Test staging deployment

Runs E2E tests, reports results to Linear

### 🔧 Admin Agent (Ops-Only)
- **`/admin`** - Run full health check + show stats
- **`/admin health`** - Check all service health
- **`/admin status`** - Show deployment status
- **`/admin stats`** - Show usage statistics

**Note:** Admin is ops-only. TPM handles all merging and shipping.

---

## SpecKit Workflow (For L/XL Features)

- **`/speckit.specify`** - Create/update feature specification
- **`/speckit.clarify`** - Identify underspecified areas with Q&A
- **`/speckit.plan`** - Execute implementation planning workflow
- **`/speckit.tasks`** - Generate dependency-ordered tasks
- **`/speckit.implement`** - Execute implementation plan
- **`/speckit.analyze`** - Cross-artifact consistency analysis
- **`/speckit.checklist`** - Generate custom feature checklist
- **`/speckit.constitution`** - Create/update project constitution

---

## Quick Reference

| Task | Command | Notes |
|------|---------|-------|
| **Plan a project** | `/tpm <description>` | Creates issues, waves, workspaces |
| **Check status & ship** | `/tpm sync` | ⭐ The main command |
| **Start any issue** | `/workon YAR-X` | Per-workspace orchestration |
| Elaborate requirements | `/pm <description>` | Manual PM control |
| Start implementation | `/builder YAR-X` | Skip PM, go direct |
| Test a PR | `/tester YAR-X` | Manual test trigger |
| Test staging | `/tester staging YAR-X` | Staging verification |
| Service health | `/admin health` | Ops monitoring |
| Usage stats | `/admin stats` | DB queries |
| Create spec (L/XL) | `/speckit.specify` | For large features |

### Agent Roles

| Agent | Workspace | Merges to main? |
|-------|-----------|----------------|
| **TPM** | 1 dedicated | **YES (sole agent)** |
| **Builder** | 1 per issue | No |
| **Tester** | Subagent | No |
| **PM** | Subagent | No |
| **Admin** | On demand | No |

---

## Documentation

- **MAW SOP:** `docs/sop.md`
- **Agent Protocol:** `docs/protocol.md`
- **Epic Registry:** `docs/EPIC_REGISTRY.md`
- **Testing Strategy:** `docs/TESTING.md`

---

**Total Active Commands:** 25 (4 TPM + 1 workon + 3 PM + 2 Builder + 3 Tester + 4 Admin + 8 SpecKit)
