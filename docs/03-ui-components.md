# 03 - UI Tokens, Components, Screen Composition and Accessibility

Scope: SwiftUI design tokens and reusable components for "Mini Finance". Visual facts come from `01-design-extraction.md` (tags `[figma]` / `[assumed]`). Data names come from `02-data-architecture.md` (`TransactionService`, `LoadState<Value>`, `Transaction`, `TransactionCategory`, `CategorySpending`, `AccountSummary`). No Swift source here, only decisions and API sketches.

Legend used below:
- **[figma]** value read from the Figma file.
- **[derived]** inferred from a Figma value (e.g. ratio, nearest system style).
- **[iOS/a11y]** an adaptation or addition we make for iOS, accessibility, or because Figma has a gap. These are NOT design facts.

Guiding rules: views render, view models decide. No formatting, filtering or validation in a `body`. Every screen state goes through one container. Every component works in light/dark and at AX5 Dynamic Type. No raw literals in views.

---

## 1. Tokens

Namespaces are caseless enums (`AppColor`, `AppFont`, `AppSpacing`, `AppRadius`) to avoid clashing with SwiftUI's `Color`/`Font`. Colors live in the Asset Catalog (Any/Dark appearance per set) so there is no `colorScheme` branching in code.

### 1.1 Color

Names follow the Figma token names (`fill/secondary` -> `AppColor.fillSecondary`) so design and code stay greppable against each other.

| Token | Figma name | Light [figma] | Dark [derived] | Notes |
|---|---|---|---|---|
| `surface` | surface/primary | #FFFFFF | #121110 | Screen and card background |
| `fillPrimary` | fill/primary | #FFFFFF | #1B1A18 | Raised element on `surface` (sheet body, icon circle bg) |
| `fillSecondary` | fill/secondary | #F6F6F4 | #262422 | Chips, pills, search field, form field bg |
| `borderPrimary` | border/primary | #F4F4F2 | #2F2D2A | 1pt ring around icon circle; also hairline separators |
| `textPrimary` | text/primary (= palette/charcoal/16) | #4D4845 | #F2F0ED | Titles, row names. ~10:1 on white |
| `textSecondary` | text/secondary | hex NOT retrieved; [assumed] #6F6B67 | #BDBAB5 | Used only for the nav title in screenshot; confirm |
| `textTertiary` | text/tertiary | #928F8B | #A6A4A0 | Captions, dates. **3.2:1 on white, fails 4.5:1 for 12pt text** (see 1.1.1) |
| `iconSecondary` | icon/secondary | #A6A4A0 | #8C8985 | Chevrons, search icon. ~2.5:1 on white; decorative only |
| `iconInverse` | icon/inverse | #FFFFFF | #FFFFFF | Icon on verdant FAB / primary button |
| `expense` | text/accent/ruby/secondary | #C9362B | #FF6B5E | Expense amounts. 5.2:1 on white |
| `income` | (none in Figma) | [iOS/a11y] #3F7359 | #6FBF9C | Derived from verdant; Figma shows only expenses. 5.5:1 on white |
| `accentBrand` | fill/accent/verdant/primary | #4E886F | #5FA085 | FAB, primary button, income bar |
| `accentWarning` | fill/accent/ember/primary | #FD8240 | #FF9A63 | Budget "spent" bar (dashboard), near-limit |
| `overlayScrim` | (sheet dim) | black @ 20% [assumed] | black @ 50% | Native sheet supplies its own scrim; token kept for custom overlays only |

Category/bar hues: Figma names five accent hues (`sanstone, verdant, ruby, ember, marigold`) with `primary`/`secondary` variants, but only `ruby/secondary`, `ember/primary`, `verdant/primary` hex values were retrieved. Define `AppColor.accentMarigold`, `accentRuby`, `accentSanstone` sets now with [assumed] values and replace after the Figma re-fetch (open question 1). Segment "left" portion = same hue at 40% opacity [figma].

#### 1.1.1 Contrast findings that drive adaptations [iOS/a11y]

| Pair (light) | Ratio | Issue | Adaptation |
|---|---|---|---|
| `textTertiary` #928F8B on #FFF | ~3.2:1 | Fails 4.5:1 for 12pt caption text | Keep Figma value for decorative/large uses; add `textTertiaryAccessible` #77746F (~4.6:1) and use it for all caption text. Deviation recorded in section 5 |
| `iconSecondary` #A6A4A0 on #FFF | ~2.5:1 | Below 3:1 for meaningful graphics | OK while icons are decorative or have adjacent text. Do not use for icon-only controls; use `textPrimary` there |
| White icon on `accentBrand` #4E886F | ~4.1:1 | Passes 3:1 graphic, fails 4.5:1 text | `PrimaryButton` (has text) uses a darker fill [derived] #3F7359 (same value as light `income`) so white text passes 4.5:1. FAB (icon only) keeps Figma #4E886F |
| `expense` on `fillSecondary` | ~4.8:1 | Passes | none |

Dark values are proposals, derived by inverting lightness while keeping hue, and must be re-checked for 4.5:1 text / 3:1 graphics in both Normal and Increase Contrast. Add High Contrast variants for `textTertiaryAccessible`, `borderPrimary`, `income`, `expense` if time allows.

### 1.2 Typography

Family in Figma is **Geist** [figma]; sizes and weights [figma] except where marked. Letter spacing 0 on all styles [figma].

| Token | Figma style | Size / line | Weight | Dynamic Type base (relativeTo) | Used for |
|---|---|---|---|---|---|
| `amountHero` | large title/regular | 32 / 48 | Regular | `.largeTitle` | Balance/"Left" amount, detail sheet amount |
| `amountCard` | (24 / 36) [derived: text box 36 high, 1.5 ratio like 32/48] | 24 / 36 | Regular | `.title2` | Category card amounts ($332.75) |
| `titleScreen` | (16 / 24) [derived: text box 24 high] | 16 / 24 | Medium [assumed] | `.headline` | Nav title, sheet title, category name |
| `rowTitle` | subheadline/medium | 14 / 20 | Medium | `.subheadline` | Row names, section titles, row amounts |
| `chipLabel` | footnote/medium | 12 / 16 | Medium | `.footnote` | Pill labels ("See all", month) |
| `caption` | footnote/regular | 12 / 16 | Regular | `.footnote` | Subtitles, dates, bar captions |

Rules:
- Every token is declared relative to a text style so it scales with Dynamic Type. Raw `.system(size:)` or fixed `Font.custom(size:)` without `relativeTo:` is not allowed.
- Figma sizes (14, 12) are below the iOS defaults (15, 13) for `.subheadline`/`.footnote`; that is fine because scaling is proportional from the chosen base.
- Amounts use tabular digits (`.monospacedDigit()`) so lists align.
- No `minimumScaleFactor` on body text. Allowed only on `amountHero`, with `lineLimit(1)` plus a wrapping fallback at accessibility sizes.

#### 1.2.1 Font decision: bundle Geist or use system?

| Option | Pros | Cons |
|---|---|---|
| A. System font (SF Pro) only | Zero setup, perfect Dynamic Type, no licensing, no loading failure modes | Does not match the design's typeface |
| B. Bundle Geist | Matches design; `Font.custom(_, size:, relativeTo:)` still scales with Dynamic Type | Font files in bundle (+~150 KB for 2 weights), registration via `UIAppFonts`, silent fallback if misnamed |

**DECIDED (user: "keep things Apple native"): Option A, system font (SF Pro).** Geist is not bundled. `AppFont` stays as the single seam and returns system text styles with the weights in the table above (e.g. `.subheadline.weight(.medium)`), so Dynamic Type works with no extra code and a custom face can be added later by changing only that file. Sizes in the table are the Figma values for reference; on device the system text-style sizes apply. No font files, no `UIAppFonts`, no OFL license entry needed.

### 1.3 Spacing [figma scale 4/8/12/16/20/24]

| Token | pt | Where [figma] |
|---|---|---|
| `xxs` | 4 | Title-subtitle gap, bar segment gap |
| `xs` | 8 | Icon-only pill padding, pill vertical padding |
| `sm` | 12 | Icon-to-text gap in rows, pill horizontal padding |
| `md` | 16 | Inner card padding [assumed from layout] |
| `lg` | 20 | **Screen horizontal gutter**, header-to-content gap |
| `xl` | 24 | Section vertical padding, row-to-row gap |

Component-specific sizes (icon circle 40, FAB 64, bar heights 4/12/16, search field 36) are NOT spacing tokens. They are `@ScaledMetric` constants private to their component so they grow with Dynamic Type where it matters (icon circle, bar height) and stay fixed where it does not (FAB can scale but is capped).

Layout is expressed relative to the container (gutter + flexible widths), never as 393pt frames. Figma's 353pt content width is an outcome of 393 - 2x20, not a constant.

### 1.4 Radius

| Token | Value | Where |
|---|---|---|
| `bar` | 4 [figma] | Progress bar segments, avg line |
| `chip` | 24 [figma] | Pills, "See all", month pill, search field [assumed same] |
| `card` | 16 [assumed from screenshot] | Bottom-sheet cards, new-type cards, detail cards, hero background |
| `round` | 100 [figma] -> use `Circle()` / `Capsule()` | Icon circles, FAB, avatar |

`chip` 24 on a 32pt pill is effectively a capsule; at larger Dynamic Type heights use `Capsule()` so the shape stays correct. The `chip` token documents intent.

### 1.5 Shadows / elevation

**The Figma design has no shadows** [figma]. Elevation is expressed by fills (`fillSecondary` on `surface`) and a 1pt `borderPrimary` ring. Therefore: no `AppShadow` token is created. The old draft's `AppShadow.card` is removed. If a future component needs separation (e.g. a floating bar over scrolling content), prefer `.regularMaterial` or the hairline border; if a shadow is truly needed, add a single token then with a reason. The FAB has no shadow in the file [figma]; keep it flat for fidelity, which also works in dark mode.

### 1.6 Other tokens

| Token | Value | Notes |
|---|---|---|
| Hairline | 1pt `borderPrimary` | The only stroke in the design [figma] |
| Min tap target | 44pt [iOS/a11y] | Figma has 32pt pills and 36pt search field; extend hit area with `contentShape`/padding, keep visuals |
| Icon sizes | 16 / 24 / 32 [figma] | SF Symbols, `Image(systemName:)` scaled with text style |
| Hatch | 2pt stroke, 135 deg, 40% hue [figma] | Used in `ProgressBar` and chart marks |

### 1.7 When does a value become a token?

| Situation | Decision |
|---|---|
| Color/font/radius used 2+ places or carrying meaning | Token |
| Must differ per appearance or accessibility setting | Token (Asset Catalog) |
| One-off geometry in a single layout | Local `@ScaledMetric` constant |
| Raw `Color.red`, `.padding(13)`, `.font(.system(size:))` in a view | Rejected in review |
| Spacing off the scale | Snap to the scale, or add one named step with a reason |

---

## 2. Component catalogue

### 2.1 Reusable vs screen-specific: decision rule

A piece is a **shared component** (`Shared/UI/`) if (a) it appears on 2+ of the 5 required screens, or (b) it is a self-contained visual with its own accessibility contract (e.g. `BalanceCard`, even if used once), or (c) it is a state/feedback element used by every screen. Otherwise it is a private subview of its screen. Shared components take plain values (strings, `Decimal`, small display structs) and closures, never view models or services, so previews are trivial. Start private; promote on the second real use.

Shared components never switch on `LoadState` except `StateContainer`.

### 2.2 Shared components

| Component | Purpose | API sketch | Figma nodes | Used in | States | Accessibility |
|---|---|---|---|---|---|---|
| `TransactionRow` | One transaction: category icon, title, caption, amount, date, review marker | `TransactionRow(model: TransactionRowModel)` (display struct built by VM: `title, caption, amount, currencyCode, date, category, isReviewed`) | `106:3534`, `106:3544`, `106:3554`; list `106:40292...106:40352` | Dashboard recent, Transactions list, Budget category drill-down | normal; unreviewed (shows compact badge); long title (truncates 1 line, wraps at AX); placeholder (redacted) | One combined element. Label: "Whole Foods, Groceries, expense 54 dollars 20 cents, Oct 12, not reviewed". Hint "Opens details" only when it is a link. HStack -> VStack at accessibility sizes. Whole row is the 44pt+ target |
| `CategoryIcon` | 40 circle with ring, white bg, category art or SF Symbol (sizes 32/40/64/80) | `CategoryIcon(category: TransactionCategory, size: Size)` | circle in `106:3534`; hero icon `106:41865`; 64 overlap `106:40133` | Row, Detail header, Budget rows/cards, Add form | size variants; asset vs SF Symbol fallback | Hidden from VoiceOver when inside a row/badge that already speaks the category; labeled `category.name` when standalone |
| `CategoryBadge` | Icon + name chip | `CategoryBadge(category:, style: .icon / .iconAndLabel)` | iOS-only addition (Figma shows category as plain text in key/value row `106:40154`) | Detail, Add form picker, Transactions filter | normal, selected (fill `fillSecondary` -> outlined `accentBrand`) | Selected exposed with `.isSelected` trait; label = category name; never color alone |
| `AmountText` | Format `Decimal` with currency, sign, income/expense color | `AmountText(amount: Decimal, currencyCode: String, style: .hero / .card / .row / .detail)` | amounts in `106:3534`, `106:5997`, `106:40133` | Row, BalanceCard, Budget card, Detail | expense (`expense`, unsigned as in design), income (`income`, "+" prefix), zero | Spoken "expense 54 dollars 20 cents" / "income 3,000 dollars", never "minus". Sign/word plus color, not color alone. Tabular digits |
| `SectionHeader` | Title (14/20 medium) + subtitle (12/16) + optional trailing pill action | `SectionHeader(title:, subtitle: nil, actionTitle: nil, action:)` | `106:3530`, `106:3977`, `106:39666` | Dashboard sections, Budget sections | with/without action | `.isHeader` trait. Action is its own `Button` with specific label ("See all recent transactions") |
| `PillButton` | Small fill/secondary pill: "See all", "See more", "Learn more", month picker, edit | `PillButton(title: String?, systemImage: String?, action:)` | `106:3564`, `106:39397`, `116:6539`, month/adjust pills in `106:5997` | Dashboard, Budget, Transactions | normal, pressed, disabled; icon-only (32x32 visual) | Icon-only requires explicit label. Hit area extended to 44pt. Month pill is a `Menu`/`Button` with value "February" |
| `PrimaryButton` | Main CTA (Save, Retry, empty-state action) | `PrimaryButton("Save", systemImage: nil, isLoading: Bool, action:)` | **iOS-only addition**: Figma has no filled text button. Styled from FAB hue (`106:6191`) and pill radius | Add form, Error state, Empty state | normal, loading (spinner, taps disabled), disabled | Native `Button`; min height 44-52 scaled; loading announces "Saving"; disabled via `.disabled` |
| `FloatingAddButton` | 64x64 round verdant FAB with plus | `FloatingAddButton(action:)` | `106:6191`, `106:39593`, `106:40112` | Dashboard, Transactions (overlay, 20pt from trailing edge, above tab bar) | normal, pressed | Label "Add transaction". `safeAreaInset` so it never covers last row; scrolls clear at AX sizes. No shadow (design has none) |
| `ProgressBar` | Spent (solid) / left (same hue 40% + hatch) segmented bar | `ProgressBar(fraction: Double, tint: Color, height: Height)` heights 16 / 12 / 4 | `106:6xxx` summary, `106:41891`, `106:3986` | `BalanceCard`, `BudgetCategoryRow` | under, near, over (clamped 0...1 for fill; over state rendered with `accentWarning`/`expense`) | Always `accessibilityHidden`; owner supplies text ("$1,285 of $3,500 spent"). Reduce Motion: no fill animation |
| `BalanceCard` | Dashboard hero: month pill, adjust pill, amount + "Left", bar, "$X / $Y spent" caption | `BalanceCard(title: String, amount: Decimal, spent: Decimal, total: Decimal, monthLabel: String, onAdjust: ...)` | `106:5997`, `106:39399` | Dashboard | normal, over budget, placeholder | Combined: "Left this month, 2,215 dollars 90 cents, 1,285 of 3,500 spent". Bar hidden. Pills stay separate buttons (so combine only the text block) |
| `BudgetCategoryRow` | Category + spent vs budget + bar. Two styles: `.compact` (32 icon, 100x4 mini bar) and `.card` (40 icon, 12 bar, 208pt tall) | `BudgetCategoryRow(spending: CategorySpending, style:)` | compact `106:3981`; card `106:41879`, `106:42072`, `106:42265`, `106:42458` | Dashboard (top 3, compact), Budget (card) | no budget (nil -> no bar, spent only), under, over | Combined: "Dining, 180 of 250 dollars spent, 72 percent, 70 dollars left". Over budget adds icon + text "over by 20 dollars", not red alone |
| ~~`SearchField`~~ | DROPPED: use system `.searchable` on the Transactions list (Figma `106:40362` is the visual reference only) | n/a | `106:40362` | Transactions list | n/a | System search bar, full VoiceOver/Dynamic Type support |
| `ReviewedStatusBadge` | Reviewed / Not reviewed pill | `ReviewedStatusBadge(isReviewed: Bool, style: .compact / .full)` | **iOS-only addition** (no review state anywhere in Figma). Styled as a `PillButton`-like pill, icon `check-circle` `76:1486` | Row (compact, shown only when unreviewed), Detail (full) | reviewed (`checkmark.circle.fill`, `accentBrand`), unreviewed (`circle.dashed`, `textTertiaryAccessible`) | Icon AND text differ; compact variant is hidden inside the row (folded into row label); full variant label "Reviewed"/"Not reviewed" |
| `NavIconButton` | 24pt icon in 44pt target for nav bar actions (back, filter, add, edit, bell) | `NavIconButton(systemImage:, label:, action:)` | `106:6210`, `106:40366`, `106:42651`, `106:41870` | Toolbar of all screens | normal, disabled | Explicit label per use ("Filter transactions"). Native back button preferred (see section 5) |
| `StateContainer` | The only `switch` over `LoadState<Value>` | `StateContainer(state:, empty: EmptyStateConfig, retry:, placeholder:, content:)` | **iOS-only addition** (Figma has no loading/empty/error) | All 5 screens | idle/loading, loaded, empty, error | Loading: single "Loading" element, skeleton hidden. Empty/error: combined element + Retry button. See section 4 |
| `EmptyStateView` | Icon, title, message, optional action | `EmptyStateView(config:)` | iOS-only addition, uses `PrimaryButton`, `titleScreen`, `caption` | via `StateContainer` | with/without action | Icon hidden; title `.isHeader`; block combined |
| `ErrorStateView` | Message + Retry | `ErrorStateView(message:, isRetryable:, retry:)` | iOS-only addition | via `StateContainer` | retryable / not | Announced on appearance via `AccessibilityNotification.Announcement`; Retry distinct button |
| `FormField` | Label + input + helper/validation message, styled with `fillSecondary`, `chip`-radius | `FormField(label:, error: String?, helper: String?) { input }` | iOS-only addition; styling from `SearchField` `106:40362` | Add transaction | normal, focused, error (icon + text) | Label bound to input; error read as value, announced on submit failure; focus moves to first invalid field |

Placeholders for loading are not a component: rows/cards are rendered from a `.placeholder` display value with `.redacted(reason: .placeholder)`; shimmer is skipped under Reduce Motion.

### 2.3 Stays screen-specific (private subviews)

| Piece | Why not shared | Source nodes |
|---|---|---|
| Transaction detail header (64 icon overlapping the sheet top, amount 32/48, title) | One screen | `106:40133`, `106:40146` |
| `DetailRow(label:value:)` key/value (Payment Date, Provider, Category) | Used 3x but on one screen; promote if Add form review step needs it | `106:40146`, `106:40150`, `106:40154` |
| Spending Insight bar chart (7 bars, avg line) and Cash Flow chart | Not in the 5 required screens' data model; build with Swift Charts only if time remains | `106:38133`, `106:40406`, `106:39696`, `106:3591` |
| Category detail hero (150pt pattern + 80 icon) | Optional drill-down; uses `CategoryIcon(size: .hero)` | `106:41865`, `106:40374` |
| Add form type selector (Expense/Income) and date row | Tied to the form VM | iOS-only |
| Filter / sort menu on Transactions | Only the list | `106:40366` |

### 2.4 Not built (in Figma, out of scope)

Tab bar with 5 icon-only items (replaced by native `TabView`, see section 5), article row and article screen (`116:6508`, `116:6842`), Upcoming Bills list (`106:39672`; same anatomy as `TransactionRow`, no data model), "New" type cards (`106:39622`, `106:39634`, `106:39649`; open question 4), brand logos, background artwork.

---

## 3. Screen composition and Figma mapping

### 3.1 Figma node -> component

| Figma node | Name | Becomes |
|---|---|---|
| `106:3528` main | Dashboard frame | `DashboardView` composition |
| `106:5997` / `106:39399` | Summary header | `BalanceCard` (+ `PillButton`, `ProgressBar`) |
| `106:3530` / `106:3977` / `106:39666` | Section header | `SectionHeader` |
| `106:3534`, `106:3544`, `106:3554`, `106:40292...106:40352` | Transaction row | `TransactionRow` (+ `CategoryIcon`, `AmountText`) |
| `106:39672`, `106:39681` | Bill row | `TransactionRow` (caption = due date), no separate component |
| `106:3564`, `106:39397`, `116:6539` | Pill buttons | `PillButton` |
| `106:6191`, `106:39593`, `106:40112` | FAB | `FloatingAddButton` |
| `106:3981` | Category row compact | `BudgetCategoryRow(.compact)` |
| `106:41879`, `106:42072`, `106:42265`, `106:42458` | Category card | `BudgetCategoryRow(.card)` |
| `106:41891`, `106:3986`, summary marks | Segmented bar | `ProgressBar` |
| `106:40362` | Search field | `SearchField` |
| `106:6210`, `106:40366`, `106:42651`, `106:41870`, `106:6919` | Top nav variants | native toolbar + `NavIconButton` |
| `106:6193`, `106:39595`, `106:40114` | Tab bar | native `TabView` (adapted) |
| `106:39618` / `106:39620` | New sheet | native `.sheet` + `AddTransactionView` (adapted) |
| `106:39622`, `106:39634`, `106:39649` | New-type cards | not built / open question 4 |
| `106:40131` / `106:40133` | Details sheet | `TransactionDetailView` (+ private `DetailRow`) |
| `106:40146`, `106:40150`, `106:40154` | Key/value rows | private `DetailRow` |
| `106:38133`, `106:40406`, `106:39696`, `106:3591` | Charts | screen-specific, optional |
| `106:41865`, `106:40374` | Category detail hero | screen-specific, optional |
| `116:6508`, `116:6708`, `116:6842` | Articles | not built |
| (none) | Reviewed state, Add form, loading/empty/error | iOS-only: `ReviewedStatusBadge`, `FormField`, `StateContainer`/`EmptyStateView`/`ErrorStateView`, `PrimaryButton` |

### 3.2 Screen -> component composition

| Screen (Figma frame) | Composition | `LoadState` Value |
|---|---|---|
| **Dashboard** (`106:3528`) | `StateContainer` > ScrollView: `BalanceCard`; `SectionHeader("Expense categories", See all)` + top 3 `BudgetCategoryRow(.compact)`; `SectionHeader("Recent transactions", See all)` + 5 `TransactionRow`; `FloatingAddButton` overlay. Cash flow / insight / articles omitted | `DashboardContent { summary: AccountSummary, topSpending: [CategorySpending], recent: [Transaction] }` |
| **Transactions** (`106:40289`) | Toolbar (`NavIconButton` filter); `SearchField`; grouped-by-day list of `TransactionRow` (NavigationLink by id); `FloatingAddButton`; `StateContainer` handles empty/no-results | `[Transaction]` |
| **Transaction detail** (`106:39664`) | Private header (`CategoryIcon(.large)`, `AmountText(.hero)`, title); `ReviewedStatusBadge(.full)` + "Mark as reviewed" `PrimaryButton`; private `DetailRow` x N (date, category via `CategoryBadge`, note); optimistic toggle with inline error | `Transaction` |
| **Budget / category** (`106:41877`, `106:40374`) | `BalanceCard` summary (reused); list of `BudgetCategoryRow(.card)`; tap -> filtered `TransactionRow` list | `[CategorySpending]` |
| **Add transaction** (`106:38128`, adapted) | Sheet in own `NavigationStack` titled "New" with Close `NavIconButton`; Expense/Income control; `FormField` x (amount, merchant, category via `CategoryBadge` picker, date, note); `PrimaryButton("Save", isLoading:)` | none for form; `SubmitState` (`idle, submitting, failed`) |

---

## 4. Managing loading / empty / error / loaded

One pattern for all screens (consistent with `02-data-architecture.md` section 10):

1. The `@MainActor @Observable` view model owns `private(set) var state: LoadState<Value>`: `idle, loading, loaded(Value), empty, error(UserFacingError)`.
2. The view model chooses `empty` vs `loaded`; views never test `.isEmpty`.
3. The view passes `state` to `StateContainer`, the only switch over `LoadState`.
4. `.task { await vm.load() }` and `.refreshable { await vm.refresh() }` on the screen; `.refreshable` is attached outside the container so every state is pullable (empty/error are wrapped in a full-height `ScrollView`).

| Concern | Behavior |
|---|---|
| Refresh with data | Stale-while-revalidate: stays `loaded`, system spinner shows; failure shows a transient banner (`vm.refreshError`), not a full error screen |
| First load flash | Skeleton only after ~250 ms (decided in VM) |
| Retry | Calls `vm.load()`; hidden when `isRetryable == false` |
| Dashboard | One `LoadState<DashboardContent>`; pieces load together via `async let` |
| Detail | Never "empty"; unknown id -> `.error("Transaction not found")`. Review toggle: optimistic, rollback + inline error on failure |

| Screen | Empty copy and action | Loading placeholder | Error |
|---|---|---|---|
| Dashboard | "No activity yet" / action opens Add | redacted `BalanceCard` + 3 rows | Retry; pull-to-refresh |
| Transactions | "No transactions" + Add; filtered: "No results" + "Clear filters" | 6 redacted `TransactionRow` | Retry |
| Detail | n/a | redacted detail layout | Retry |
| Budget | "No spending yet" | 4 redacted `BudgetCategoryRow` | Retry |
| Add | n/a (`SubmitState`) | button `isLoading` | inline error, input preserved |

The empty/error/loading visuals are all [iOS/a11y] additions built from existing tokens (`fillSecondary`, `textPrimary`, `caption`, `PrimaryButton`).

---

## 5. Deviations, adaptations and open questions

### 5.1 Adaptations (iOS/accessibility choices, not design facts)

| # | Gap or issue in Figma | Adaptation | Why |
|---|---|---|---|
| 1 | No reviewed/unreviewed state | `ReviewedStatusBadge` (icon + text, pill styled from existing chips); row shows it only when unreviewed; detail has full badge + toggle | Required by data model (`isReviewed`) and brief |
| 2 | No Add form, only type picker sheet | Form built from `FormField`/`PrimaryButton` using existing tokens; picker cards not reproduced | Brief requires Add screen; data model has no Budget/Bills/Subscription types |
| 3 | No dark-mode UI tokens | Dark values derived (section 1.1), flagged, checked for contrast | Brief requires dark mode |
| 4 | Geist is not a system font | Use SF Pro via system text styles behind the `AppFont` seam; weights kept from Figma | Apple-native decision; perfect Dynamic Type, no licensing |
| 5 | Hex values missing (text/secondary, marigold/ruby primaries, hero tan, article tags, scrim) | [assumed] values in Asset Catalog, marked in token table | Re-fetch pending |
| 6 | `textTertiary` fails 4.5:1 | `textTertiaryAccessible` for caption text | WCAG AA |
| 7 | All amounts red and unsigned; no income color | `income` token derived from verdant; income shows "+", expenses show "-" (via the locale currency formatter); both are spoken as "income" / "expense" | Color is not the only signal |
| 8 | Fixed 393pt layouts | Gutter 20 + flexible widths; row/card stats stack at accessibility sizes; verified on 375pt | No single-device hardcoding |
| 9 | 5 icon-only tabs (Home, Budget, Savings, Invest, Wallet) | Native `TabView` with 3 labeled tabs (Dashboard, Transactions, Budget); FAB stays | Icon-only tabs lack labels; Savings/Invest/Wallet have no data |
| 10 | Custom top nav with centered 24pt title | Native `NavigationStack` toolbar; `titleScreen` style for custom titles only | Back swipe, large-title behavior, VoiceOver for free |
| 11 | Details as bottom sheet over Cash Flow | Detail is a pushed `NavigationStack` route by id (matches doc 02, supports deep links); sheet is used for Add | Simpler state ownership |
| 12 | Hatch pattern for "left" portion | Canvas stripes at 40% opacity, plain 40% fill under Reduce Transparency/Motion | Not a signal carrier; text states the value |
| 13 | No shadows | No shadow token; flat FAB | Fidelity |
| 14 | Category art is multicolor, only 16 Figma categories vs our 9-case enum | `TransactionCategory` -> asset/SF Symbol mapping lives in a UI extension (e.g. groceries/dining -> foodstuff/fork.knife, transport -> transportation/car, shopping -> shopping/bag, bills -> receipt, entertainment -> ticket, health -> cross.case, income -> banknote, other -> circle.grid.2x2). Assets exported from Figma where they exist, SF Symbol otherwise | Brief: SF Symbols when assets unavailable |
| 15 | 32-36pt tap targets (pills, search) | 44pt hit area via padding/`contentShape` | HIG |

### 5.2 Open questions

1. Re-fetch missing Figma tokens (`106:6193`, `106:6210`, `106:3976`, `106:41877`, `106:39618`, `116:6504`) after the rate limit resets: text/secondary, marigold/ruby/sanstone primaries, scrim opacity, sheet card radius.
Questions 2-7 are RESOLVED (user: "keep things Apple native, otherwise whatever you recommend"):

2. RESOLVED: `BalanceCard` follows Figma (budget left = total budget - spent), with `AccountSummary.balance` as a secondary line.
3. RESOLVED: explicit signs via the system currency formatter ("+" income, "-" expense), plus spoken "income"/"expense". Native and not color-only.
4. RESOLVED: "New" type cards are not reproduced; Add opens the transaction form directly with a native segmented `Picker` for Expense/Income.
5. RESOLVED: system `.searchable` on the Transactions list. The custom `SearchField` component is dropped from the catalogue (section 2.2 row and file layout below are superseded).
6. RESOLVED: system font (SF Pro); Geist is not bundled (see 1.2.1).
7. RESOLVED: charts out of scope for the core; native Swift Charts only if time remains, with an accessibility description.

Apple-native consequences: native `TabView`, `NavigationStack` toolbar, `.searchable`, `.refreshable`, `.sheet` with `.presentationDetents`, SF Symbols (Figma category art only where an SF Symbol has no match), system `Form`/`DatePicker`/`Picker` inside the Add sheet, and system materials/semantic colors where the Figma value has no distinct meaning.

---

## 6. Accessibility checklist (per component, verify before merge)

| Area | Rule |
|---|---|
| Grouping | Rows and cards use `.accessibilityElement(children: .combine)` or `.ignore` + explicit label. One swipe = one logical item |
| Label/value/hint | Label says what it is; value says state; hint only for non-obvious results. No "button" in labels |
| Headers | `SectionHeader`, screen titles, empty-state titles get `.isHeader` |
| Dynamic Type | All text via `AppFont` tokens (relative to text styles). Icon frames, bar heights, paddings via `@ScaledMetric`. Test XS and AX5 |
| Layout switching | `ViewThatFits` / `dynamicTypeSize.isAccessibilitySize` switches HStack -> VStack in `TransactionRow`, `BalanceCard`, `BudgetCategoryRow`. Amounts never truncate |
| Tap targets | 44x44 minimum; whole row tappable |
| Color | Never the only signal: review state (icon+text), income/expense (word/sign+color), over-budget (icon+text). Check light, dark, Increase Contrast |
| Motion/transparency | Honor Reduce Motion (no shimmer/bar animation) and Reduce Transparency (solid fills) |
| Dynamic content | Errors and "Transaction added" announced via `AccessibilityNotification.Announcement`; focus to first invalid field |
| Forms | Label bound to input; `.decimalPad` for amount; inline persistent validation text |
| Images | Decorative icons hidden; meaningful ones labeled; SF Symbols via `Label` where text exists |
| Dark mode | No hardcoded white/black; everything through `AppColor` |
| Small device | Verified on iPhone SE (375pt) at AX sizes; vertical scroll, no clipping |

---

## 7. Previews and file layout

Previews: every component ships previews from fixtures and `MockTransactionService` (`.loaded`, `.empty`, `.failing`, `.slow`). Component matrix: Light, Dark, `.xSmall`, `.accessibility5`, plus each variant (reviewed/unreviewed, over-budget, long title, income/expense). Screen matrix: loading, loaded, empty, error in Light and Dark, plus loaded at `.accessibility3` and on iPhone SE / Pro Max. View models accept an initial `LoadState` for previews. A `previewMatrix()` helper applies the appearance and type-size variants.

Layout (aligns with `Shared/UI` in doc 02):

```
Shared/UI/
  Tokens/      AppColor.swift AppFont.swift AppSpacing.swift AppRadius.swift
  Components/  TransactionRow.swift CategoryIcon.swift CategoryBadge.swift AmountText.swift
               SectionHeader.swift PillButton.swift PrimaryButton.swift FloatingAddButton.swift
               ProgressBar.swift BalanceCard.swift BudgetCategoryRow.swift
               ReviewedStatusBadge.swift NavIconButton.swift FormField.swift
  State/       StateContainer.swift EmptyStateView.swift ErrorStateView.swift EmptyStateConfig.swift
  Resources/   Assets.xcassets (colors, category icons)   // no custom fonts; search uses .searchable
```

### Key decisions

1. Tokens named after Figma tokens; dark values and income/accessible-caption colors are explicitly derived.
2. No shadow token because the design has none.
3. System font (SF Pro) behind one `AppFont` seam; Geist not bundled. Apple-native controls preferred everywhere (`.searchable`, `TabView`, system `Form`).
4. 15 shared components (`SearchField` dropped); charts, detail header, key/value rows, filter toolbar stay screen-specific.
5. Review state, Add form and all load/empty/error visuals are iOS-only additions built from existing tokens.
6. One `StateContainer` is the only switch over `LoadState`; refresh never reverts to the skeleton.
7. Accessibility is a per-component contract: combined elements, text plus icon, `@ScaledMetric`, layout switch at AX sizes, 44pt targets.
