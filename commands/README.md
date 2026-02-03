# Slash Commands

## Multi-Agent Workflow (MAW) Commands

> **MANDATORY:** All feature and bug development MUST use MAW. No development outside MAW except production hotfixes.

The core workflow uses 4 agents that coordinate via Linear labels.

### ⭐ `/workon` - Auto-Orchestrator (RECOMMENDED)

- **`/workon YAR-XXX`** - Auto-route issue through complete MAW pipeline

**What it does:**
1. Fetches issue from Linear, checks size (estimate field)
2. Routes to correct agent based on current state
3. **M or smaller** → Full autonomous orchestration to staging
4. **L or XL** → PM elaboration only, then stops

**Use this for all development.** Individual agent commands below are for manual control.

---

### 📋 PM Agent
- **`/pm`** - Interactive requirements elaboration session
- **`/pm <description>`** - Elaborate specific feature into Linear issue
- **`/pm-requirements <desc>`** - Alias for `/pm <description>`

Creates issues with: epic labels, size labels, CUJ references, test plans

### 🔨 Builder Agent
- **`/builder`** - Auto-pickup highest priority "Todo" issue
- **`/builder YAR-5`** - Work on specific issue

Implements features, creates PRs targeting `staging` branch

### 🧪 Tester Agent
- **`/tester`** - Auto-pickup oldest "PR-Ready" issue
- **`/tester YAR-5`** - Test specific issue
- **`/tester staging YAR-5`** - Test staging deployment

Runs E2E tests, reports results to Linear

### 🚀 Admin Agent
- **`/admin`** - Review all ready PRs, deploy to staging
- **`/admin review`** - Review PRs without deploying
- **`/admin stage YAR-5`** - Deploy specific issue to staging
- **`/admin promote YAR-5`** - Promote staging to production
- **`/admin status`** - Show deployment status
- **`/admin health`** - Check service health

Manages staging and production deployments

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
| **Start any issue** | `/workon YAR-X` | ⭐ Recommended for all work |
| Elaborate requirements | `/pm <description>` | Manual PM control |
| Start implementation | `/builder YAR-X` | Skip PM, go direct |
| Test a PR | `/tester YAR-X` | Manual test trigger |
| Test staging | `/tester staging YAR-X` | Staging verification |
| Deploy to staging | `/admin stage YAR-X` | Manual staging deploy |
| Deploy to production | `/admin promote YAR-X` | Always manual |
| Create spec (L/XL) | `/speckit.specify` | For large features |

### Size Limits for `/workon` Automation

| Size | Points | `/workon` Behavior |
|------|--------|-------------------|
| XS/S/M | 1-3 | ✅ Full auto to staging |
| L/XL | 5-8+ | ❌ PM only, then manual |

---

## Documentation

- **MAW SOP:** `docs/maw/sop.md`
- **Commands Reference:** `docs/COMMANDS_REFERENCE.md`
- **Epic Registry:** `docs/EPIC_REGISTRY.md`
- **Testing Strategy:** `docs/TESTING.md`

---

**Total Active Commands:** 21 (1 workon + 4 PM + 2 Builder + 3 Tester + 6 Admin + 8 SpecKit - with aliases)
