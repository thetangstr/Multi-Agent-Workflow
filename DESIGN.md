# Design System: Yarda AI Landscape Studio

**Project:** Yarda v5 (yarda.pro)
**Last Updated:** 2026-02-02
**Purpose:** Source of truth for AI-generated UI screens via Stitch

---

## 1. Visual Theme & Atmosphere

**Mood:** Warm, organic, professional, trustworthy
**Aesthetic:** Modern minimalism with natural earth tones
**Density:** Airy and spacious with generous whitespace
**Character:** Approachable yet professional - a blend of friendly SaaS and premium landscape design

The design evokes the feeling of a well-maintained garden: organized, natural, and calming. Interfaces feel light and breathable, never cramped or overwhelming.

---

## 2. Color Palette & Roles

### Primary Brand Colors

| Name | Hex | Role |
|------|-----|------|
| **Sage Green** | `#5A6C4D` | Primary brand color, main CTAs, key actions |
| **Dark Forest** | `#3D4A36` | Hover states, emphasis, dark UI elements |
| **Warm Cream** | `#F5F3F0` | Page backgrounds, breathing room |
| **Light Sage** | `#F0F4ED` | Secondary backgrounds, subtle highlights |
| **Soft Sage** | `#E8EDE5` | Card backgrounds, surface differentiation |

### Buffer-Inspired Palette (Light Theme)

| Name | Hex | Role |
|------|-----|------|
| **Off-White Canvas** | `#FAFAF8` | Main page background |
| **Warm Stone** | `#F5F3F0` | Cards and elevated surfaces |
| **Pure White** | `#FFFFFF` | Input fields, modal backgrounds |
| **Golden Cream** | `#FEF3E2` | Hero sections, accent areas, highlights |
| **Forest Green** | `#2D8B5D` | Primary buttons, success states |
| **Deep Green** | `#236B48` | Button hover states |
| **Darkest Green** | `#1A5038` | Button active/pressed states |

### Accent Colors (Pastels)

| Name | Hex | Role |
|------|-----|------|
| **Soft Coral** | `#F5A89A` | Decorative accents, illustrations |
| **Coral Mist** | `#FDE8E4` | Coral background tints |
| **Lavender** | `#D6C8FF` | Pro/premium features, special badges |
| **Lavender Mist** | `#F3EFFF` | Lavender background tints |
| **Sunshine** | `#F9E79F` | Warnings, highlights, attention |
| **Sunshine Mist** | `#FEF9E7` | Yellow background tints |
| **Sky Blue** | `#93C5FD` | Info states, links, secondary actions |
| **Sky Mist** | `#EFF6FF` | Blue background tints |

### Text Hierarchy

| Name | Hex | Role |
|------|-----|------|
| **Primary Text** | `#1F2937` | Headlines, body text, key content |
| **Secondary Text** | `#4B5563` | Subheadings, descriptions |
| **Tertiary Text** | `#6B7280` | Captions, helper text |
| **Muted Text** | `#9CA3AF` | Placeholders, disabled states |

### Semantic Colors

| State | Light | Medium | Dark | Role |
|-------|-------|--------|------|------|
| **Success** | `#ECFDF5` | `#10B981` | `#047857` | Confirmations, completed states |
| **Warning** | `#FEF3C7` | `#F59E0B` | `#B45309` | Cautions, important notices |
| **Error** | `#FEE2E2` | `#EF4444` | `#B91C1C` | Errors, destructive actions |

### Borders

| Name | Hex | Role |
|------|-----|------|
| **Light Border** | `#E5E7EB` | Subtle dividers, card borders |
| **Medium Border** | `#D1D5DB` | Input borders, stronger separation |

---

## 3. Typography Rules

### Font Families

| Type | Family | Character |
|------|--------|-----------|
| **Body** | Poppins | Clean, modern, highly readable geometric sans-serif |
| **Display** | Playfair Display | Elegant serif for premium headlines and hero text |

### Type Scale

| Name | Size | Line Height | Usage |
|------|------|-------------|-------|
| **xs** | 12px | 16px | Fine print, badges, timestamps |
| **sm** | 14px | 20px | Secondary text, captions, metadata |
| **base** | 16px | 24px | Body text, descriptions, paragraphs |
| **lg** | 18px | 28px | Emphasized body, intro text |
| **xl** | 20px | 28px | Card titles, section headers |
| **2xl** | 24px | 32px | Page section titles |
| **3xl** | 30px | 36px | Major headings |
| **4xl** | 36px | 40px | Hero subheadings |
| **5xl** | 48px | 1 | Hero headlines |
| **6xl** | 60px | 1 | Display headlines, landing pages |

### Weight Usage

- **Regular (400):** Body text, descriptions
- **Medium (500):** Subheadings, button text, emphasis
- **Semibold (600):** Section titles, card headers
- **Bold (700):** Headlines, strong emphasis

---

## 4. Component Stylings

### Buttons

| Type | Style | States |
|------|-------|--------|
| **Primary** | Sage green (`#5A6C4D`) background, white text, gently rounded corners | Hover: Dark forest (`#3D4A36`), subtle lift shadow |
| **Secondary** | White/transparent background, sage green border and text | Hover: Light sage background tint |
| **Ghost** | No background, sage text | Hover: Very subtle sage background |
| **Destructive** | Error red background, white text | Hover: Darker red |

**Shape:** Subtly rounded corners (`border-radius: 0.5rem` / 8px)
**Padding:** Comfortable horizontal padding, never cramped
**Shadow on hover:** Whisper-soft elevation (`shadow-brand`)

### Cards & Containers

| Property | Value | Description |
|----------|-------|-------------|
| **Background** | `#FFFFFF` or `#F5F3F0` | Pure white or warm stone |
| **Border** | `1px solid #E5E7EB` | Subtle light border |
| **Border Radius** | `0.75rem` - `1.5rem` | Generously rounded, soft corners |
| **Shadow** | `shadow-card` | Gentle, diffused elevation |
| **Padding** | `1.5rem` - `2rem` | Generous internal spacing |

### Inputs & Forms

| Property | Value | Description |
|----------|-------|-------------|
| **Background** | `#FFFFFF` | Pure white for clarity |
| **Border** | `1px solid #D1D5DB` | Medium border for definition |
| **Border (focus)** | `2px solid #5A6C4D` | Sage green focus ring |
| **Border Radius** | `0.5rem` | Subtly rounded |
| **Placeholder** | `#9CA3AF` | Muted, unobtrusive |

### Badges & Tags

| Type | Style |
|------|-------|
| **Default** | Light gray background, dark text |
| **Success** | Light green background, dark green text |
| **Warning** | Light yellow background, amber text |
| **Pro/Premium** | Lavender background, purple text |
| **New** | Coral background, dark text |

---

## 5. Layout Principles

### Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| **xs** | 4px | Tight gaps, inline elements |
| **sm** | 8px | Related element spacing |
| **md** | 16px | Standard component gaps |
| **lg** | 24px | Section padding |
| **xl** | 32px | Major section breaks |
| **2xl** | 48px | Page section separation |
| **3xl** | 64px | Hero section padding |

### Grid & Alignment

- **Max content width:** 1280px (centered)
- **Page margins:** 16px (mobile), 32px (tablet), 64px (desktop)
- **Card grids:** 1 column (mobile), 2-3 columns (tablet), 3-4 columns (desktop)
- **Alignment:** Left-aligned text, center-aligned heroes and CTAs

### Whitespace Philosophy

- **Generous breathing room** between sections
- **Never cramped** - when in doubt, add more space
- **Visual hierarchy through spacing** - more important = more space around it
- **Consistent rhythm** - use spacing scale consistently

---

## 6. Shadows & Elevation

| Level | Shadow | Usage |
|-------|--------|-------|
| **Flat** | None | Inline elements, minimal UI |
| **Subtle** | `shadow-sm` | Hover states, slight lift |
| **Default** | `shadow` | Cards at rest |
| **Medium** | `shadow-md` | Dropdowns, popovers |
| **Elevated** | `shadow-lg` | Modals, dialogs |
| **Floating** | `shadow-xl` | Floating action buttons |
| **Brand** | `shadow-brand` | CTA buttons on hover (sage-tinted) |

**Shadow character:** Soft, diffused, natural - never harsh or dramatic

---

## 7. Iconography & Imagery

### Icons

- **Style:** Outlined, consistent stroke width
- **Size:** 16px (inline), 20px (buttons), 24px (standalone)
- **Color:** Inherit from text or use sage green for emphasis

### Photography

- **Subject:** Residential landscapes, gardens, outdoor living spaces
- **Mood:** Aspirational but achievable, real homes not mansions
- **Treatment:** Bright, natural lighting, slightly warm color grading
- **Overlay:** Subtle gradient overlays for text readability when needed

### Illustrations

- **Style:** Simple, organic shapes with pastel accent colors
- **Usage:** Empty states, onboarding, feature explanations
- **Palette:** Coral, lavender, sage, sunshine pastels

---

## 8. Motion & Animation

| Type | Duration | Easing | Usage |
|------|----------|--------|-------|
| **Micro** | 150ms | ease-out | Button hovers, toggles |
| **Standard** | 200ms | ease-in-out | Card hovers, reveals |
| **Emphasis** | 300ms | ease-in-out | Modals, drawers |
| **Page** | 400ms | ease-out | Page transitions |

**Philosophy:** Subtle and purposeful - animations should feel natural and never distracting

---

## 9. Responsive Breakpoints

| Name | Width | Target |
|------|-------|--------|
| **sm** | 640px | Large phones |
| **md** | 768px | Tablets |
| **lg** | 1024px | Small laptops |
| **xl** | 1280px | Desktops |
| **2xl** | 1536px | Large screens |

---

## 10. Design Tokens Summary

```css
/* Primary Colors */
--color-brand-green: #5A6C4D;
--color-brand-dark: #3D4A36;
--color-brand-cream: #F5F3F0;

/* Backgrounds */
--color-bg-primary: #FAFAF8;
--color-bg-secondary: #F5F3F0;
--color-bg-tertiary: #FFFFFF;

/* Text */
--color-text-primary: #1F2937;
--color-text-secondary: #4B5563;
--color-text-muted: #9CA3AF;

/* Fonts */
--font-sans: 'Poppins', sans-serif;
--font-display: 'Playfair Display', serif;

/* Radii */
--radius-sm: 0.375rem;
--radius-md: 0.5rem;
--radius-lg: 0.75rem;
--radius-xl: 1rem;
```

---

## Usage with Stitch

When prompting Stitch to generate new screens, reference this design system:

> "Create a [screen type] using Yarda's design system: sage green (#5A6C4D) for primary actions, warm cream (#F5F3F0) backgrounds, Poppins font, generously rounded corners, and soft diffused shadows. The mood should be warm, organic, and professional."

For specific components, reference the component styling section above.
