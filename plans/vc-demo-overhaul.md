# Sanctuary VC Demo Overhaul Plan

## Current State Analysis

### What Exists
- **iOS App**: Full SwiftUI app with Supabase backend, safety monitoring, consent management, WidgetKit extension
- **Web Demo** (`demo/index.html`): Single-page iPhone mockup with basic tab switching, a panic button, monitoring toggle, and a simple activity feed. ~1338 lines of vanilla HTML/CSS/JS
- **Privacy Policy** (`demo/privacy-policy.html`): Well-structured page with proper sections
- **Terms & Conditions** (`demo/terms.html`): Comprehensive terms including SMS messaging terms with HELP/STOP in bold
- **Vercel Deployment**: Configured via `vercel.json` serving the `demo/` directory at `sanctuary-ios-safety.vercel.app`
- **README.md**: Good content but contains emojis and em dashes

### Problems to Fix
1. **Twilio A2P Campaign Rejection**: Campaign rejected because the Privacy Policy URL and Terms URL fields contain placeholder values (`https://example.com/...`). Actual pages exist but the Twilio form was never updated.
2. **Demo is basic**: Current demo is an iPhone frame mockup with minimal interactivity. Not compelling for a VC partner demo.
3. **README style**: Contains emojis and em dashes, not industry-standard formatting.
4. **No analytics/data visualization**: Missing the data-rich dashboards that Tesla/Whoop UIs are known for.

---

## Architecture: New Demo Web App

### Design System (Tesla/Whoop Inspired)

| Token | Value | Usage |
|-------|-------|-------|
| Background | `#000000` OLED Black | Primary background |
| Surface | `#0A0A0A` | Elevated surfaces |
| Card | `#111111` | Card backgrounds |
| Card Hover | `#1A1A1A` | Interactive card hover state |
| Border | `rgba(255,255,255,0.06)` | Subtle dividers |
| Accent | `#FF5F00` Safety Orange | Primary brand color |
| Safe | `#30D158` Green | Positive/active states |
| Danger | `#FF3B30` Red | Alert/emergency states |
| Info | `#0A84FF` Blue | Informational elements |
| Text Primary | `#FFFFFF` | Headings, primary text |
| Text Secondary | `rgba(255,255,255,0.55)` | Supporting text |
| Text Tertiary | `rgba(255,255,255,0.25)` | Timestamps, labels |
| Typography | SF Pro Display / Inter | System font stack |
| Border Radius | 16px cards, 12px buttons, 50% circles | Consistent rounding |

### UI Reference: Tesla + Whoop Patterns
- **Tesla**: Full-width dark dashboard, clean card grid, real-time vehicle telemetry, minimalist controls, smooth state transitions
- **Whoop**: Animated circular progress rings, health metric cards, strain/recovery scores, timeline views, data-dense but readable

### Tech Stack
- **Frontend**: Vanilla HTML/CSS/JS (zero build step, instant deploy to Vercel)
- **Charts**: Lightweight custom SVG-based charts (no external dependencies)
- **Animations**: CSS keyframes + `requestAnimationFrame` for 60fps data updates
- **Hosting**: Vercel (free tier, already configured)
- **No frameworks**: Keeps the demo self-contained, fast to load, zero dependencies

### File Structure

```
demo/
  index.html              # Main VC demo app (complete rewrite)
  privacy-policy.html     # Updated with current date, direct Twilio-ready link
  terms.html              # Updated to meet all Twilio A2P requirements
```

---

## Screen-by-Screen Breakdown

### 1. Dashboard (Home)
Full-screen dark dashboard with a Tesla-like layout:

- **Safety Score Ring**: Large animated SVG circular progress indicator (0-100 safety score) with gradient stroke, center showing current score animating up on load
- **Real-Time Metrics Grid** (2x2 bento grid):
  - Check-in Timer: Countdown with animated progress bar
  - GPS Accuracy: Live-updating meter value with signal strength indicator
  - Active Contacts: Count with avatar stack
  - Session Duration: Running timer when monitoring is active
- **Live Activity Feed**: Vertically scrolling feed with new items sliding in every 5-8 seconds, each with icon, description, timestamp, and colored status dot
- **Quick Actions Bar**: Activate Monitoring, SOS shortcut, Check-in Now buttons

### 2. Safety
Dedicated safety control center:

- **Large Panic Button**: Animated concentric pulse rings, hold-to-activate with radial progress indicator showing hold duration, state transitions (idle, holding, triggered, cooldown)
- **Live Location Map**: CSS-based animated map visualization with a pulsing location dot, fake coordinate updates, and a trail of recent positions
- **Dead Man's Switch Panel**: Visual countdown timer with circular progress, configurable interval selector
- **Contact Alert Status**: List of trusted contacts with real-time delivery status indicators (sent, delivered, acknowledged)

### 3. Analytics
Data-rich screen inspired by Whoop's recovery/strain views:

- **Weekly Safety Score Chart**: Animated SVG line/area chart showing 7-day trend with gradient fill
- **Session History Timeline**: Vertical timeline with duration bars, color-coded by type (monitoring, alert, check-in)
- **Statistics Cards**:
  - Total sessions this month
  - Average session duration
  - Alerts sent
  - Response time (average time for contacts to acknowledge)
- **Consent Agreement Progress**: Horizontal animated progress bars per category

### 4. Consent
Partner consent management interface:

- **Partner Header Card**: Avatar, name, linked status, overall agreement progress ring
- **Consent Category Grid**: 2x2 grid of interactive cards with icons, animated state transitions (accepted/pending/declined), tap to toggle with smooth color/icon animation
- **Recent Agreement Activity**: Mini feed showing recent consent changes

### 5. Settings
Clean settings layout:

- **Profile Card**: User avatar, name, phone number
- **Toggle Groups**: iOS-style toggle switches for Safety Monitoring, Background Location, Notifications, Dead Man's Switch
- **Configuration Links**: Check-in interval, emergency message, trusted contacts
- **Legal Links**: Privacy Policy, Terms and Conditions (linking to the actual pages)
- **App Info**: Version, build, environment badge

### Navigation
- **Bottom Tab Bar**: Fixed at bottom, 5 tabs (Dashboard, Safety, Analytics, Consent, Settings) with SF Symbol-style icons, active state indicator with animated underline
- **Smooth Screen Transitions**: CSS transform-based slide/fade transitions between screens

---

## Real-Time Data Simulation

All data updates are generated client-side with randomized intervals to create a convincing live-data feel:

| Data Point | Update Interval | Animation |
|------------|----------------|-----------|
| Safety Score | 15-30s | SVG stroke-dashoffset tween |
| GPS Accuracy | 3-5s | Smooth counter transition |
| Check-in Timer | 1s | Countdown with progress bar |
| Activity Feed | 5-8s random | Slide-in from left with fade |
| Session Timer | 1s | Running clock |
| Weekly Chart | 20s | Re-render with eased transitions |
| Location Dot | 2-4s | CSS translate with trail effect |
| Contact Status | 8-12s random | Status badge color transition |

---

## Animation Specifications

### Micro-interactions
- **Button press**: `transform: scale(0.97)` on `:active`, 100ms ease-out
- **Card hover**: Subtle `translateY(-2px)` lift with shadow increase
- **Toggle switch**: 300ms cubic-bezier spring animation
- **Tab switch**: 250ms slide transition with opacity cross-fade

### Feature Animations
- **Safety Score Ring**: On-load animation from 0 to target value over 1.5s with `cubic-bezier(0.4, 0, 0.2, 1)`
- **Panic Button Rings**: Continuous concentric pulse using `@keyframes` with staggered delays
- **Panic Hold Progress**: Radial SVG path that fills clockwise over 1.5s while held
- **Location Pulse**: Expanding ring animation at location marker position
- **Activity Feed Items**: `translateX(-20px)` to `0` with `opacity: 0` to `1` over 300ms
- **Chart Line Draw**: SVG path animation using `stroke-dasharray` + `stroke-dashoffset`
- **Number Counters**: `requestAnimationFrame`-based interpolation for smooth value changes

---

## Privacy Policy Updates for Twilio

The existing privacy policy page is well-structured. Updates needed:
- Update the effective date to February 2026
- Ensure the URL path is clean: `/privacy-policy.html`
- Verify the page loads independently (no JS dependencies)
- Confirm all required Twilio content is present:
  - What data is collected
  - How data is used
  - Confirmation data is not shared with third parties for marketing

**Final URL for Twilio**: `https://sanctuary-ios-safety.vercel.app/privacy-policy.html`

## Terms and Conditions Updates for Twilio

The existing terms page already meets most A2P 10DLC requirements. Updates needed:
- Update the effective date to February 2026
- Verify all required elements per Twilio's support article:
  - Program name: Present ("Sanctuary Personal Safety and Consent Management")
  - Program description: Present
  - Message/data rates: Present ("Message and data rates may apply")
  - Message frequency: Present
  - Support contact: Present (support@sanctuary.app)
  - HELP keyword: Present and bold
  - STOP keyword: Present and bold

**Final URL for Twilio**: `https://sanctuary-ios-safety.vercel.app/terms.html`

---

## README Rewrite

Remove all emojis and em dashes. Follow standard open-source README conventions:
- Title with badges
- One-line description
- Table of contents
- Overview
- Architecture
- Getting Started with numbered steps
- Feature descriptions using plain text headers
- Contributing guide
- License

---

## Deployment

```mermaid
flowchart LR
    A[demo/ directory] --> B[Vercel Build]
    B --> C[sanctuary-ios-safety.vercel.app]
    C --> D[/index.html - VC Demo]
    C --> E[/privacy-policy.html - Twilio URL]
    C --> F[/terms.html - Twilio URL]
```

- Hosting: Vercel free tier (already configured)
- Domain: `sanctuary-ios-safety.vercel.app` (existing)
- Build: Zero-config static site (no build step)
- Deploy: `git push` to main triggers auto-deploy

---

## Execution Order

1. Update `demo/privacy-policy.html` with current dates
2. Update `demo/terms.html` with current dates
3. Rewrite `demo/index.html` as the full VC-ready dashboard demo
4. Rewrite `README.md` with industry-standard formatting
5. Commit and push to trigger Vercel deployment
6. Verify all three URLs are publicly accessible
7. User updates Twilio A2P campaign form with the real URLs

---

## Post-Deployment: Twilio Campaign Fix

After deployment, the user should update the Twilio A2P 10DLC campaign with:
- **Privacy Policy URL**: `https://sanctuary-ios-safety.vercel.app/privacy-policy.html`
- **Terms and Conditions URL**: `https://sanctuary-ios-safety.vercel.app/terms.html`

Then resubmit the campaign for review. The pages contain all required content for A2P 10DLC compliance.
