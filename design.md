# Tiara Finance — Backoffice RT Design System

## 1. Context and goals

**Design intent:** Maintain the existing Tiara Finance UI and visual language while turning it into a consistent, implementation-ready design system for the RT/RW backoffice used by Ketua RT, Bendahara, and authorized administrators.

Tiara Finance is a Flutter application for neighborhood financial and operational management. The backoffice supports dashboard monitoring, iuran management, payment verification, resident management, financial reporting, announcements, notifications, forums, and resident complaints. The repository is implemented in Flutter and already uses Material 3, custom theme classes, charts, skeleton/loading utilities, pull-to-refresh, slidable actions, cached images, notifications, and PDF/reporting packages. fileciteturn3file0L2-L2 fileciteturn4file0L2-L2

The backoffice navigation and screen structure already differentiates between `ketua_rt` and the default administrator/bendahara role. Ketua RT has a reduced read-oriented navigation set, while the default admin has access to dashboard, transactions, iuran, residents, and profile. fileciteturn7file0L2-L2

### Non-negotiable visual preservation

- Existing colors **must not be changed**.
- Existing visual language, component character, navigation treatment, gradients, cards, rounded surfaces, and overall UI direction **must not be redesigned**.
- New screens **must reuse existing theme tokens and component patterns** instead of introducing a competing visual style.
- Layout improvements **must improve hierarchy, spacing consistency, usability, or accessibility without changing the established visual identity**.
- New components **must look native to the current app**, not like an imported web dashboard or unrelated template.
- Teams **must prefer system consistency over local visual exceptions**.

## 2. Design tokens and foundations

### 2.1 Color tokens

Use semantic tokens from the existing Flutter theme. Do not use raw hex values in component guidance or new components.

```text
color.brand.primary        = AppTheme.primary
color.brand.primaryDark    = AppTheme.primaryDark
color.brand.secondary      = AppTheme.secondary
color.surface.background   = AppTheme.background
color.surface.raised       = AppTheme.surface
color.text.primary         = AppTheme.textMain
color.text.secondary       = AppTheme.textSecondary
color.border.default       = AppTheme.divider
color.status.danger        = AppTheme.danger
color.status.warning       = AppTheme.warning
color.status.success       = AppTheme.success
color.gradient.primary     = AppTheme.primaryGradient
color.gradient.mesh        = AppTheme.meshGradient
```

The repository currently defines emerald/teal as the primary brand, white surfaces, light blue-grey page background, dark primary text, muted secondary text, and semantic danger/warning/success colors. fileciteturn8file0L2-L2

Role-specific tokens **must** continue using the existing role theme:

```text
role.warga.primary        = RoleTheme.wargaPrimary
role.warga.secondary      = RoleTheme.wargaSecondary
role.warga.background     = RoleTheme.wargaBackground
role.warga.gradient       = RoleTheme.wargaGradient

role.admin.primary        = RoleTheme.adminPrimary
role.admin.secondary      = RoleTheme.adminSecondary
role.admin.background     = RoleTheme.adminBackground
role.admin.surface        = RoleTheme.adminSurface
role.admin.text           = RoleTheme.adminText
role.admin.gradient       = RoleTheme.adminGradient

role.rt.primary           = RoleTheme.rtPrimary
role.rt.secondary         = RoleTheme.rtSecondary
role.rt.accent            = RoleTheme.rtAccent
role.rt.background        = RoleTheme.rtBackground
role.rt.gradient          = RoleTheme.rtGradient
```

These role tokens are existing product behavior and **must not be replaced by new palette values**. fileciteturn8file0L2-L2

### 2.2 Typography

The existing theme uses Google Fonts with Outfit for prominent headings and Poppins for body copy. New backoffice UI **must reuse these established styles through theme tokens** rather than creating one-off font families. fileciteturn8file0L2-L2

```text
font.family.heading = existing AppTheme header/title styles
font.family.body    = existing AppTheme body style
font.weight.heading = existing AppTheme heading weights
font.weight.body    = existing AppTheme body weight
```

Recommended hierarchy:

```text
text.display        = AppTheme.header1
text.sectionTitle   = AppTheme.title
text.body           = AppTheme.body
text.caption        = existing body style with smaller scale
text.label          = existing body style with stronger weight
```

Typography **must** remain content-first. Status labels, money values, dates, counts, and resident names **must** remain scannable at a glance.

### 2.3 Shape, elevation, and motion

- Existing rounded-card treatment **must** remain the source of truth.
- Existing card elevation and shadow treatment **must** be reused.
- Existing gradients **must** be reused instead of introducing new gradients.
- Existing transition and interaction motion **should** remain smooth and restrained.
- Motion **must not** prevent completion of routine administrative tasks.
- Decorative motion **must** be skipped when it creates visual noise or harms comprehension.

### 2.4 Layout and density

Backoffice layout **must** prioritize information density without becoming visually crowded.

Use the existing Flutter spacing patterns and standard Material spacing primitives. New components **must not** introduce arbitrary pixel spacing when an existing theme or design constant is available.

Known product areas include:

```text
Primary navigation     = role-aware bottom navigation
Dashboard              = KPI + charts + operational summaries
Transactions           = dense list/data review
Iuran                  = recurring fee administration
Residents              = resident management and detail
Announcements          = announcement list/detail/create
Complaints             = complaint triage and status handling
Forums                 = moderation/discussion review
Profile                = account/session settings
```

## 3. Component-level rules

Every component **must** document and implement these states: `default`, `hover`, `focus-visible`, `active`, `disabled`, `loading`, and `error`. On touch-only surfaces, hover **must** be treated as non-applicable and the component **must** preserve an equivalent pressed/active affordance.

### 3.1 App shell and navigation

**Anatomy:** content area, role-aware navigation, optional floating action, system safe areas.

**Variants:**
- `admin/bendahara`
- `ketua_rt`

The existing app uses a `PageView` with a custom `WavyBottomBar`. That navigation treatment **must** remain visually consistent. Role-based item visibility **must** follow authorization rules rather than visual preference. fileciteturn7file0L2-L2

**States:**
- default: active destination is visually obvious.
- hover: **must** apply only where a pointer exists; it **should** be subtle.
- focus-visible: focused navigation item **must** have a visible non-color-only indicator.
- active: selected item **must** provide icon + position + visual emphasis.
- disabled: unavailable navigation **must** not be presented as actionable.
- loading: destination content **must** show a loading state without breaking the shell.
- error: destination-level failures **must** preserve navigation so the operator can recover.

**Keyboard/pointer/touch:**
- Keyboard users **must** be able to traverse every reachable navigation action in logical order.
- Enter/Space **must** activate the focused navigation action.
- Pointer click **must** activate exactly once.
- Touch targets **must** provide a practical minimum hit area consistent with Flutter accessibility guidance.
- Swiping between pages **should** remain available only where it does not conflict with accessibility or accidental navigation.

### 3.2 Dashboard KPI cards

**Purpose:** Summarize cash position, payment status, outstanding iuran, resident counts, and operational queues.

**Anatomy:** label, primary value, optional trend/context, optional status icon.

**Rules:**
- KPI labels **must** identify the metric in plain language.
- Monetary values **must** use consistent Indonesian currency formatting.
- Important status **must not** rely on color alone.
- Cards **should** expose the next relevant action where one exists.
- Zero states **must** explain whether zero means "none" or "not yet loaded".

**Responsive:** KPI cards **must** reflow to maintain readable values at narrow widths. Text **must not** be clipped or replaced with unexplained ellipses.

### 3.3 Buttons and action controls

**Variants:** primary, secondary, text, destructive, icon action.

**States:**
- default: existing brand treatment.
- hover: **must** provide clear interaction feedback without palette changes.
- focus-visible: **must** use a visible focus treatment.
- active/pressed: **must** show immediate pressed feedback.
- disabled: **must** lower interactivity and reject activation.
- loading: **must** prevent duplicate submissions and show progress.
- error: after a failed action, **must** expose actionable feedback.

**Rules:**
- Primary actions **must** use the existing primary token.
- Destructive actions **must** use the existing danger semantic token.
- Labels **must** describe the action, e.g. `Verifikasi Pembayaran`, `Simpan Iuran`, `Tolak Pengaduan`.
- Ambiguous labels such as `OK`, `Klik`, or `Lanjut` **must not** be used when the result can be named.
- Icon-only buttons **must** provide an accessible label and tooltip where appropriate.

**Keyboard/pointer/touch:** Enter and Space **must** activate focused buttons; pointer and touch **must** have equivalent behavior; repeated touch/pointer events **must not** create duplicate writes.

### 3.4 Forms and inputs

Backoffice forms cover authentication, iuran creation/editing, profile updates, announcement creation, and operational responses. Existing screens include editable profile and creation/detail flows. fileciteturn6file0L2-L2

**Rules:**
- Every input **must** have a persistent, descriptive label.
- Required fields **must** be identifiable before submission.
- Validation **must** occur close to the relevant field and at submit.
- Monetary inputs **must** accept only valid numeric representations and **must** preserve intended value formatting.
- Error text **must** explain how to fix the value.
- Form submission **must** prevent duplicate requests while loading.

**States:** default, hover, focus-visible, active/editing, disabled, loading, error.

**Keyboard:** Tab order **must** follow the visual reading order. Escape **should** dismiss temporary overlays or clear transient UI where appropriate. Enter **must not** accidentally submit a multi-step or destructive form unless that is the documented primary action.

### 3.5 Tables, lists, and transaction records

Transactions represent payments, income, expenses, timestamps, status, period, descriptions, and optional proof images. fileciteturn10file0L2-L2

**Rules:**
- Lists **must** remain scannable at operational density.
- Each row/card **must** expose its primary identity, amount/value, status, and relevant date/period.
- Status **must** use semantic tokens and text labels.
- Secondary metadata **should** be visually subordinate.
- Row actions **must** be discoverable and must not depend solely on swipe.
- `flutter_slidable` behavior **should** be treated as a progressive enhancement, not the only action path.

**Long content:** names and descriptions **must** wrap or provide a detail view. Critical monetary values **must not** be truncated.

**Overflow:** horizontal scrolling **should** be avoided on common phone widths; when unavoidable for genuinely tabular data, headers and column relationships **must** remain understandable while scrolling.

**Empty state:** empty lists **must** explain what is missing and, when relevant, provide the next action.

### 3.6 Status badges

Use semantic status tokens. Typical statuses include `Lunas`, `Belum Bayar`, `Menunggu`, `Disetujui`, `Ditolak`, `Pending`, `Proses`, and `Selesai`.

Status labels **must** be human-readable and **must** include text in addition to color/icon meaning.

### 3.7 Announcement management

The existing announcement management includes list, create, detail, view count, date, and author context. fileciteturn11file0L2-L2

- Announcement cards **must** prioritize title and publication date.
- View count **should** remain secondary metadata.
- Create/add actions **must** use explicit language such as `Buat Pengumuman`.
- Long announcement content **must** move to a detail surface rather than overloading a list row.
- Empty announcements **must** provide a clear creation path for authorized roles.

### 3.8 Resident management

Resident data includes name, email, role, block, house number, phone number, and optional photo. fileciteturn10file0L2-L2

- Search/filter controls **must** use descriptive labels.
- Resident identity **must** remain the strongest visual anchor.
- Sensitive details **should** remain hidden until needed for the operational task.
- Role and account status **must** be explicit in detail views.
- Long resident names **must** wrap safely.

### 3.9 Complaint / pengaduan management

Complaints include category, title, description, optional photo, creation date, status, response, and response time. Categories include cleanliness, security, facilities, and other. fileciteturn10file0L2-L2

Operational statuses **must** remain explicit: `Pending`, `Proses`, `Selesai`.

- Operators **must** be able to understand ownership, category, age, and current status quickly.
- Response actions **must** use task-specific labels such as `Mulai Proses` or `Tandai Selesai`.
- Error states **must** explain whether the failure occurred while loading the report, loading media, or submitting the response.

### 3.10 Charts and financial visualization

The application uses `fl_chart` for interactive financial visualization. fileciteturn4file0L2-L2

- Charts **must** include a textual summary for users who cannot interpret the visual.
- Axis labels and legends **must** remain readable at phone sizes.
- Color **must not** be the only encoding for categories.
- Empty charts **must** explain that there is no data rather than rendering an empty frame without context.
- Tooltip/interaction **must** be keyboard- or semantics-accessible where the chart exposes actionable information.

### 3.11 Loading, skeleton, and refresh

The repository already uses shimmer/skeleton and pull-to-refresh capabilities. fileciteturn4file0L2-L2

- Loading state **must** preserve layout stability.
- Skeletons **should** approximate the final content shape.
- Refresh **must not** clear valid existing data before replacement data is available unless the operation explicitly requires it.
- Loading indicators **must** not trap keyboard focus.

### 3.12 Connectivity and system errors

The application already surfaces connectivity loss and provides a retry action. fileciteturn5file0L2-L2

- Offline state **must** clearly identify loss of connectivity.
- Retry actions **must** be explicit and must not silently repeat writes.
- Error surfaces **must** preserve access to navigation and safe recovery paths.
- Technical error details **should** be available for support/debugging without being the primary user-facing message.

## 4. Responsive behavior and edge cases

The backoffice **must** support practical Flutter phone/tablet layouts without creating a second visual system.

- Narrow widths **must** reduce column density before reducing readable text size.
- Content **must** scroll vertically rather than overflow off-screen.
- Cards **must** stack or reflow when side-by-side presentation would make data unreadable.
- Buttons **must** remain reachable and must not overlap navigation, floating actions, or system safe areas.
- Floating actions **must** account for the existing bottom navigation treatment; the current implementation already offsets the admin FAB to avoid overlap. fileciteturn7file0L2-L2
- Long names, long descriptions, large currency amounts, zero values, and missing optional images **must** be handled without broken layouts.
- Lists with hundreds of records **should** use lazy rendering and pagination/streaming patterns appropriate to the data source.
- Missing profile photos or remote images **must** have a stable fallback.

## 5. Accessibility requirements and testable acceptance criteria

Target: **WCAG 2.2 AA** principles adapted to Flutter.

### Contrast

- Normal body text **must** meet at least 4.5:1 contrast against its effective background.
- Large text **must** meet at least 3:1.
- Meaningful icons and interactive controls **must** meet applicable non-text contrast requirements.
- Color-coded statuses **must** include text and/or icon differentiation.

**Pass/fail:** Run contrast analysis on each semantic text/surface combination used in production states. Any failing combination **must** fail QA until corrected using existing semantic tokens or an approved accessible treatment that does not change brand colors.

### Keyboard/focus

- Every interactive element **must** be reachable with sequential keyboard navigation where the platform supports keyboard input.
- Focus order **must** follow task order.
- Focus indicators **must** remain visible and **must not** depend only on color.
- Focus **must not** be trapped in a non-modal surface.

**Pass/fail:** Complete the primary admin flows using keyboard only. A flow fails if any actionable control cannot be reached, activated, or dismissed without a pointer/touch device.

### Touch and pointer

- Interactive targets **must** provide an appropriately sized hit area for touch.
- Adjacent actions **must** have enough separation to reduce accidental activation.
- Swipe-only actions **must not** be the sole path to critical tasks.

**Pass/fail:** Execute verification, rejection, save, navigation, and refresh tasks on a touch device without accidental neighboring activation.

### Semantics and announcements

- Icons **must** have meaningful semantic labels when they represent actions or important status.
- Form errors **must** be associated with their inputs.
- Dynamic status changes **should** be exposed to assistive technology when appropriate.
- Loading and completion feedback **must** be understandable without relying on animation.

**Pass/fail:** Screen-reader testing must identify each interactive control by role/name and must expose validation/error status after failed submission.

### Motion

- Essential information **must not** depend on motion.
- Motion **should** be reduced or avoided where a platform/user preference requests reduced motion.
- Loading animations **must** not continue indefinitely after content becomes available.

## 6. Content and tone standards

Tone: concise, confident, administrative, and locally understandable. Copy **must** use familiar RT/RW terminology.

Use:

```text
Dashboard
Kelola Iuran
Verifikasi Pembayaran
Data Warga
Laporan Keuangan
Pengumuman
Pengaduan Warga
Forum
Profil
```

Prefer action-oriented copy:

```text
Verifikasi Pembayaran
Buat Iuran
Simpan Perubahan
Kirim Pengumuman
Mulai Proses
Tandai Selesai
Coba Lagi
```

Avoid:

```text
Klik Di Sini
OK
Submit
Action
Manage
Something went wrong
```

Financial copy **must** distinguish `pemasukan`, `pengeluaran`, `iuran`, `saldo`, `status`, and `periode` consistently. Transaction records already model `tipe`, `status`, `uang`, and `periode`; UI wording **must** preserve these distinctions. fileciteturn10file0L2-L2

## 7. Anti-patterns and prohibited implementations

- New colors **must not** be introduced merely to differentiate a new screen.
- New gradients **must not** be introduced when an existing gradient token fits.
- A separate web-dashboard visual language **must not** be introduced into the Flutter backoffice.
- One-off font families **must not** be introduced.
- One-off spacing constants **must not** be introduced without a system-level reason.
- Critical actions **must not** be hidden behind hover-only interactions.
- Destructive actions **must not** look identical to safe secondary actions.
- Status **must not** be conveyed by color alone.
- Loading **must not** replace the entire screen with an unexplained spinner when the surrounding layout can be preserved.
- Empty states **must not** be blank screens with no explanation.
- Errors **must not** expose raw technical messages as the only user-facing content.
- Swipe gestures **must not** be the only route to transaction/resident actions.
- Decorative components **must not** consume space needed by high-value operational information.

## 8. Migration notes

This document replaces the original generic Tagus/crypto dashboard framing with product-specific guidance for the Tiara Finance RT backoffice.

Migration rules:

1. Existing `AppTheme` and `RoleTheme` tokens **must** remain the canonical visual source of truth. fileciteturn8file0L2-L2
2. Existing admin navigation and role-aware information architecture **must** remain intact unless a product requirement explicitly changes permissions or workflow. fileciteturn7file0L2-L2
3. Existing custom visual patterns such as the wavy bottom navigation, branded gradients, rounded cards, and green/blue role treatment **must** be preserved. fileciteturn7file0L2-L2 fileciteturn8file0L2-L2
4. Improvements **should** focus on consistency, semantic labeling, state completeness, responsive behavior, keyboard accessibility, contrast, and operational clarity.
5. Existing functionality such as charting, notifications, pull-to-refresh, cached images, shimmer/loading, PDF reporting, and slidable actions **should** be reused before adding new dependencies. fileciteturn4file0L2-L2

## 9. QA checklist

### Visual consistency

- [ ] All new screens reuse existing theme/color tokens.
- [ ] No raw replacement palette was introduced.
- [ ] Existing card, gradient, navigation, and typography character remains intact.
- [ ] No one-off spacing or component styling exception was introduced.

### Component states

- [ ] Default state implemented.
- [ ] Hover state handled where pointer exists.
- [ ] Focus-visible state implemented.
- [ ] Active/pressed state implemented.
- [ ] Disabled state implemented.
- [ ] Loading state implemented.
- [ ] Error state implemented.

### Interaction

- [ ] Keyboard navigation works for every interactive flow.
- [ ] Pointer interaction works without duplicate activation.
- [ ] Touch interaction has adequate hit areas and separation.
- [ ] Swipe is not the sole route to critical actions.

### Content/data

- [ ] Long names/descriptions do not break layouts.
- [ ] Large currency values remain readable.
- [ ] Empty states explain what happened and what to do next.
- [ ] Missing images have stable fallbacks.
- [ ] Loading preserves layout where possible.
- [ ] Errors are actionable and understandable.

### Accessibility

- [ ] Text contrast meets WCAG 2.2 AA.
- [ ] Status meaning is not color-only.
- [ ] Interactive controls have accessible names.
- [ ] Form validation is programmatically associated with inputs.
- [ ] Focus is visible and not trapped unexpectedly.
- [ ] Screen-reader output identifies important controls and status.
- [ ] Motion is not required to understand or complete a task.

### Product QA

- [ ] Ketua RT permissions remain correctly restricted.
- [ ] Bendahara/admin actions remain available only to authorized roles.
- [ ] Financial verification cannot be accidentally duplicated.
- [ ] Complaint/announcement status transitions are explicit.
- [ ] Dashboard metrics remain consistent with underlying data.
- [ ] The final result looks like the existing Tiara Finance app, not a redesigned product.
