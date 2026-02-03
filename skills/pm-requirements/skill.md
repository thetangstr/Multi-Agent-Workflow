# PM Requirements Elaboration Skill

A structured approach to elaborate raw feature requests into comprehensive product requirements.

## When to Use

Invoke `/pm-requirements` when:
- Starting a new feature that needs clear specifications
- Raw requirements need to be broken down into actionable items
- Need to identify edge cases, data models, and success metrics
- Want to create a shared understanding before implementation

## Research Phase (ALWAYS DO FIRST)

Before elaborating requirements, conduct thorough research:

### 1. Codebase Exploration
- Search for existing implementations of similar features
- Identify reusable components and patterns
- Understand current data models and relationships
- Find related API endpoints and services

### 2. Data Model Analysis
- Review database migrations for relevant tables
- Map out foreign key relationships
- Identify existing RLS policies
- Note any denormalized views or materialized data

### 3. UI/UX Patterns
- Screenshot or describe existing similar UI
- Identify design system components in use
- Note navigation patterns and user flows
- Review existing notification/badge implementations

### 4. Technical Dependencies
- List services that will need modification
- Identify shared utilities and hooks
- Note any third-party integrations involved
- Check for feature flags or A/B tests

### 5. Gap Analysis
- What exists that we can reuse?
- What needs to be created from scratch?
- What needs to be modified/extended?
- What should be deprecated/removed?

## Elaboration Framework

### 1. Problem Statement
- What problem are we solving?
- Who is the target user?
- What is the current pain point?

### 2. User Stories
Format: `As a [role], I want to [action], so that [benefit]`

### 3. Functional Requirements
- Core features (must-have)
- Enhanced features (nice-to-have)
- Out of scope (explicitly not doing)

### 4. UI/UX Specifications
- Screen layouts and navigation
- Component hierarchy
- Interaction patterns
- Loading states and empty states
- Error states and validation

### 5. Data Model Requirements
- New tables/columns needed
- Relationships and foreign keys
- Migration considerations
- RLS policies (if Supabase)

### 6. API Requirements
- New endpoints needed
- Request/response schemas
- Authentication requirements

### 7. Edge Cases & Error Handling
- What happens when data is missing?
- Concurrent access scenarios
- Network failure handling
- Permission edge cases

### 8. Success Metrics
- How do we know this feature is successful?
- What metrics should we track?
- A/B testing considerations

### 9. Implementation Phases
- Phase 1: MVP (what ships first)
- Phase 2: Enhancements
- Phase 3: Future considerations

## Linear Issue Management

When creating or updating Linear issues, PM Agent MUST follow these practices:

### Epic & CUJ Tagging (REQUIRED)

1. **Apply Epic Label**: Every issue MUST have exactly one `epic:` label:
   - `epic:auth` - Authentication and session management
   - `epic:generation` - AI landscape generation for homeowners
   - `epic:payments` - Tokens, subscriptions, billing
   - `epic:marketplace` - Homeowner estimates and contractor proposals
   - `epic:pro-mode` - Professional 2D site plan generation
   - `epic:pros-dashboard` - Dashboard and workflow for Pros
   - `epic:account` - User account and profile management
   - `epic:holiday` - Seasonal marketing campaigns
   - `epic:admin` - Internal admin tools

2. **Reference CUJs in Description**: Include `#cuj-name` references in the issue description:
   ```markdown
   ## CUJs Affected
   - #gen-first (first generation flow)
   - #gen-multi-area (multi-area generation)
   ```

   See `docs/EPIC_REGISTRY.md` for the complete CUJ list per epic.

### Size Assignment (REQUIRED)

Assign one size label based on effort estimate:

| Size | Effort | Test Scope |
|------|--------|------------|
| `XS` | < 1 day | Smoke tests only |
| `S` | 1-2 days | CUJ-level tests |
| `M` | 3-5 days | Epic-level tests |
| `L` | 1-2 weeks | Multi-epic tests |
| `XL` | > 2 weeks | Full regression |

### Test Plan (REQUIRED for M/L/XL)

Every issue M-sized or larger MUST include a test plan in the issue description:

```markdown
## Test Plan

**Epic:** epic:<name>
**Size:** <XS|S|M|L|XL>

### Automated Tests
Run the following command after staging deployment:
```bash
<specific playwright command based on affected CUJs>
```

### CUJs to Verify
- [ ] #<cuj-1>: <brief description of what to check>
- [ ] #<cuj-2>: <brief description of what to check>

### Manual Verification (if needed)
- [ ] <manual check 1>
- [ ] <manual check 2>
```

**Test Command Examples by Scope:**

| Scope | Command |
|-------|---------|
| Single CUJ | `npx playwright test --grep "#gen-first"` |
| Multiple CUJs | `npx playwright test --grep "#gen-first\|#gen-multi-area"` |
| Entire Epic | `npx playwright test --grep "@payments"` |
| Multiple Epics | `npx playwright test --grep "@payments\|@generation"` |
| Full Regression | `npm run test:full` |

**Size → Test Scope Mapping:**

| Size | Default Test Scope |
|------|-------------------|
| XS | Smoke only: `npm run test:smoke` |
| S | Affected CUJ(s) only |
| M | Entire affected epic |
| L | All affected epics |
| XL | Full regression |

### Registry Updates

When a feature adds or modifies CUJs:
1. Update `docs/EPIC_REGISTRY.md` with new CUJ definitions
2. Update `docs/MANUAL_TESTING_GUIDE.md` with manual test scenarios
3. Ensure new test files include `@epic #cuj` tags in `test.describe()`

## Output Format

Generate a structured PRD document in markdown format that can be saved to `specs/<feature-name>/spec.md`.

## Usage

```
/pm-requirements <raw requirements or feature description>
```

The skill will:
1. Parse the raw requirements
2. Ask clarifying questions if needed
3. Generate a comprehensive PRD following the framework above
4. Identify technical dependencies and risks
5. Suggest implementation order
