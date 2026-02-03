# Yarda v5 - Complete Manual Testing Guide

**Version:** 2.1
**Last Updated:** 2026-01-28
**Purpose:** Business-priority manual testing checklist for agent-driven testing or QA validation

---

## Testing Strategy & Priorities

### Business-Driven Test Prioritization

Tests are organized by **business impact** rather than feature areas. This ensures critical revenue-protecting features are validated first.

**Priority Levels:**
- 🔴 **P0 - Critical Revenue Protection** - Partner acquisition, subscriptions, Pro Mode access
- 🟠 **P1 - High Priority Business Features** - Token purchases, checkout recovery, customer retention
- 🟡 **P2 - Premium Features** - Pro Mode generation, lead notifications
- 🟢 **P3 - Standard Features** - Core functionality with existing automated coverage

**Testing Philosophy:**
1. **ALWAYS test P0 features first** - These directly impact revenue
2. **P1 features before deployment** - High business value
3. **P2 features for major releases** - Premium user experience
4. **P3 features when time permits** - Already covered by automated E2E tests

### Recommended Test Execution Order

**Quick Validation (30 minutes):**
- Suite 1: Partner Signup & Email (P0)
- Suite 2: Subscription Flow (P0)
- Suite 3: Pro Mode Access Control (P0)

**Full Pre-Deployment (2 hours):**
- All P0 tests
- All P1 tests
- Critical P2 tests (Pro Mode generation)

**Comprehensive QA (4+ hours):**
- All P0, P1, P2 tests
- Selected P3 tests (authentication, trial flow)

---

## How to Use This Guide

This guide provides step-by-step manual testing procedures organized by business priority. Each test is designed to be executed by either:
1. **QA Engineers** - Manual validation before production deployment
2. **AI Testing Agents** - Automated browser testing using Playwright MCP or similar
3. **Product Managers** - Feature acceptance testing

### Test Status Indicators

- ✅ **PASS** - Feature works as expected
- ❌ **FAIL** - Feature broken or does not meet requirements
- ⚠️ **WARNING** - Feature works but has issues
- ⏭️ **SKIP** - Test not applicable in current environment

### Prerequisites

Before starting any manual test session:

```bash
# 1. Ensure test users exist in database (see Test User Setup section)
# 2. Reset test user credits to known state
# 3. Clear browser cache and cookies
# 4. Use incognito/private browsing mode for clean state
# 5. Verify Stripe test mode configured (see STRIPE_TEST_MODE_SETUP.md)
```

---

## Test User Setup

### Required Test Accounts

Create these test users in production/staging database:

```sql
-- Reset all test users to known state before testing
BEGIN;

-- Trial user (3 credits)
DELETE FROM users WHERE email = 'test+trial@yarda.app';
INSERT INTO users (id, email, trial_remaining, tokens_purchased, subscription_status)
VALUES (
  '10000000-0000-0000-0000-000000000001',
  'test+trial@yarda.app',
  3, 0, NULL
);

-- Zero-credit user
DELETE FROM users WHERE email = 'test+nocredit@yarda.app';
INSERT INTO users (id, email, trial_remaining, trial_used, tokens_purchased)
VALUES (
  '10000000-0000-0000-0000-000000000002',
  'test+nocredit@yarda.app',
  0, 3, 0
);

-- Token user (5 purchased credits)
DELETE FROM users WHERE email = 'test+token@yarda.app';
INSERT INTO users (id, email, trial_remaining, tokens_purchased, tokens_used)
VALUES (
  '10000000-0000-0000-0000-000000000003',
  'test+token@yarda.app',
  0, 5, 0
);

-- Pro subscriber
DELETE FROM users WHERE email = 'test+pro@yarda.app';
INSERT INTO users (id, email, subscription_status, subscription_credits, g3p_credits, stripe_subscription_id)
VALUES (
  '10000000-0000-0000-0000-000000000004',
  'test+pro@yarda.app',
  'active', 20, 10, 'sub_test_123'
);

-- Partner user
DELETE FROM users WHERE email = 'test+partner@yarda.app';
INSERT INTO users (id, email, trial_remaining, g3p_credits)
VALUES (
  '10000000-0000-0000-0000-000000000005',
  'test+partner@yarda.app',
  3, 10
);

INSERT INTO marketplace_contractors (id, user_id, business_name, contact_name, contact_phone, status)
VALUES (
  '20000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000005',
  'Test Landscaping Co',
  'Test Partner',
  '555-1234',
  'active'
) ON CONFLICT (user_id) DO UPDATE SET
  business_name = 'Test Landscaping Co',
  status = 'active';

-- Admin user
DELETE FROM users WHERE email = 'admin@yarda.app';
INSERT INTO users (id, email, role, trial_remaining, g3p_credits)
VALUES (
  '10000000-0000-0000-0000-000000000099',
  'admin@yarda.app',
  'admin', 999, 999
);

COMMIT;
```

### Test User Credentials

| Email | Password | Role | Credits | Purpose |
|-------|----------|------|---------|---------|
| `test+trial@yarda.app` | `yarda123` | Trial | 3 trial | New user experience |
| `test+nocredit@yarda.app` | `yarda123` | Zero-credit | 0 | Purchase flow testing |
| `test+token@yarda.app` | `yarda123` | Token | 5 tokens | Token usage testing |
| `test+pro@yarda.app` | `yarda123` | Pro | 20 sub, 10 G3P | Pro Mode testing |
| `test+partner@yarda.app` | `yarda123` | Partner | 3 trial, 10 G3P | Partner features |
| `admin@yarda.app` | `yarda123` | Admin | ∞ | Admin features |

### Stripe Test Credentials

**Stripe Account:** `acct_1SFRz7F7hxfSl7pF`

**Test Cards:**
| Card Number | Expiry | CVC | ZIP | Description |
|-------------|--------|-----|-----|-------------|
| `4242 4242 4242 4242` | 12/34 | 123 | 12345 | ✅ Successful payment |
| `4000 0566 5566 5556` | 12/34 | 123 | 12345 | ✅ Visa debit (success) |
| `5555 5555 5555 4444` | 12/34 | 123 | 12345 | ✅ Mastercard (success) |
| `4000 0000 0000 0002` | 12/34 | 123 | 12345 | ❌ Card declined |
| `4000 0000 0000 9995` | 12/34 | 123 | 12345 | ❌ Insufficient funds |
| `4000 0000 0000 0341` | 12/34 | 123 | 12345 | 🔐 Requires 3D Secure |

**Test Mode API Keys:**
- Publishable Key: `pk_test_YOUR_PUBLISHABLE_KEY`
- Secret Key: `sk_test_YOUR_SECRET_KEY`
- Webhook Secret (Staging): `whsec_YOUR_WEBHOOK_SECRET`
- Webhook Endpoint: `https://yardav5-staging-b19c.up.railway.app/webhooks/stripe`

**Current Production Pricing (as of 2026-01-28):**

**Token Packages:**
| Package | Price | Per Token | Savings |
|---------|-------|-----------|---------|
| 10 tokens | $2.50 | $0.25 | - |
| 50 tokens | $10.00 | $0.20 | 20% |
| 100 tokens | $17.50 | $0.17 | 30% |
| 250 tokens | $37.50 | $0.15 | 40% |

**Property Pass:** $9.99 for 5 days (unlimited designs for one address)

**Monthly Pro:** $99/month with 7-day free trial (unlimited designs, all addresses)

**Note:** Stripe product IDs may change. Verify current pricing on https://yarda.pro/pricing before testing.

---

## Production Stripe Testing (Safe Testing Guide)

**⚠️ IMPORTANT:** On production (yarda.pro), Stripe uses LIVE mode. Test cards do NOT work. Use these safe testing approaches:

### Production-Safe Stripe Tests

These tests verify the payment flow WITHOUT completing actual transactions:

#### Test P-1: Pricing Page UI Review
**Objective:** Verify pricing page displays correctly with proper CTAs

**Steps:**
1. Navigate to `https://yarda.pro/pricing`
2. Verify page loads without errors
3. Check visual elements:
   - [ ] **Token Packages section** displays 4 options (10/50/100/250 tokens)
   - [ ] **Property Pass** card shows $9.99 for 5 days
   - [ ] **Monthly Pro** card shows $99/month with 7-day free trial
   - [ ] Price amounts match current pricing (see Stripe section above)
   - [ ] Feature lists are readable and accurate
   - [ ] CTA buttons ("Buy Credits", "Get Property Pass", "Start 7-Day Free Trial") are prominent
   - [ ] Mobile responsive layout works
   - [ ] Comparison table displays correctly
4. Review copy/text quality:
   - [ ] No typos or grammatical errors
   - [ ] Value proposition is clear
   - [ ] Benefits are compelling

**Aesthetic Criteria:**
- Typography: Clean, readable, consistent sizing
- Spacing: Proper padding, no cramped elements
- Colors: Brand consistent, good contrast
- Buttons: Clear visual hierarchy, hover states work

#### Test P-2: Checkout Redirect Verification
**Objective:** Verify Stripe Checkout redirects work correctly

**Steps:**
1. Login to production with test account
2. Navigate to `/pricing`
3. Click "Buy Credits" then select a token package
4. Verify redirect to `checkout.stripe.com`
5. **DO NOT COMPLETE PAYMENT** - Close tab after verifying:
   - [ ] Stripe Checkout loads
   - [ ] Product name shows token package details
   - [ ] Price matches selected package
   - [ ] Yarda branding/logo appears
6. Repeat for "Start 7-Day Free Trial" button:
   - [ ] Shows "Yarda Pro - Monthly" subscription
   - [ ] Shows 7-day free trial, then $99/month
   - [ ] Subscription badge/indicator visible

**Note:** If user already has active subscription, system should show "You already have an active subscription" message instead of redirecting.

#### Test P-3: Success/Cancel Page Flow
**Objective:** Verify success and cancel redirect URLs work

**Steps:**
1. Start checkout flow (don't complete)
2. Click "Back" or close Stripe Checkout
3. Verify redirect to cancel page or pricing page
4. Check error handling - no broken states

#### Test P-4: Customer Portal Access (For Existing Subscribers)
**Objective:** Verify subscribers can access Customer Portal

**Prerequisites:** User with active subscription

**Steps:**
1. Login as subscriber
2. Navigate to account/settings
3. Click "Manage Subscription"
4. Verify redirect to `billing.stripe.com`
5. Check portal shows:
   - [ ] Current plan details
   - [ ] Payment method (masked)
   - [ ] Billing history
   - [ ] Cancel option available

#### Test P-5: Pricing Page Copy Review (AI Critique)

**Objective:** AI reviews pricing page copy for quality and conversion optimization

**Review Criteria:**
1. **Clarity:** Is the value proposition immediately clear?
2. **Urgency:** Does the copy create appropriate urgency?
3. **Trust:** Are there trust signals (guarantees, social proof)?
4. **Objection Handling:** Does the copy address common concerns?
5. **CTA Strength:** Are CTAs compelling and action-oriented?
6. **Feature Presentation:** Are benefits prioritized over features?

**Scoring:**
- 5/5: Excellent - No improvements needed
- 4/5: Good - Minor tweaks recommended
- 3/5: Adequate - Some improvements needed
- 2/5: Poor - Significant issues
- 1/5: Critical - Major rewrite needed

---

## Manual Test Suites

Test suites are ordered by business priority (P0 → P1 → P2 → P3).

**Quick Reference:**
- **P0:** Suites 1-3 (Partner Email, Subscription, Pro Access)
- **P1:** Suites 4-6 (Token Purchase, Abandoned Checkout, Customer Portal)
- **P2:** Suites 7-8 (Pro Mode Generation, Lead Notifications)
- **P3:** Suites 9-13 (Authentication, Trial Flow, Standard Features, Holiday, Admin, Error Handling)

---

## 🔴 P0 - CRITICAL REVENUE PROTECTION

---

## Suite 1: Partner Signup & Email Flow (P0)

**Business Impact:** Partner acquisition is our primary revenue source
**Automated Test:** `frontend/tests/e2e/partner-email-flow.spec.ts`
**Time:** 10 minutes

### Test 1.1: Partner Signup Welcome Email

**Objective:** Verify partner signup sends professional welcome email with correct branding

**Prerequisites:** Unique email not in system

**Steps:**
1. Navigate to `/partner/profile`
2. Fill partner signup form:
   - **Business Name:** "Test Landscaping Co"
   - **Contact Name:** "Test Partner"
   - **Email:** `test+newpartner${DATE}@yarda.app`
   - **Phone:** "555-1234"
   - **ZIP Code:** "90210"
   - **State:** California
   - **Services:** Check "Hardscaping" and "Softscaping"
3. Check disclaimers and terms checkboxes
4. Click "Submit"
5. Verify success message
6. Check email inbox for welcome email (within 60 seconds)

**Expected Results:**
- [ ] Form validation works (required fields)
- [ ] Submit button enables when form complete
- [ ] Success message: "Check your email..."
- [ ] Welcome email received within 1 minute
- [ ] Email from: **"Yarda <admin@yarda.pro>"** (NOT "Eddy" or "noreply")
- [ ] Email subject: **"🎉 You're In! Start Receiving Pre-Qualified Leads Today"**
- [ ] Email contains:
  - [ ] Business name ("Test Landscaping Co")
  - [ ] Contact name ("Test Partner")
  - [ ] CTA: "Complete Profile Now"
  - [ ] CTA: "View Partner Dashboard"
  - [ ] CTA: "Explore Pro Mode"
  - [ ] Pro tip about 15-min response time (3x conversion)
  - [ ] 5-minute quick start checklist
  - [ ] Professional, elegant, simple design
- [ ] All CTAs clickable and link to correct pages

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Email Received: [ ] Yes  [ ] No (time: _____ sec)
Email From: _______________________________ (MUST be admin@yarda.pro)
Email Quality: [ ] Professional  [ ] Poor
All CTAs Work: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 1.2: Existing User Partner Conversion

**Objective:** Existing Yarda user converts to partner

**Prerequisites:** Login as `test+trial@yarda.app`

**Steps:**
1. Login to existing account
2. Navigate to `/partner/profile`
3. Fill partner form (same as Test 1.1)
4. Submit

**Expected Results:**
- [ ] System detects existing user
- [ ] Profile linked to existing account
- [ ] Welcome email sent (from admin@yarda.pro)
- [ ] Can access both homeowner features AND partner dashboard

**Verification:**
```sql
SELECT u.email, c.business_name, c.status
FROM users u
JOIN marketplace_contractors c ON c.user_id = u.id
WHERE u.email = 'test+trial@yarda.app';

-- Should return 1 row with contractor profile
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Existing User Detected: [ ] Yes  [ ] No
Profile Created: [ ] Yes  [ ] No
Email From admin@yarda.pro: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

## Suite 2: Stripe Subscription Flow (P0)

**Business Impact:** Subscriptions are recurring revenue - must work flawlessly
**Automated Test:** `frontend/tests/e2e/stripe-subscription-flow.spec.ts`
**Time:** 15 minutes

### Test 2.1: Complete Subscription Purchase

**Objective:** User purchases monthly Pro plan and receives 20 credits + Pro Mode access

**Prerequisites:**
- Login as `test+nocredit@yarda.app` (0 credits)
- Stripe test mode configured (see STRIPE_TEST_MODE_SETUP.md)

**Steps:**
1. Navigate to `/pricing`
2. Locate "Pro Plan - $25/month"
3. Click "Subscribe"
4. Verify redirect to Stripe Checkout
5. Fill Stripe test card:
   - **Card:** 4242 4242 4242 4242
   - **Expiry:** 12/34
   - **CVC:** 123
   - **Name:** Test User
6. Click "Pay"
7. Wait for redirect back to app (success page)
8. Wait 10 seconds for webhook to process
9. Verify credits added
10. Verify Pro Mode accessible

**Expected Results:**
- [ ] Redirected to `checkout.stripe.com`
- [ ] Stripe Checkout loads correctly
- [ ] Test card accepted
- [ ] Redirect to `/success` or `/generate`
- [ ] **20 subscription credits** added (within 10 seconds)
- [ ] **G3P credits** added for Pro Mode (>0)
- [ ] Badge shows "Pro" or "Unlimited"
- [ ] Can access Pro Mode at `/pro-mode`
- [ ] No upgrade prompt when visiting `/pro-mode`

**Verification:**
```sql
SELECT subscription_status, subscription_credits, g3p_credits, stripe_subscription_id
FROM users
WHERE email = 'test+nocredit@yarda.app';

-- Should show:
-- subscription_status = 'active'
-- subscription_credits = 20
-- g3p_credits > 0
-- stripe_subscription_id = sub_XXXXX
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Stripe Checkout Loaded: [ ] Yes  [ ] No
Payment Successful: [ ] Yes  [ ] No
Credits Added: [ ] Yes  [ ] No (took ____ seconds)
  - Subscription Credits: _____ (expected: 20)
  - G3P Credits: _____ (expected: >0)
Pro Badge Visible: [ ] Yes  [ ] No
Pro Mode Accessible: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

## Suite 3: Pro Mode Access Control (P0)

**Business Impact:** Prevents free access to premium features
**Automated Test:** `frontend/tests/e2e/auth-pro-mode-access.spec.ts`
**Time:** 10 minutes

### Test 3.1: Non-Pro User CANNOT Access Pro Mode

**Objective:** Verify access control blocks non-subscribers

**Prerequisites:** Login as `test+trial@yarda.app` (no Pro subscription)

**Steps:**
1. Navigate to `/pro-mode`
2. Verify upgrade prompt or redirect

**Expected Results:**
- [ ] Redirected to upgrade page OR
- [ ] See "Upgrade to Pro" modal
- [ ] "Subscribe Now" CTA visible
- [ ] Cannot access Pro Mode features
- [ ] Camera controls NOT visible

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Access Blocked: [ ] Yes  [ ] No
Upgrade Prompt Shown: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 3.2: Pro Subscriber CAN Access Pro Mode

**Objective:** Verify Pro users have full access

**Prerequisites:** Login as `test+pro@yarda.app`

**Steps:**
1. Navigate to `/pro-mode`
2. Verify Pro Mode interface loads
3. Verify camera controls visible

**Expected Results:**
- [ ] Pro Mode interface loads
- [ ] Camera controls visible
- [ ] Can enter address and proceed
- [ ] No upgrade prompt

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Pro Mode Loaded: [ ] Yes  [ ] No
Camera Controls Visible: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 3.3: Partner User Gets Automatic Pro Access

**Objective:** Partners receive Pro Mode access automatically

**Prerequisites:** Login as `test+partner@yarda.app`

**Steps:**
1. Navigate to `/pro-mode`
2. Verify Pro Mode accessible (partners get automatic access)

**Expected Results:**
- [ ] Pro Mode accessible (partners get automatic access)
- [ ] Full features available

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Partner Pro Access: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 3.4: Anonymous User Pro Mode Landing Page

**Objective:** Unauthenticated users see marketing demo page (not full Pro Mode)

**Prerequisites:** None (clear all auth state)

**Steps:**
1. Clear cookies and localStorage
2. Navigate to `/pro-mode`

**Expected Results:**
- [ ] Shows marketing landing page with "Professional 2D & 3D Site Plans" heading
- [ ] Interactive demo video/animation plays
- [ ] "Try Free for 7 Days" CTA button links to `/register`
- [ ] "Already have an account? Sign in" button visible
- [ ] User cannot access actual Pro Mode features without authentication

**Note:** This is intentional marketing funnel behavior, not a redirect to login.

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Demo Page Shown: [ ] Yes  [ ] No
CTAs Work: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

## 🟠 P1 - HIGH PRIORITY BUSINESS FEATURES

---

## Suite 4: Token Purchase Flow (P1)

**Business Impact:** One-time revenue from token purchases
**Automated Test:** `frontend/tests/e2e/stripe-token-purchase.spec.ts`
**Time:** 10 minutes

### Test 4.1: Token Purchase via Stripe (CUJ-4)

**Objective:** User purchases one-time tokens via Stripe

**Prerequisites:** Login as `test+nocredit@yarda.app`

**Steps:**
1. Navigate to `/pricing`
2. Locate "Buy 5 Credits - $10" option
3. Click "Purchase"
4. Verify redirect to Stripe Checkout
5. Fill Stripe test card:
   - **Card:** 4242 4242 4242 4242
   - **Expiry:** 12/34
   - **CVC:** 123
   - **Name:** Test User
6. Click "Pay"
7. Wait for redirect back to app
8. Verify credits added

**Expected Results:**
- [ ] Redirected to `checkout.stripe.com`
- [ ] Stripe Checkout loads correctly
- [ ] Test card accepted
- [ ] Redirect to `/success` or `/generate`
- [ ] Credits updated: **0 → 5** (within 10 seconds)
- [ ] Can now generate designs

**Verification:**
```sql
SELECT tokens_purchased, tokens_used
FROM users
WHERE email = 'test+nocredit@yarda.app';

-- Should show tokens_purchased = 5
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Stripe Checkout Loaded: [ ] Yes  [ ] No
Payment Successful: [ ] Yes  [ ] No
Credits Added: [ ] Yes  [ ] No (took ____ seconds)
Final Credit Balance: _____
Notes: ___________________________________________
```

---

## Suite 5: Abandoned Checkout Recovery (P1)

**Business Impact:** Recover lost revenue from abandoned checkouts
**Automated Test:** `backend/tests/unit/test_abandoned_checkout_service.py`
**Time:** 10 minutes (manual trigger required)

### Test 5.1: Abandoned Subscription Checkout

**Objective:** User starts subscription checkout but abandons, receives recovery email

**Prerequisites:** Login as `test+nocredit@yarda.app`

**Steps:**
1. Navigate to `/pricing`
2. Click "Subscribe - $25/month"
3. Redirected to Stripe Checkout
4. DO NOT complete payment - close browser tab
5. Manually trigger cron: `python backend/scripts/send_recovery_emails.py`
6. Check email inbox

**Expected Results:**
- [ ] Abandoned checkout tracked in database
- [ ] Recovery email received after manual trigger
- [ ] Email from: "Yarda <admin@yarda.pro>"
- [ ] Email subject mentions subscription
- [ ] Email contains:
  - [ ] Plan details (Monthly Pro, $25/month)
  - [ ] Resume checkout CTA
  - [ ] Benefits reminder
- [ ] Resume link works and opens Stripe Checkout

**Verification:**
```sql
SELECT * FROM abandoned_checkouts
WHERE user_id = (SELECT id FROM users WHERE email = 'test+nocredit@yarda.app')
  AND NOT completed
ORDER BY created_at DESC
LIMIT 1;

-- Should show:
-- recovery_email_sent = TRUE
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Checkout Tracked: [ ] Yes  [ ] No
Recovery Email Received: [ ] Yes  [ ] No
Resume Link Works: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

## Suite 6: Customer Portal Access (P1)

**Business Impact:** Customer retention and self-service
**Automated Test:** `frontend/tests/e2e/subscription-customer-portal.spec.ts`
**Time:** 5 minutes

### Test 6.1: Customer Portal Access

**Objective:** User can manage subscription via Customer Portal

**Prerequisites:** User with active subscription (use `test+pro@yarda.app`)

**Steps:**
1. Login as `test+pro@yarda.app`
2. Navigate to `/account` or `/settings`
3. Locate "Manage Subscription" button
4. Click button
5. Verify redirect to Stripe Customer Portal
6. Review subscription details

**Expected Results:**
- [ ] "Manage Subscription" button visible
- [ ] Redirect to `billing.stripe.com/p/login/...`
- [ ] Customer Portal loads
- [ ] Can view subscription details
- [ ] Can update payment method
- [ ] Can cancel subscription

**⚠️ WARNING: Do NOT actually cancel the test subscription unless you plan to recreate it**

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Portal Accessible: [ ] Yes  [ ] No
Subscription Details Shown: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

## 🟡 P2 - PREMIUM FEATURES

---

## Suite 7: Pro Mode 2D Site Plan Generation (P2)

**Business Impact:** Premium feature quality and user experience
**Automated Test:** `frontend/tests/e2e/pro-mode-full-generation.spec.ts`
**Time:** 20 minutes

### Test 7.1: Pro Mode 2D Site Plan Generation

**Objective:** Generate professional 2D CAD blueprint

**Prerequisites:** Login as `test+pro@yarda.app` (Pro access + G3P credits)

**Steps:**
1. Navigate to `/pro-mode`
2. Enter address: "2164 Lakewood Ct, San Jose, CA 95131"
3. Wait for 3D tiles to load
4. Verify camera auto-positions to front view
5. Select "Front Yard" area
6. Add design elements:
   - Click "Patio" (14x16 ft)
   - Click "Walkway"
   - Click "Landscape Beds"
7. Review camera position (should show front of house)
8. Click "Generate Site Plan"
9. Wait for SSE streaming progress
10. Verify 2D CAD blueprint appears

**Expected Results:**
- [ ] 3D tiles load within 10 seconds
- [ ] Camera auto-positions correctly (front view)
- [ ] Design elements selectable
- [ ] SSE progress shows:
  1. "Analyzing property..."
  2. "Generating site plan..."
  3. "Finalizing design..."
- [ ] 2D blueprint appears within 2 minutes
- [ ] Blueprint is professional CAD-style
- [ ] Shows measurements and labels
- [ ] Download button works
- [ ] G3P credits deducted (check backend)

**Verification:**
```sql
SELECT g3p_credits
FROM users
WHERE email = 'test+pro@yarda.app';
-- Should be reduced by 1
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
3D Tiles Loaded: [ ] Yes  [ ] No (time: _____ sec)
Camera Position: [ ] Correct  [ ] Incorrect
Generation Time: _____ minutes
Blueprint Quality: [ ] Professional  [ ] Poor
G3P Deducted: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

## Suite 8: Partner Lead Notifications (P2)

**Business Impact:** Partner engagement and lead conversion
**Automated Test:** `frontend/tests/e2e/marketplace-lead-notifications.spec.ts`
**Time:** 10 minutes

### Test 8.1: Partner Receives Lead Notification Email

**Objective:** Partner receives email when new lead is submitted in their area

**Prerequisites:**
- Partner user in database covering ZIP 94102
- Homeowner submits lead request

**Steps:**
1. Login as homeowner (any account)
2. Navigate to marketplace/submit lead
3. Fill lead form:
   - **Address:** "123 Main St, San Francisco, CA 94102"
   - **Project Type:** "Patio Installation"
   - **Budget:** "$5,000 - $10,000"
4. Submit lead
5. Wait 1 minute
6. Check partner email inbox (`test+partner@yarda.app`)

**Expected Results:**
- [ ] Lead submitted successfully
- [ ] Partner email received within 60 seconds
- [ ] Email from: "Yarda <admin@yarda.pro>"
- [ ] Email contains:
  - [ ] Lead details (address, project type, budget)
  - [ ] "View Lead" CTA
  - [ ] Homeowner contact info (if applicable)
- [ ] CTA redirects to partner dashboard

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Lead Submitted: [ ] Yes  [ ] No
Email Received: [ ] Yes  [ ] No (time: _____ sec)
Email Content Correct: [ ] Yes  [ ] No
CTA Works: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

## 🟢 P3 - STANDARD FEATURES

These features have existing automated E2E test coverage. Manual testing is optional.

---

## Suite 9: Authentication & Registration (P3)

**Note:** These features have automated E2E test coverage. Manual testing is optional.
**Automated Tests:** `frontend/tests/e2e/auth/*.spec.ts`
**Time:** 15 minutes (if manual testing required)

### Test 9.1: Anonymous User Access

**Objective:** Verify anonymous users can only access public pages

**Prerequisites:** None (no login required)

**Steps:**
1. Open browser in incognito mode
2. Navigate to `https://yarda.pro`
3. Verify landing page loads
4. Click "Get Started Free"
5. Verify redirected to `/login` or `/auth`

**Expected Results:**
- [ ] Landing page accessible
- [ ] "Get Started" redirects to login
- [ ] Cannot access `/generate` without login
- [ ] Cannot access `/pro-mode` without login
- [ ] CAN access `/holiday` (public feature)

**Test Results:** `Status: [ ] PASS  [ ] FAIL  [ ] SKIP`

---

### Test 9.2: Google OAuth Sign-In

**Objective:** New user signs up via Google OAuth

**Prerequisites:** Gmail account not previously registered with Yarda

**Steps:**
1. Navigate to `https://yarda.pro/login`
2. Click "Continue with Google"
3. Select Google account
4. Grant permissions
5. Verify redirected to `/generate`
6. Check top-right corner for user info

**Expected Results:**
- [ ] Google OAuth popup appears
- [ ] After approval, redirected to `/generate`
- [ ] User sees "3 trial credits" badge
- [ ] User email displayed in navigation
- [ ] User can start generating immediately

**Verification:**
```sql
-- Check user was created in database
SELECT id, email, trial_remaining, created_at
FROM users
WHERE email = 'YOUR_GOOGLE_EMAIL@gmail.com';

-- Should show:
-- trial_remaining = 3
-- created_at = recent timestamp
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Google Email Used: _______________________________
User ID Created: _________________________________
Notes: ___________________________________________
```

---

### Test 1.3: Magic Link Authentication

**Objective:** Passwordless login via email magic link

**Prerequisites:** Email account with access to inbox

**Steps:**
1. Navigate to `/login`
2. Enter email: `test+magiclink@yarda.app`
3. Click "Send Magic Link"
4. Verify success message
5. Check email inbox
6. Click magic link in email
7. Verify logged in to app

**Expected Results:**
- [ ] "Magic link sent" success message
- [ ] Email received within 1 minute
- [ ] Email from "Yarda <admin@yarda.pro>"
- [ ] Click link → automatically logged in
- [ ] Redirected to `/generate`

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Email Received: [ ] Yes  [ ] No
Time to Receive: _______ seconds
Magic Link Worked: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 1.4: Email/Password Registration

**Objective:** Traditional signup with email/password

**Prerequisites:** Unique email not in system

**Steps:**
1. Navigate to `/signup`
2. Enter email: `test+emailpw${DATE}@yarda.app`
3. Enter password: `SecurePass123!`
4. Click "Sign Up"
5. Check email for verification
6. Click verification link
7. Login with credentials

**Expected Results:**
- [ ] Registration form validates inputs
- [ ] Password requirements shown
- [ ] Verification email sent
- [ ] Account activated after verification
- [ ] Can login with email/password

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Notes: ___________________________________________
```

---

## Suite 10: Trial User Experience (P3 - CUJ-1)

**Note:** Trial flow has automated E2E test coverage. Manual testing is optional.
**Automated Tests:** `frontend/tests/e2e/trial/*.spec.ts`
**Time:** 15 minutes (if manual testing required)

### Test 10.1: Trial Credit Display

**Objective:** Verify trial user sees 3 credits after signup

**Prerequisites:** Login as `test+trial@yarda.app`

**Steps:**
1. Login to account
2. Navigate to `/generate`
3. Look for credit badge in navigation

**Expected Results:**
- [ ] Badge shows "3 trial credits" or similar
- [ ] Credit count is prominently displayed
- [ ] Generate button is enabled

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Credit Count Shown: _____
Notes: ___________________________________________
```

---

### Test 2.2: First Generation with Trial Credit

**Objective:** User generates landscape design using trial credit

**Prerequisites:** Login as `test+trial@yarda.app` (3 credits)

**Steps:**
1. Navigate to `/generate`
2. Fill in form:
   - **Address:** "123 Main St, San Francisco, CA 94102"
   - **Area:** Click "Front Yard"
   - **Style:** Click "Modern Minimalist"
3. Click "Generate Landscape Design"
4. Wait for generation to complete (~2-3 minutes)
5. Verify results displayed

**Expected Results:**
- [ ] Form accepts all inputs
- [ ] Generate button becomes active when form complete
- [ ] Toast notification: "Generation started"
- [ ] Progress indicator appears
- [ ] No page navigation occurs (stays on `/generate`)
- [ ] Results displayed inline after ~2-3 min
- [ ] 3 design variations shown
- [ ] Download buttons work for each image
- [ ] Credits updated: **3 → 2**

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Generation Time: _______ minutes
Credits After: _____
Number of Images: _____
Download Worked: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 2.3: Trial Credit Deduction Verification

**Objective:** Verify trial credits decrease after each generation

**Prerequisites:** Login as `test+trial@yarda.app`

**Steps:**
1. Note current credit count (should be 3)
2. Complete one generation (see Test 2.2)
3. Check credit count → should be 2
4. Complete second generation
5. Check credit count → should be 1
6. Complete third generation
7. Check credit count → should be 0

**Expected Results:**
- [ ] Credits decrease by 1 after each generation
- [ ] Credit display updates immediately after generation starts
- [ ] Backend database matches frontend display

**Verification:**
```sql
SELECT trial_remaining, trial_used
FROM users
WHERE email = 'test+trial@yarda.app';

-- After 3 generations:
-- trial_remaining = 0
-- trial_used = 3
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Credits After Gen 1: _____
Credits After Gen 2: _____
Credits After Gen 3: _____
Notes: ___________________________________________
```

---

## Suite 3: Trial Exhaustion & Purchase Flow (CUJ-6)

### Test 3.1: Zero Credits Purchase Modal

**Objective:** User with 0 credits sees purchase modal

**Prerequisites:** Login as `test+nocredit@yarda.app` (0 credits)

**Steps:**
1. Navigate to `/generate`
2. Fill in generation form
3. Attempt to click "Generate" button

**Expected Results:**
- [ ] Generate button is **disabled**
- [ ] Tooltip or message: "No credits remaining"
- [ ] "Buy Credits" button or link visible
- [ ] Click "Buy Credits" → redirects to `/pricing`

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Generate Button State: [ ] Disabled  [ ] Enabled
Purchase CTA Visible: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 3.2: Token Purchase via Stripe (CUJ-4)

**Objective:** User purchases one-time tokens via Stripe

**Prerequisites:** Login as `test+nocredit@yarda.app`

**Steps:**
1. Navigate to `/pricing`
2. Locate "Buy 5 Credits - $10" option
3. Click "Purchase"
4. Verify redirect to Stripe Checkout
5. Fill Stripe test card:
   - **Card:** 4242 4242 4242 4242
   - **Expiry:** 12/34
   - **CVC:** 123
   - **Name:** Test User
6. Click "Pay"
7. Wait for redirect back to app
8. Verify credits added

**Expected Results:**
- [ ] Redirected to `checkout.stripe.com`
- [ ] Stripe Checkout loads correctly
- [ ] Test card accepted
- [ ] Redirect to `/success` or `/generate`
- [ ] Credits updated: **0 → 5** (within 10 seconds)
- [ ] Can now generate designs

**Verification:**
```sql
SELECT tokens_purchased, tokens_used
FROM users
WHERE email = 'test+nocredit@yarda.app';

-- Should show tokens_purchased = 5
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Stripe Checkout Loaded: [ ] Yes  [ ] No
Payment Successful: [ ] Yes  [ ] No
Credits Added: [ ] Yes  [ ] No (took ____ seconds)
Final Credit Balance: _____
Notes: ___________________________________________
```

---

### Test 3.3: Subscription Purchase (CUJ-5)

**Objective:** User subscribes to monthly Pro plan

**Prerequisites:** Login as `test+nocredit@yarda.app`

**Steps:**
1. Navigate to `/pricing`
2. Locate "Pro Plan - $25/month"
3. Click "Subscribe"
4. Complete Stripe Checkout (same card as Test 3.2)
5. Verify subscription activated
6. Check credits added immediately

**Expected Results:**
- [ ] Redirected to Stripe Checkout
- [ ] Subscription payment successful
- [ ] **20 credits** added immediately
- [ ] Badge shows "Pro" or "Unlimited"
- [ ] Can access Pro Mode at `/pro-mode`
- [ ] G3P credits granted for Pro Mode

**Verification:**
```sql
SELECT subscription_status, subscription_credits, g3p_credits, stripe_subscription_id
FROM users
WHERE email = 'test+nocredit@yarda.app';

-- Should show:
-- subscription_status = 'active'
-- subscription_credits = 20
-- g3p_credits > 0
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Subscription Activated: [ ] Yes  [ ] No
Credits Added: _____ (expected: 20)
G3P Credits Added: _____ (expected: >0)
Pro Badge Visible: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 3.4: Customer Portal Access

**Objective:** User can manage subscription via Customer Portal

**Prerequisites:** User with active subscription (use `test+pro@yarda.app`)

**Steps:**
1. Login as `test+pro@yarda.app`
2. Navigate to `/account` or `/settings`
3. Locate "Manage Subscription" button
4. Click button
5. Verify redirect to Stripe Customer Portal
6. Review subscription details
7. (Optional) Cancel subscription

**Expected Results:**
- [ ] "Manage Subscription" button visible
- [ ] Redirect to `billing.stripe.com/p/login/...`
- [ ] Customer Portal loads
- [ ] Can view subscription details
- [ ] Can update payment method
- [ ] Can cancel subscription

**⚠️ WARNING: Do NOT actually cancel the test subscription unless you plan to recreate it**

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Portal Accessible: [ ] Yes  [ ] No
Subscription Details Shown: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

## Suite 11: Standard Landscape Generation (P3)

**Note:** Standard generation flow has automated E2E test coverage. Manual testing is optional.
**Automated Tests:** `frontend/tests/e2e/generation/*.spec.ts`
**Time:** 30 minutes (if manual testing required)

### Test 11.1: Address Input with Google Maps

**Objective:** Google Maps autocomplete works for address entry

**Prerequisites:** Login as any user with credits

**Steps:**
1. Navigate to `/generate`
2. Click into address field
3. Start typing: "123 Main St, San Fr"
4. Verify dropdown suggestions appear
5. Select "123 Main St, San Francisco, CA"
6. Verify address populates

**Expected Results:**
- [ ] Google autocomplete dropdown appears
- [ ] Suggestions match typed text
- [ ] Selecting suggestion fills address field
- [ ] Map preview updates (if visible)

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Autocomplete Worked: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 4.2: Google Maps Satellite Image Selection

**Objective:** User can select property via satellite view

**Prerequisites:** Login with credits

**Steps:**
1. Navigate to `/generate`
2. Click "Use Satellite Image" or "Select from Map"
3. Verify Google Maps loads
4. Search for address: "2164 Lakewood Ct, San Jose, CA 95131"
5. Zoom to property level
6. Verify satellite imagery visible
7. Click to select property
8. Confirm selection

**Expected Results:**
- [ ] Google Maps loads with satellite layer
- [ ] Can search for addresses
- [ ] Satellite imagery shows property clearly
- [ ] Selection tool works
- [ ] Image captured and passed to generation

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Map Loaded: [ ] Yes  [ ] No
Satellite Quality: [ ] Good  [ ] Poor
Selection Worked: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 4.3: All Landscape Styles

**Objective:** Verify all landscape styles generate successfully

**Prerequisites:** Login as `test+token@yarda.app` (5 credits)

**Repeat for each style:**
- Modern Minimalist
- Traditional/Classic
- California Native
- Eco-Friendly
- Low-Maintenance

**Steps:**
1. Navigate to `/generate`
2. Enter address: "123 Test St, San Francisco, CA"
3. Select "Front Yard"
4. Select [STYLE]
5. Generate
6. Verify 3 images generated
7. Verify images match style theme

**Expected Results:**
- [ ] All 5 styles generate successfully
- [ ] Each style produces visually distinct results
- [ ] Generation time: 2-3 minutes per style
- [ ] 3 variations per generation

**Test Results:**
```
Style: Modern Minimalist
Status: [ ] PASS  [ ] FAIL
Time: _____ min

Style: Traditional
Status: [ ] PASS  [ ] FAIL
Time: _____ min

Style: California Native
Status: [ ] PASS  [ ] FAIL
Time: _____ min

Style: Eco-Friendly
Status: [ ] PASS  [ ] FAIL
Time: _____ min

Style: Low-Maintenance
Status: [ ] PASS  [ ] FAIL
Time: _____ min
```

---

### Test 4.4: All Area Types

**Objective:** Verify all area types generate correctly

**Prerequisites:** Login with 3+ credits

**Areas to test:**
- Front Yard
- Backyard
- Side Yard
- Walkway/Path
- Patio Area
- Pool Area

**Steps:**
1. For each area:
   - Navigate to `/generate`
   - Select [AREA]
   - Generate with Modern Minimalist style
   - Verify results appropriate for area type

**Expected Results:**
- [ ] Each area type generates successfully
- [ ] Results contextually appropriate (e.g., pool area includes pool)
- [ ] No errors or failed generations

**Test Results:**
```
Area: Front Yard - [ ] PASS  [ ] FAIL
Area: Backyard - [ ] PASS  [ ] FAIL
Area: Side Yard - [ ] PASS  [ ] FAIL
Area: Walkway - [ ] PASS  [ ] FAIL
Area: Patio - [ ] PASS  [ ] FAIL
Area: Pool Area - [ ] PASS  [ ] FAIL
```

---

## Suite 13: Admin Features (P3)

**Steps:**
1. Login as `test+trial@yarda.app` (no Pro subscription)
2. Navigate to `/pro-mode`

**Expected Results:**
- [ ] Redirected to upgrade page OR
- [ ] See "Upgrade to Pro" modal
- [ ] "Subscribe Now" CTA visible
- [ ] Cannot access Pro Mode features

**Test Case B: Pro User**

**Steps:**
1. Login as `test+pro@yarda.app`
2. Navigate to `/pro-mode`

**Expected Results:**
- [ ] Pro Mode interface loads
- [ ] Camera controls visible
- [ ] Can enter address and proceed

**Test Case C: Partner User**

**Steps:**
1. Login as `test+partner@yarda.app`
2. Navigate to `/pro-mode`

**Expected Results:**
- [ ] Pro Mode accessible (partners get automatic access)
- [ ] Full features available

**Test Results:**
```
Non-Pro Access Blocked: [ ] Yes  [ ] No
Pro User Access: [ ] Yes  [ ] No
Partner Access: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 5.2: Pro Mode 2D Site Plan Generation

**Objective:** Generate professional 2D CAD blueprint

**Prerequisites:** Login as `test+pro@yarda.app` (Pro access + G3P credits)

**Steps:**
1. Navigate to `/pro-mode`
2. Enter address: "2164 Lakewood Ct, San Jose, CA 95131"
3. Wait for 3D tiles to load
4. Verify camera auto-positions to front view
5. Select "Front Yard" area
6. Add design elements:
   - Click "Patio" (14x16 ft)
   - Click "Walkway"
   - Click "Landscape Beds"
7. Review camera position (should show front of house)
8. Click "Generate Site Plan"
9. Wait for SSE streaming progress
10. Verify 2D CAD blueprint appears

**Expected Results:**
- [ ] 3D tiles load within 10 seconds
- [ ] Camera auto-positions correctly (front view)
- [ ] Design elements selectable
- [ ] SSE progress shows:
  1. "Analyzing property..."
  2. "Generating site plan..."
  3. "Finalizing design..."
- [ ] 2D blueprint appears within 2 minutes
- [ ] Blueprint is professional CAD-style
- [ ] Shows measurements and labels
- [ ] Download button works
- [ ] G3P credits deducted (check backend)

**Verification:**
```sql
SELECT g3p_credits
FROM users
WHERE email = 'test+pro@yarda.app';
-- Should be reduced by 1
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
3D Tiles Loaded: [ ] Yes  [ ] No (time: _____ sec)
Camera Position: [ ] Correct  [ ] Incorrect
Generation Time: _____ minutes
Blueprint Quality: [ ] Professional  [ ] Poor
G3P Deducted: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 5.3: Auto-Camera Positioning Accuracy

**Objective:** Verify camera auto-positions to front of house correctly

**Prerequisites:** Login as `test+pro@yarda.app`

**Test Addresses:**

| Address | Type | Expected Heading Source |
|---------|------|------------------------|
| 2164 Lakewood Ct, San Jose, CA | Standard lot | Street View metadata |
| 1234 Main St & Oak, Cupertino, CA | Corner lot | Gemini satellite |
| 5678 Circle Dr, Los Altos, CA | Cul-de-sac | Gemini satellite |

**Steps:**
1. For each address:
   - Navigate to `/pro-mode`
   - Enter address
   - Wait for camera auto-positioning
   - Check heading source indicator
   - Verify front of house visible in 3D view

**Expected Results:**
- [ ] Standard lot: Uses Street View metadata (HIGH confidence)
- [ ] Corner lot: Uses Gemini (overrides Street View) (MEDIUM confidence)
- [ ] Cul-de-sac: Uses Gemini or default (MEDIUM/LOW confidence)
- [ ] Front of house always visible in camera view

**Test Results:**
```
Standard Lot:
  Heading Source: _________________
  Confidence: _____
  Front Visible: [ ] Yes  [ ] No

Corner Lot:
  Heading Source: _________________
  Confidence: _____
  Front Visible: [ ] Yes  [ ] No

Cul-de-sac:
  Heading Source: _________________
  Confidence: _____
  Front Visible: [ ] Yes  [ ] No
```

---

## Suite 6: Partner Features

### Test 6.1: Partner Signup Flow

**Objective:** New partner signs up and receives welcome email

**Prerequisites:** Unique email not in system

**Steps:**
1. Navigate to `/partner/profile`
2. Fill partner signup form:
   - **Business Name:** "Test Landscaping Co"
   - **Contact Name:** "Test Partner"
   - **Email:** `test+newpartner${DATE}@yarda.app`
   - **Phone:** "555-1234"
   - **ZIP Code:** "90210"
   - **State:** California
   - **Services:** Check "Hardscaping" and "Softscaping"
3. Check disclaimers and terms checkboxes
4. Click "Submit"
5. Verify success message
6. Check email inbox for welcome email

**Expected Results:**
- [ ] Form validation works (required fields)
- [ ] Submit button enables when form complete
- [ ] Success message: "Check your email..."
- [ ] Welcome email received within 1 minute
- [ ] Email from: "Yarda <admin@yarda.pro>"
- [ ] Email subject: "🎉 You're In! Start Receiving Pre-Qualified Leads Today"
- [ ] Email contains:
  - [ ] Business name ("Test Landscaping Co")
  - [ ] Contact name ("Test Partner")
  - [ ] CTA: "Complete Profile Now"
  - [ ] CTA: "View Partner Dashboard"
  - [ ] CTA: "Explore Pro Mode"
  - [ ] Pro tip about 15-min response time
  - [ ] 5-minute quick start checklist
- [ ] All CTAs clickable and link to correct pages

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Email Received: [ ] Yes  [ ] No (time: _____ sec)
Email From: _______________________________
All CTAs Work: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 6.2: Existing User Partner Conversion

**Objective:** Existing Yarda user converts to partner

**Prerequisites:** Login as `test+trial@yarda.app`

**Steps:**
1. Login to existing account
2. Navigate to `/partner/profile`
3. Fill partner form (same as Test 6.1)
4. Submit

**Expected Results:**
- [ ] System detects existing user
- [ ] Profile linked to existing account
- [ ] Welcome email sent
- [ ] Can access both homeowner features AND partner dashboard

**Verification:**
```sql
SELECT u.email, c.business_name, c.status
FROM users u
JOIN marketplace_contractors c ON c.user_id = u.id
WHERE u.email = 'test+trial@yarda.app';

-- Should return 1 row with contractor profile
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Existing User Detected: [ ] Yes  [ ] No
Profile Created: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 6.3: Partner Dashboard Access

**Objective:** Verified partner can access dashboard and view leads

**Prerequisites:** Login as `test+partner@yarda.app`

**Steps:**
1. Navigate to `/partner/dashboard`
2. Verify dashboard loads
3. Check sections visible:
   - Active Leads
   - Pending Estimates
   - Profile Completeness
   - Service Areas

**Expected Results:**
- [ ] Dashboard loads without errors
- [ ] All sections visible
- [ ] Can view lead list (may be empty)
- [ ] Can navigate to profile settings

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Dashboard Loaded: [ ] Yes  [ ] No
Sections Visible: _____/4
Notes: ___________________________________________
```

---

### Test 6.4: Partner Receives Lead Notification Email

**Objective:** Partner receives email when new lead is submitted in their area

**Prerequisites:**
- Partner user in database covering ZIP 94102
- Homeowner submits lead request

**Steps:**
1. Login as homeowner (any account)
2. Navigate to marketplace/submit lead
3. Fill lead form:
   - **Address:** "123 Main St, San Francisco, CA 94102"
   - **Project Type:** "Patio Installation"
   - **Budget:** "$5,000 - $10,000"
4. Submit lead
5. Wait 1 minute
6. Check partner email inbox (`test+partner@yarda.app`)

**Expected Results:**
- [ ] Lead submitted successfully
- [ ] Partner email received within 60 seconds
- [ ] Email from: "Yarda <admin@yarda.pro>"
- [ ] Email contains:
  - [ ] Lead details (address, project type, budget)
  - [ ] "View Lead" CTA
  - [ ] Homeowner contact info (if applicable)
- [ ] CTA redirects to partner dashboard

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Lead Submitted: [ ] Yes  [ ] No
Email Received: [ ] Yes  [ ] No (time: _____ sec)
Email Content Correct: [ ] Yes  [ ] No
CTA Works: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

## Suite 12: Holiday Decorator (P3 - CUJ-7)

**Note:** Holiday feature has automated E2E test coverage. Manual testing is optional.
**Automated Tests:** `frontend/tests/e2e/holiday/*.spec.ts`
**Time:** 15 minutes (if manual testing required)

### Test 12.1: Holiday Decorator Basic Generation

**Objective:** User generates holiday-decorated home image

**Prerequisites:** Login as any user (or anonymous if allowed)

**Steps:**
1. Navigate to `/holiday`
2. Enter address: "321 Maple Dr, Boston, MA"
3. Select holiday style: "Classic Christmas"
4. Click "Generate Decoration"
5. Wait for generation
6. Verify decorated image appears

**Expected Results:**
- [ ] Holiday page loads
- [ ] Styles available: Classic Christmas, Winter Wonderland, etc.
- [ ] Generation starts
- [ ] Decorated image shows holiday elements
- [ ] Share button visible

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Generation Time: _____ minutes
Holiday Elements: [ ] Present  [ ] Missing
Share Button: [ ] Visible  [ ] Hidden
Notes: ___________________________________________
```

---

### Test 7.2: Social Sharing for Bonus Credits

**Objective:** User shares holiday design and earns credit after 3 referrals

**Prerequisites:** Login as `test+trial@yarda.app`

**Steps:**
1. Complete Test 7.1 (generate holiday design)
2. Click "Share" button
3. Verify share modal opens
4. Copy share link
5. Verify link contains referral tracking parameter
6. Open link in 3 different incognito windows
7. Complete generation in each window
8. Check original user's credits

**Expected Results:**
- [ ] Share modal opens with options (Facebook, Twitter, Copy Link)
- [ ] Link contains `?ref=USER_ID` parameter
- [ ] After 3 referrals complete generation:
  - [ ] Original user receives +1 bonus credit
  - [ ] Notification shown to original user

**Verification:**
```sql
SELECT holiday_credits, referral_count
FROM users
WHERE email = 'test+trial@yarda.app';

-- After 3 referrals: holiday_credits += 1
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Share Link Generated: [ ] Yes  [ ] No
Referral Param Present: [ ] Yes  [ ] No
Bonus Credit Awarded: [ ] Yes  [ ] No (after ____ referrals)
Notes: ___________________________________________
```

---

## Suite 8: Abandoned Checkout Recovery

### Test 8.1: Abandoned Subscription Checkout

**Objective:** User starts subscription checkout but abandons, receives recovery email

**Prerequisites:** Login as `test+nocredit@yarda.app`

**Steps:**
1. Navigate to `/pricing`
2. Click "Subscribe - $25/month"
3. Redirected to Stripe Checkout
4. DO NOT complete payment - close browser tab
5. Wait 1 hour (or manually trigger cron: `python scripts/send_recovery_emails.py`)
6. Check email inbox

**Expected Results:**
- [ ] Abandoned checkout tracked in database
- [ ] Recovery email received after 1 hour
- [ ] Email from: "Yarda <admin@yarda.pro>"
- [ ] Email subject mentions subscription
- [ ] Email contains:
  - [ ] Plan details (Monthly Pro, $25/month)
  - [ ] Resume checkout CTA
  - [ ] Benefits reminder
- [ ] Resume link works and opens Stripe Checkout

**Verification:**
```sql
SELECT * FROM abandoned_checkouts
WHERE user_id = (SELECT id FROM users WHERE email = 'test+nocredit@yarda.app')
  AND NOT completed
ORDER BY created_at DESC
LIMIT 1;

-- Should show:
-- recovery_email_sent = TRUE
-- reminder_email_sent = FALSE (if not 24h yet)
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Checkout Tracked: [ ] Yes  [ ] No
Recovery Email Received: [ ] Yes  [ ] No (time: _____)
Resume Link Works: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 8.2: Abandoned Token Purchase

**Objective:** Similar to Test 8.1 but for one-time token purchase

**Steps:**
1. Start token purchase ($10 for 5 credits)
2. Abandon at Stripe Checkout
3. Wait 1 hour
4. Check email

**Expected Results:**
- [ ] Recovery email received
- [ ] Email subject mentions credits/tokens
- [ ] Resume link works

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Notes: ___________________________________________
```

---

### Test 8.3: Reminder Email (24 Hours)

**Objective:** User receives reminder email 24h after recovery email if still not completed

**Prerequisites:** Abandoned checkout from 25+ hours ago

**Steps:**
1. Create abandoned checkout (from Test 8.1)
2. Receive recovery email (1 hour)
3. Do NOT complete checkout
4. Wait 24 hours (or manually trigger cron again)
5. Check email for reminder

**Expected Results:**
- [ ] Reminder email received 24h after recovery email
- [ ] Different messaging than recovery email
- [ ] Only sent for subscriptions (not tokens)
- [ ] Resume link still works

**Verification:**
```sql
SELECT recovery_email_sent, recovery_email_sent_at,
       reminder_email_sent, reminder_email_sent_at
FROM abandoned_checkouts
WHERE ...;

-- Both should be TRUE
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Reminder Email Received: [ ] Yes  [ ] No (time: _____)
Different Messaging: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

## Suite 13: Admin Features (P3)

**Note:** Admin features have automated coverage. Manual testing is optional.
**Automated Tests:** `frontend/tests/e2e/admin/*.spec.ts`
**Time:** 10 minutes (if manual testing required)

### Test 13.1: Admin Dashboard Access

**Objective:** Admin can access admin-only features

**Prerequisites:** Login as `admin@yarda.app`

**Steps:**
1. Navigate to `/admin/camera-playground`
2. Verify camera playground loads
3. Navigate to `/playground/learning-db`
4. Verify learning database viewer loads

**Expected Results:**
- [ ] Admin can access both pages
- [ ] Camera playground functional
- [ ] Learning DB shows camera parameter records

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Camera Playground: [ ] Accessible  [ ] Blocked
Learning DB: [ ] Accessible  [ ] Blocked
Notes: ___________________________________________
```

---

### Test 9.2: Grant Pro Access (Admin Tool)

**Objective:** Admin can manually grant Pro Mode access to users

**Prerequisites:** Login as `admin@yarda.app`

**Steps:**
1. Run backend script:
   ```bash
   cd backend
   source venv/bin/activate
   python scripts/grant_pro_access.py --email test+trial@yarda.app --credits 10
   ```
2. Verify script output shows success
3. Login as `test+trial@yarda.app`
4. Navigate to `/pro-mode`
5. Verify Pro Mode accessible

**Expected Results:**
- [ ] Script runs without errors
- [ ] G3P credits granted (10 credits)
- [ ] User can access Pro Mode
- [ ] Pro badge visible in navigation

**Verification:**
```sql
SELECT g3p_credits
FROM users
WHERE email = 'test+trial@yarda.app';

-- Should show g3p_credits = 10
```

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Script Successful: [ ] Yes  [ ] No
Credits Granted: [ ] Yes  [ ] No
Pro Mode Accessible: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

## Suite 14: Error Handling & Edge Cases (P3)

**Note:** Error handling has automated coverage. Manual testing is optional.
**Automated Tests:** `frontend/tests/e2e/errors/*.spec.ts`
**Time:** 15 minutes (if manual testing required)

### Test 14.1: Generation Failure Refund

**Objective:** Credits refunded if generation fails

**Prerequisites:** Login as `test+trial@yarda.app`

**Steps:**
1. Note current credit count
2. Start generation with invalid parameters (if possible) OR
3. Manually trigger backend failure (admin access required)
4. Verify error shown to user
5. Check credit count

**Expected Results:**
- [ ] Error message shown
- [ ] Credits refunded (count restored)
- [ ] Error logged in backend

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Error Shown: [ ] Yes  [ ] No
Credits Refunded: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 10.2: Expired Checkout Session

**Objective:** Verify checkout sessions expire after 24 hours

**Prerequisites:** Abandoned checkout >24 hours old

**Steps:**
1. Create abandoned checkout
2. Wait 24 hours
3. Attempt to resume checkout via recovery email link

**Expected Results:**
- [ ] Stripe shows "Session expired"
- [ ] User prompted to start new checkout
- [ ] No recovery emails sent after expiration

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Session Expired: [ ] Yes  [ ] No
New Checkout Required: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

### Test 10.3: Network Timeout Handling

**Objective:** App handles network timeouts gracefully

**Prerequisites:** Login as any user

**Steps:**
1. Start generation
2. Disable network (airplane mode or kill WiFi)
3. Wait for timeout
4. Verify error shown
5. Re-enable network
6. Retry generation

**Expected Results:**
- [ ] Timeout error shown (not infinite loading)
- [ ] User can retry
- [ ] Credits not lost

**Test Results:**
```
Status: [ ] PASS  [ ] FAIL  [ ] SKIP
Timeout Handled: [ ] Yes  [ ] No
Retry Works: [ ] Yes  [ ] No
Notes: ___________________________________________
```

---

## Test Summary Report

### Test Execution Summary

**Date:** _______________
**Tester:** _______________
**Environment:** [ ] Production  [ ] Staging  [ ] Local
**Test Level:** [ ] P0 Only (30 min)  [ ] P0+P1 (2 hr)  [ ] Full (4+ hr)

### Priority-Based Results

**🔴 P0 - Critical Revenue Protection (REQUIRED FOR EVERY DEPLOYMENT)**

| Suite | Tests | Passed | Failed | Skipped | Time |
|-------|-------|--------|--------|---------|------|
| 1. Partner Signup & Email | 2 | ___ | ___ | ___ | ___ min |
| 2. Subscription Flow | 1 | ___ | ___ | ___ | ___ min |
| 3. Pro Mode Access Control | 4 | ___ | ___ | ___ | ___ min |
| **P0 SUBTOTAL** | **7** | **___** | **___** | **___** | **___** min |

**P0 Pass Rate:** ______% (MUST BE 100% to deploy)

---

**🟠 P1 - High Priority Business Features (REQUIRED BEFORE PRODUCTION DEPLOY)**

| Suite | Tests | Passed | Failed | Skipped | Time |
|-------|-------|--------|--------|---------|------|
| 4. Token Purchase Flow | 1 | ___ | ___ | ___ | ___ min |
| 5. Abandoned Checkout Recovery | 1 | ___ | ___ | ___ | ___ min |
| 6. Customer Portal Access | 1 | ___ | ___ | ___ | ___ min |
| **P1 SUBTOTAL** | **3** | **___** | **___** | **___** | **___** min |

**P1 Pass Rate:** ______% (Target: >95%)

---

**🟡 P2 - Premium Features (RECOMMENDED FOR MAJOR RELEASES)**

| Suite | Tests | Passed | Failed | Skipped | Time |
|-------|-------|--------|--------|---------|------|
| 7. Pro Mode 2D Site Plan | 1 | ___ | ___ | ___ | ___ min |
| 8. Partner Lead Notifications | 1 | ___ | ___ | ___ | ___ min |
| **P2 SUBTOTAL** | **2** | **___** | **___** | **___** | **___** min |

**P2 Pass Rate:** ______% (Target: >90%)

---

**🟢 P3 - Standard Features (OPTIONAL - HAS AUTOMATED COVERAGE)**

| Suite | Tests | Passed | Failed | Skipped | Time |
|-------|-------|--------|--------|---------|------|
| 9. Authentication & Registration | ~4 | ___ | ___ | ___ | ___ min |
| 10. Trial User Experience | ~3 | ___ | ___ | ___ | ___ min |
| 11. Standard Landscape Generation | ~3 | ___ | ___ | ___ | ___ min |
| 12. Holiday Decorator | ~2 | ___ | ___ | ___ | ___ min |
| 13. Admin Features | ~2 | ___ | ___ | ___ | ___ min |
| 14. Error Handling & Edge Cases | ~3 | ___ | ___ | ___ | ___ min |
| **P3 SUBTOTAL** | **~17** | **___** | **___** | **___** | **___** min |

**P3 Pass Rate:** ______% (Target: >85%, has automated E2E coverage)

---

**GRAND TOTAL**

| Priority | Tests | Passed | Failed | Skipped | Pass Rate | Status |
|----------|-------|--------|--------|---------|-----------|--------|
| P0 (Critical) | 7 | ___ | ___ | ___ | ___% | [ ] ✅ PASS  [ ] ❌ BLOCK |
| P1 (High) | 3 | ___ | ___ | ___ | ___% | [ ] ✅ PASS  [ ] ⚠️ WARNING |
| P2 (Medium) | 2 | ___ | ___ | ___ | ___% | [ ] ✅ PASS  [ ] ⏭️ SKIP |
| P3 (Low) | ~17 | ___ | ___ | ___ | ___% | [ ] ✅ PASS  [ ] ⏭️ SKIP |
| **TOTAL** | **~29** | **___** | **___** | **___** | **___% ** | |

**Overall Pass Rate:** ______%

**Deployment Decision:**
- [ ] ✅ **APPROVED FOR DEPLOYMENT** - All P0 tests pass, P1 >95%
- [ ] ⚠️ **APPROVED WITH WARNINGS** - All P0 pass, but P1 <95%
- [ ] ❌ **BLOCKED** - Any P0 test failures

### Critical Issues Found

1. _______________________________________________________
2. _______________________________________________________
3. _______________________________________________________

### Recommendations

1. _______________________________________________________
2. _______________________________________________________
3. _______________________________________________________

### Sign-off

**Tester Signature:** ___________________  **Date:** _______________

**Product Manager Approval:** ___________________  **Date:** _______________

---

## Appendix A: Test Data Cleanup

After testing, reset test users to clean state:

```sql
-- Reset trial user
UPDATE users SET trial_remaining = 3, trial_used = 0
WHERE email = 'test+trial@yarda.app';

-- Reset token user
UPDATE users SET tokens_purchased = 5, tokens_used = 0
WHERE email = 'test+token@yarda.app';

-- Reset zero-credit user
UPDATE users SET trial_remaining = 0, trial_used = 3, tokens_purchased = 0
WHERE email = 'test+nocredit@yarda.app';

-- Clear abandoned checkouts
DELETE FROM abandoned_checkouts
WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE 'test+%@yarda.app'
);

-- Clear test generations (optional)
DELETE FROM generations
WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE 'test+%@yarda.app'
)
AND created_at < NOW() - INTERVAL '7 days';
```

---

## Appendix B: Known Issues & Workarounds

### Issue 1: Stripe Test Mode Not Configured

**Symptom:** Cannot complete payment tests (Tests 3.2, 3.3)

**Workaround:** Skip payment tests or use production Stripe with refunds

**Fix:** Configure Stripe test mode in environment variables

### Issue 2: Magic Link Emails Delayed

**Symptom:** Magic link emails take >5 minutes to arrive

**Workaround:** Check spam folder, use email/password instead

**Fix:** Verify Supabase SMTP configuration

---

**End of Manual Testing Guide**
