# KAIWAI — Product Requirements Document
## Version 1.0 | 2026-03-13

---

## 1. Product Vision

> *"The body exists in physical space. The network doesn't care."*

KAIWAI (界隈) is built on a single tension: athletes already form invisible communities around shared physical locations — the same park loop, the same gym floor, the same rooftop — but the digital layer that could amplify those communities either doesn't exist or routes through generic social platforms that dilute the signal.

KAIWAI closes that gap. It anchors digital identity, social ranking, and knowledge distribution directly to GPS-verified physical locations. You are not a username. You are a presence at a spot. The app does not work unless you show up.

This is not a fitness tracker. It is a **local intelligence network for serious athletes.**

---

## 2. Target Users

| Tier | Profile | Core Need |
|---|---|---|
| **Core** | HYROX and marathon competitors. Goal-oriented, data-literate, competitive. | Spot-specific performance data. Who else trains here. Who is faster. |
| **Leader** | Coaches, trainers, influencer athletes with proprietary methods. | A distribution channel for structured knowledge tied to a real place. Revenue from premium access. |
| **Local** | Neighborhood runners (Yūtenji, Kōkyo perimeter). High consistency, low following. | Recognition within their home territory. A leaderboard that reflects real-world presence. |

---

## 3. Feature Specifications — v1.0

### 3.1 Map

**Screen:** `MapScreen`
**Libraries:** `flutter_map` + CartoDB Dark Matter tile layer (no API key required)
**Location:** `geolocator` continuous stream, 10m distance filter, high accuracy

#### Behavior

- Full-screen dark map centered on user's first GPS fix. Tokyo (`35.6762, 139.6503`) as fallback.
- Spots rendered as custom `SpotMarkerWidget` icons with transparent radius circles (`CircleLayer`). Circle fills accent color at `0.08` opacity; border at `0.3` opacity. Selected state intensifies both.
- Proximity detection runs on every GPS update. When the user enters a spot's `radius_meters`, an animated `_ProximityBanner` slides up from the bottom with the spot name, distance in metres, and a `界隈に入る` CTA.
- Tapping a spot opens a `SpotInfoSheet` bottom modal. Tapping the CTA or the banner button navigates to `SpotDetailScreen`.
- `[ ID ]` chip (top-right) opens `ProfileScreen`.
- Recenter FAB snaps map back to user location at zoom 15.

#### Data

- Spots fetched from Supabase `spots` table via `SpotRepository`.
- Each spot carries: `id`, `name`, `latitude`, `longitude`, `radius_meters`, `country_code`, `city_name`, `timezone_id`.

---

### 3.2 Auth

**Screen:** `LoginScreen`, `ProfileScreen`
**Backend:** Supabase Auth
**Methods:** Google OAuth (one-tap), Magic Link (email OTP)

#### Login Flow

Terminal aesthetic throughout. Screen header: `KAIWAI_AUTH_v1.0`. Title block: "IDENTIFY / YOURSELF" in `RubikMonoOne`, acid yellow glow on second line. Subtitle: "ACCESS RESTRICTED — MEMBERS ONLY".

Animated scan line passes vertically at 3s cycle (opacity `0.04`). Auth method buttons use `RobotoMono` monospace. On magic link send: success state shows `✓ LINK TRANSMITTED`.

DEV bypass (password login) visible in current build — **must be removed before v1.0 release.**

#### Identity Card (Profile)

`ProfileScreen` slides up as a full-screen modal from bottom. Displays a bordered ID card (`KAIWAI ID` badge, truncated UID, enrolled date, clearance level: `OPERATIVE`). Spec rows: OS, STATUS (`ENCRYPTED`), NETWORK (`MEMBERS_ONLY`). Disconnect button triggers `AuthRepository.signOut()` which causes `_AuthGate` in `main.dart` to swap back to `LoginScreen`.

---

### 3.3 Content (界隈ノート)

**Screens:** `SpotDetailScreen` (Notes tab), `CreateNoteScreen`, `NoteDetailScreen`
**Backend:** Supabase `contents` table via `ContentRepository`

#### Note List

Notes displayed as `_ContentCard` widgets with torn-corner clip path (`_TornCornerClipper`). Free notes show `TAP TO READ`. Premium notes (`is_premium: true`) show price badge (`¥{price}` in accent color) and are overlaid with `_BarricadeTapeOverlay` — diagonal repeating `/// WARNING /// PRIVATE ///` text in `RubikMonoOne` — when `userInsideSpot` is false.

**Location-gated access:** Premium content is only readable when `userInsideSpot == true`. This is passed from `MapScreen` via `SpotDetailScreen(userInsideSpot: true)`. Physical presence is the paywall.

**Dummy-real merge:** `_devContents` (4 fixture notes: HYROX prep, threshold intervals, rooftop session, sled mechanics) are always appended after real Supabase data so the screen never appears empty during the demo phase. This merge logic is intentional for v1.0; it will be gated behind a feature flag before public release.

#### Note Detail

`NoteDetailScreen` renders note body as plain monospace text. Displays city code badge and premium indicator if applicable.

#### Note Creation — Transmission

`CreateNoteScreen` is a terminal-style editor:

- Header: `[ NEW TRANSMISSION ]` in `RobotoMono`.
- Blinking block cursor (`█`) at 530ms interval, implemented via `Timer.periodic`.
- Subject field: `SUBJECT` (uppercase, 80 char cap). Body field: `TRANSMISSION BODY` (multiline).
- Submit CTA: `▶  TRANSMIT`. In-progress state: `TRANSMITTING...` with inline spinner.
- On save: calls `ContentRepository.createContent()` which inserts into Supabase `contents` with `author_id` = current user UID.
- Auth guard: if no session, shows snack `AUTH REQUIRED — LOGIN TO TRANSMIT` and pushes `LoginScreen`.
- RLS error detection: checks for Postgres error code `42501` and surfaces `ACCESS DENIED — CHECK RLS POLICIES`.

---

### 3.4 Social (界隈ランキング)

**Screen:** `SpotDetailScreen` (Ranking tab)
**Data:** `ContentRepository.leaderboardStream()` — Supabase realtime stream on `check_ins` aggregated by `user_id` for the given `spot_id`

#### Leaderboard Rendering

Entries ranked by `check_in_count` descending. Rank labels use Roman numeral tally marks: `I`, `II`, `III`, then `#N` for rank ≥ 4. Custom `_BoltPainter` lightning bolt icon precedes the count.

**Top 3 treatment:**
- Left-edge accent bar (3px, solid acid yellow).
- `_NeonFlicker` wrapper: `TweenSequence` animation at 3.2s cycle with randomized opacity dips (simulates real neon tube behavior). Opacity range: `1.0 → 0.65` with micro-flicker segments.
- Neon glow `Shadow` on rank label and count: `blurRadius 8` inner, `blurRadius 20` outer.
- Full-opacity username in `textPrimary`; `RubikMonoOne` at 13px.

Ranks ≥ 4 render at reduced opacity (`surface` at `0.6 alpha`), secondary text color, no flicker.

**Dummy-real merge:** `_devLeaderboard` (5 fixture entries: APEX_RUNNER, IRONCLAD_88, GHOST_ATHLETE, URBAN_BLADE, CTRL_ALT_RUN) appended after real stream data. On stream error (e.g., RLS blocks unauthenticated reads), dev data displayed in full. Same feature-flag deprecation plan as notes.

---

### 3.5 Spot Detail — Global Context

**Widget:** `_GlobalBadge`, `_SpotMetaLine`

- Global badge in app bar: country flag emoji + 3-letter city code derived from `spot.country_code` / `spot.city_name` via `TimezoneUtils`. Visible only when data present.
- Meta line: radius in metres + local time at the spot's timezone, auto-refreshed every 30 seconds via `Stream.periodic`. Enables nomadic athletes to instantly orient to a remote spot's local context.

---

## 4. Design System

| Token | Value | Usage |
|---|---|---|
| `background` | `#0D0D0D` | App background |
| `surface` | `#1A1A1A` | Cards, app bars |
| `accent` | `#E2FF4F` | Primary CTA, active states, neon glow |
| `accentDim` | `#8A9A2F` | Inactive spot circles |
| `textPrimary` | `#F0EEE9` | Body copy |
| `textSecondary` | `#888888` | Labels, metadata |
| `danger` | `#FF4F4F` | Errors, disconnect |
| `border` | `#2E2E2E` | Dividers, card borders |

**Typefaces:**
- `RubikMonoOne` — headings, rank labels, brand moments
- `RobotoMono` — system text, terminal UI, form inputs
- `Inter` — base body (fallback)

**Visual language:** Urban brutalism. Concrete texture backgrounds (`_ConcreteTexturePainter`). Torn-corner card clips. Spray-paint tab indicator (`_SprayBoxPainter`). Glitch text on screen entry (`_GlitchText` — cyan/magenta channel split at 3px). Zero border-radius on interactive elements. All-caps copy.

---

## 5. Technical Stack

| Layer | Technology | Notes |
|---|---|---|
| **Mobile Client** | Flutter (iOS + Android) | Material 3 dark theme |
| **Map** | `flutter_map` + CartoDB Dark Matter | No API key. OSM attribution required. |
| **Location** | `geolocator` | High accuracy, 10m distance filter |
| **Auth** | Supabase Auth | Google OAuth + Magic Link |
| **Database** | Supabase (PostgreSQL + PostGIS) | `geography(POINT)` for spot locations |
| **Realtime** | Supabase Realtime | Leaderboard stream |
| **Storage** | Supabase Storage | Avatar URLs (future) |
| **Fonts** | Google Fonts (`RubikMonoOne`, `RobotoMono`, `Inter`) | Bundled via `google_fonts` package |

### Database Schema (v1.0)

```
spots          id, name, location(geography), radius_meters, leader_id,
               country_code, city_name, timezone_id, description, created_at

profiles       id, username, avatar_url, bio, is_leader

check_ins      id, user_id, spot_id, check_in_at, check_out_at, status

contents       id, spot_id, author_id, title, body_json(jsonb),
               is_premium, price, created_at
```

PostGIS `ST_DWithin` used for server-side proximity queries (future optimization; client currently handles proximity via `Geolocator.distanceBetween`).

---

## 6. Open Items — Pre-Release Blockers

| # | Item | Owner |
|---|---|---|
| 1 | Remove `_DevLoginButton` and dev bypass in `_performCheckIn` | Eng |
| 2 | Wire `userInsideSpot` to live GPS check, not hardcoded `true` | Eng |
| 3 | Implement RLS policies for `contents` insert (author = current user) | Eng/DB |
| 4 | Replace `_devContents` / `_devLeaderboard` with feature flag | Eng |
| 5 | Remove hardcoded `akihide@example.com` dev credential | Eng |
| 6 | Add OSM / CartoDB tile attribution overlay to map | Eng |

---

## 7. Future Roadmap

### v1.1 — Paywall & Monetization

- Stripe integration via Supabase Edge Functions.
- `contents.is_premium = true` rows require verified payment record before body is decrypted client-side.
- Leader dashboard: earnings, subscriber count per note, conversion rate.
- `profiles.is_leader` gates note creation and premium pricing controls.

### v1.2 — Live Check-In Counts

- Supabase Realtime subscription on `check_ins` filtered by `spot_id` and active `check_out_at IS NULL`.
- Count badge rendered on spot markers on the map — ambient live signal that a spot is active.
- Privacy mode: only aggregate count visible, never individual user location.

### v1.3 — ChoreoID Motion Analysis

- Camera-based form analysis for compound movements (squat, lunge, sled push stance).
- ML model derived from ChoreoID pose estimation pipeline.
- Output attached to a check-in: form score stored alongside performance data.
- Spot leaders can define movement standards; members are scored against them.

### v2.0 — Global Spots Network

- Spot creation open to verified leaders.
- Cross-city leaderboards for nomadic athletes.
- `_GlobalBadge` country/city context already scaffolded for this expansion.

---

## 8. Success Metrics (KPI)

| Metric | Definition | Target (6 months post-launch) |
|---|---|---|
| **Spot Retention** | % of users checking into the same spot ≥ 3×/week | 25% of MAU |
| **Note Subscription Rate** | Paid conversions / premium note views | ≥ 8% |
| **Session Depth** | Avg. screens visited per session (map → spot → ranking/notes) | ≥ 3 screens |
| **Leaderboard Engagement** | % of check-in users who open ranking tab | ≥ 60% |

---

*KAIWAI NETWORK — MEMBERS ONLY*
*v1.0 PRD — internal use*
