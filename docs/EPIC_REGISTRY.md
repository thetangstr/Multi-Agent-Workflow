# Epic & CUJ Registry

**Owner:** PM Agent
**Last Updated:** 2026-02-02
**Version:** 1.0

This is the canonical source of truth for Yarda's Epic and CUJ (Critical User Journey) hierarchy. All Linear issues, tests, and specs should reference this document.

---

## Hierarchy Overview

```
Epic (labeled in Linear)
  └── CUJ (referenced in issue title/description with #cuj-name)
        └── Tests (tagged with @epic and @cuj in test files)
```

**Rules:**
- Every Linear issue belongs to exactly ONE epic
- CUJs are referenced inline with `#cuj-name` notation
- No feature should span multiple epics (if it does, scope is too big)
- Tests are tagged for selective execution by epic or CUJ

---

## User Types

| Type | Description | Epics |
|------|-------------|-------|
| **Visitor** | Unauthenticated user | AUTH, MARKETING |
| **Homeowner** | Authenticated consumer user | AUTH, GENERATION, PAYMENTS, MARKETPLACE, ACCOUNT |
| **Pros** | Professional users (designers, architects, contractors) | AUTH, PRO_MODE, PROS_DASHBOARD, PAYMENTS, ACCOUNT |
| **Admin** | Internal team | ADMIN |

> **Note:** "Pros" is the standard term. See YAR-203 for terminology cleanup.

---

## Epics & CUJs

### EPIC: AUTH
Authentication and session management for all user types.

| CUJ ID | CUJ Name | Description | User Type |
|--------|----------|-------------|-----------|
| `#auth-oauth` | OAuth Login | User signs in via Google OAuth | All |
| `#auth-magic-link` | Magic Link Login | User signs in via email link (passwordless) | All |
| `#auth-session` | Session Management | Session persistence, refresh, expiration | All |
| `#auth-profile-sync` | Profile Sync | User profile syncs with Supabase auth | All |

**Test Files:**
- `tests/e2e/auth/magic-link.spec.ts` → @auth #auth-magic-link
- `tests/e2e/auth/oauth-errors.spec.ts` → @auth #auth-oauth
- `tests/e2e/auth/profile-sync.spec.ts` → @auth #auth-profile-sync
- `tests/e2e/auth/session-persistence.spec.ts` → @auth #auth-session

---

### EPIC: GENERATION
AI landscape generation for homeowners (oblique imagery).

| CUJ ID | CUJ Name | Description | User Type |
|--------|----------|-------------|-----------|
| `#gen-first` | First Generation | New user generates their first design using trial credits | Homeowner |
| `#gen-multi-area` | Multi-Area Generation | Generate front yard, backyard, walkway simultaneously | Homeowner |
| `#gen-style` | Style Selection | User selects design style (modern, tropical, etc.) | Homeowner |
| `#gen-address` | Address Input | User enters address, system fetches Street View/satellite | Homeowner |
| `#gen-progress` | Generation Progress | Real-time progress updates during generation | Homeowner |
| `#gen-results` | View Results | User views and downloads generated designs | Homeowner |
| `#gen-retry` | Retry Failed Generation | User retries after generation failure | Homeowner |

**Test Files:**
- `tests/e2e/generation/download-results.spec.ts` → @generation #gen-results
- `tests/e2e/generation/failure-retry.spec.ts` → @generation #gen-retry
- `tests/e2e/generation/invalid-address.spec.ts` → @generation #gen-address
- `tests/e2e/generation/multiple-areas.spec.ts` → @generation #gen-multi-area
- `tests/e2e/generation/special-properties.spec.ts` → @generation #gen-address

---

### EPIC: PAYMENTS
Token purchases, subscriptions, and billing for homeowners.

| CUJ ID | CUJ Name | Description | User Type |
|--------|----------|-------------|-----------|
| `#pay-tokens` | Purchase Tokens | User buys token pack via Stripe checkout | Homeowner |
| `#pay-subscribe` | Subscribe to Pro | User subscribes to monthly/annual Pro plan | Homeowner |
| `#pay-trial` | Trial Management | Trial credit allocation, usage, exhaustion | Homeowner |
| `#pay-auto-reload` | Auto-Reload | Automatic token replenishment when balance low | Homeowner |
| `#pay-billing` | Billing History | User views transaction and payment history | Homeowner |
| `#pay-manage` | Manage Subscription | User updates payment method, cancels subscription | Homeowner |
| `#pay-promo` | Promo Codes | User applies promotional discount codes | Homeowner |

**Test Files:**
- `tests/e2e/payments/subscription.spec.ts` → @payments #pay-subscribe
- `tests/e2e/payments/purchase-tokens.spec.ts` → @payments #pay-tokens
- `tests/e2e/payments/trial-expiration.spec.ts` → @payments #pay-trial
- `tests/e2e/payments/billing-history.spec.ts` → @payments #pay-billing
- `tests/e2e/payments/payment-methods.spec.ts` → @payments #pay-manage
- `tests/e2e/payments/plan-changes.spec.ts` → @payments #pay-subscribe

---

### EPIC: MARKETPLACE
Homeowners request estimates, contractors respond with proposals.

| CUJ ID | CUJ Name | Description | User Type |
|--------|----------|-------------|-----------|
| `#mkt-request` | Request Estimate | Homeowner posts project for contractor bids | Homeowner |
| `#mkt-view-proposals` | View Proposals | Homeowner reviews received proposals | Homeowner |
| `#mkt-compare` | Compare Proposals | Homeowner compares multiple contractor proposals | Homeowner |
| `#mkt-accept` | Accept Proposal | Homeowner accepts a contractor's proposal | Homeowner |
| `#mkt-view-leads` | View Leads | Contractor views available leads in service area | Pros |
| `#mkt-submit-proposal` | Submit Proposal | Contractor submits proposal with design + pricing | Pros |
| `#mkt-track-status` | Track Status | Both parties track project/proposal status | All |

**Test Files:**
- `tests/e2e/marketplace/homeowner-flow.spec.ts` → @marketplace #mkt-request #mkt-view-proposals
- `tests/e2e/marketplace/contractor-flow.spec.ts` → @marketplace #mkt-view-leads #mkt-submit-proposal
- `tests/e2e/marketplace/detailed-estimates.spec.ts` → @marketplace #mkt-submit-proposal
- `tests/e2e/marketplace/project-status.spec.ts` → @marketplace #mkt-track-status

---

### EPIC: PRO_MODE
Professional 2D site plan generation for Pros. Will fork into two experiences:
- **Designer/Architect track:** High-fidelity CAD output, drone uploads, material schedules
- **Contractor track:** Quick proposals, lead conversion, pricing integration

| CUJ ID | CUJ Name | Description | User Type |
|--------|----------|-------------|-----------|
| `#pro-camera` | Camera Positioning | Auto-position camera for optimal property view | Pros |
| `#pro-boundary` | Boundary Detection | AI detects property boundaries from satellite | Pros |
| `#pro-2d-plan` | Generate 2D Plan | Generate professional 2D site plan | Pros |
| `#pro-streaming` | SSE Streaming | Real-time progress during generation pipeline | Pros |
| `#pro-measurements` | Measurements | View/edit dimensions and measurements | Pros |
| `#pro-export` | Export Designs | Export designs as PNG, PDF, or ZIP package | Pros |

**Designer-specific CUJs (future):**
| CUJ ID | CUJ Name | Description |
|--------|----------|-------------|
| `#pro-drone` | Drone Upload | Upload high-res drone imagery |
| `#pro-cad` | CAD Export | Export DXF/DWG files |
| `#pro-materials` | Material Schedule | Generate itemized material list + CSV |

**Test Files:**
- `tests/e2e/pro-mode/access-control.spec.ts` → @pro_mode #pro-boundary
- `tests/e2e/pro-mode/corner-lots.spec.ts` → @pro_mode #pro-boundary
- `tests/e2e/pro-mode/dimensions.spec.ts` → @pro_mode #pro-measurements
- `tests/e2e/pro-mode/generation.spec.ts` → @pro_mode #pro-2d-plan
- `tests/e2e/pro-mode/sse-streaming.spec.ts` → @pro_mode #pro-streaming
- `tests/e2e/pro-mode/auto-camera.spec.ts` → @pro_mode #pro-camera
- `tests/e2e/pro-mode/dual-shot.spec.ts` → @pro_mode #pro-2d-plan

---

### EPIC: PROS_DASHBOARD
Dashboard and workflow tools for Pros (formerly "Partner Dashboard").

| CUJ ID | CUJ Name | Description | User Type |
|--------|----------|-------------|-----------|
| `#dash-leads` | Lead Management | View, filter, triage incoming leads | Pros |
| `#dash-proposals` | Proposal Management | Manage draft and sent proposals | Pros |
| `#dash-designs` | Design Library | View and organize saved designs | Pros |
| `#dash-profile` | Profile Settings | Update business profile and service areas | Pros |
| `#dash-analytics` | Analytics | View performance metrics and stats | Pros |

**Test Files:**
- `tests/e2e/partner/dashboard.spec.ts` → @pros_dashboard #dash-leads #dash-proposals
- `tests/e2e/partner/signup.spec.ts` → @pros_dashboard #dash-profile

---

### EPIC: ACCOUNT
User account management for all user types.

| CUJ ID | CUJ Name | Description | User Type |
|--------|----------|-------------|-----------|
| `#acct-profile` | Update Profile | User updates name, email, preferences | All |
| `#acct-password` | Password Reset | User resets forgotten password | All |
| `#acct-designs` | My Designs | User views their saved/generated designs | Homeowner |
| `#acct-settings` | Account Settings | Language, notifications, privacy settings | All |

**Test Files:**
- `tests/e2e/account/my-designs.spec.ts` → @account #acct-designs
- `tests/e2e/account/password-reset.spec.ts` → @account #acct-password
- `tests/e2e/account/profile-update.spec.ts` → @account #acct-profile

---

### EPIC: HOLIDAY
Seasonal marketing campaigns (Holiday Decorator).

| CUJ ID | CUJ Name | Description | User Type |
|--------|----------|-------------|-----------|
| `#hol-generate` | Generate Decoration | User generates AI holiday decoration | Visitor/Homeowner |
| `#hol-share` | Social Share | User shares decoration on social media | Homeowner |
| `#hol-earn` | Earn Credits | User earns credits by sharing | Homeowner |
| `#hol-download` | HD Download | User downloads high-res decoration image | Homeowner |

**Test Files:**
- (Holiday tests to be tagged)

---

### EPIC: ADMIN
Internal admin tools and monitoring.

| CUJ ID | CUJ Name | Description | User Type |
|--------|----------|-------------|-----------|
| `#admin-users` | User Management | View and manage user accounts | Admin |
| `#admin-analytics` | System Analytics | View system metrics and dashboards | Admin |
| `#admin-camera` | Camera Playground | Test and tune camera positioning | Admin |

**Test Files:**
- (Admin tests to be tagged)

---

## Issue Sizing

| Size | Effort | Test Scope | Example |
|------|--------|------------|---------|
| **XS** | < 1 day | Smoke only | Copy change, config tweak |
| **S** | 1-2 days | CUJ tests | Single bug fix, minor feature |
| **M** | 3-5 days | Epic tests | Feature enhancement, multiple CUJs |
| **L** | 1-2 weeks | Multi-epic tests | New feature spanning areas |
| **XL** | > 2 weeks | Full regression | Major refactor, new epic |

---

## Test Triggering Rules

### On PR to Staging

| Issue Size | Test Scope | Command |
|------------|------------|---------|
| XS | Smoke tests | `npm run test:smoke` |
| S | CUJ tests (affected CUJs) | `npm run test:cuj -- --grep "@<epic> #<cuj>"` |
| M | Epic tests (affected epic) | `npm run test:epic -- --grep "@<epic>"` |
| L | Multi-epic tests | `npm run test:epic -- --grep "@<epic1>\|@<epic2>"` |
| XL | Full E2E suite | `npm run test:e2e` |

### Before Production

**Always run full regression** before promoting staging → main:
```bash
npm run test:full
```

---

## Linear Label Structure

### Epic Labels (create in Linear)
```
epic:auth
epic:generation
epic:payments
epic:marketplace
epic:pro-mode
epic:pros-dashboard
epic:account
epic:holiday
epic:admin
```

### Size Labels
```
XS, S, M, L, XL
```

### Workflow Labels (existing)
```
PR-Ready, Testing, Tests-Passed, Tests-Failed, On-Staging, In-Production, Human-Verified
```

---

## CUJ Reference in Issues

When creating or updating Linear issues, reference CUJs in the title or description:

**Example Issue Title:**
```
Fix boundary detection for corner lots #pro-boundary
```

**Example Issue Description:**
```
## Summary
Corner lots are not being detected correctly...

## CUJs Affected
- #pro-boundary
- #pro-camera

## Epic
epic:pro-mode
```

---

## Test File Tagging Convention

Add tags to test file descriptions for selective execution:

```typescript
// tests/e2e/generation/download-results.spec.ts

import { test, expect } from '@playwright/test';

test.describe('@generation #gen-results Download Results', () => {
  test('user can download generated design', async ({ page }) => {
    // ...
  });
});
```

This allows running tests by epic or CUJ:
```bash
# Run all generation tests
npx playwright test --grep "@generation"

# Run specific CUJ tests
npx playwright test --grep "#gen-results"

# Run multiple CUJs
npx playwright test --grep "#gen-results|#gen-progress"
```

---

## PM Agent Responsibilities

The PM Agent is responsible for:

1. **Maintaining this document** - Keep epics and CUJs up to date
2. **Tagging Linear issues** - Apply epic labels and CUJ references
3. **Sizing issues** - Assign XS/S/M/L/XL based on scope
4. **Updating test plan** - Keep `docs/MANUAL_TEST_PLAN.md` in sync
5. **Triggering appropriate tests** - Ensure correct test scope runs for each change

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-02 | 1.0 | Initial creation with 9 epics, 40+ CUJs |
