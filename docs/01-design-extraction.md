# 01 - Design extraction (Figma "Mini Finance")

Tags: `[figma]` = read from the Figma MCP (metadata, design context, token list, screenshot). `[assumed]` = not provided by Figma (estimated from screenshot or standard practice). Nothing here is invented without a tag.

## 1. Sources and results

File key `XYHSE9Sp7kF4cerO9yD0xK`.

| Source | Tool | Result |
|---|---|---|
| Assets page `72:530` ("Assets") | get_metadata | OK. 4 kits: Icons, Brand Logos, Backgrounds (all under section label "Mini Finance"). |
| Budget page `106:750` ("Budget") | get_metadata | OK (1.0 MB XML). One section `106:749` "budget" (3951x3107) with 7 iPhone frames (393x852 base). |
| Budget section screenshot | get_screenshot | OK, all 7 screens viewed. |
| Budget `main` frame `106:3528` | get_design_context | Sparse (too large); metadata only. |
| `106:3529` transactions, `106:5997` summary, `106:6191` fab | get_design_context | OK, full code with token names. Summary (`106:5997`) and categories (`106:3976`) outputs were too large; summary code was read from the saved output, categories only as structure. |
| `106:6193` tab bar, `106:6210` top nav and further sub-frames | get_design_context | NOT fetched: Figma MCP Starter-plan call limit was hit mid-run. Their structure is known from metadata, their style values are not. |
| get_variable_defs (both nodes) | get_variable_defs | Failed: tool needs a layer selected in the Figma desktop app. Token names/values were instead taken from the "styles contained in the design" line that get_design_context returns. |
| search_design_system | - | Not run (rate limit). |

Result: the file contains real app screens (earlier "Cover has no screens" note is superseded). Token coverage is partial (see gaps).

## 2. Frame-to-screen mapping

All Budget frames are 393x852 (iPhone 15/16 class, status bar 59, home indicator 34) unless noted.

| Required screen | Closest frame | Node ID | Notes |
|---|---|---|---|
| Dashboard | "main" (scrolling, 393x2507) | `106:3528` | Summary, Spending Insight, Expense Categories, Cash Flow, Upcoming Bills, Recent Transactions, Articles, FAB, tab bar. This is a Budget-tab home, used as Dashboard. [figma] |
| Transactions list | "transactions" | `106:40289` | Top nav "Transactions" (back + filter), search field, list of 7 rows. [figma] |
| Transaction detail | "transaction details" (bottom sheet over Cash Flow) | `106:39664` (sheet `106:40133`) | Shows YouTube Premium $7.99, card ending 5642, Payment Date, Provider, Category. [figma] |
| Budget / Category | "budget - expense categories" (`106:41877`) and "shopping" category detail (`106:40374`) | `106:41877`, `106:40374` | Category list with spent/left bars; category detail with hero background, insight chart, recent transactions. [figma] |
| Add transaction | "create new" bottom sheet (picker only) | `106:38128` (sheet `106:39620`) | "New" sheet with 3 type cards: Budget, Bills, Subscription. No amount/merchant entry form. Partial match. [figma] |
| (extra) Article | "article" | `116:6842` | Not required. |

Screens with no frame:
- Transaction detail **reviewed/unreviewed state**: no frame, no badge, no "reviewed" wording anywhere in the file. [figma: absent]
- Add transaction **form** (amount, merchant, category, date, save): not designed.
- Dedicated Dashboard with account balance/net worth: not designed; use `main`.
- Empty, loading, error states: none.
- Dark-mode app screens: none (only dark background variants of the artwork).

## 3. Design tokens

### 3.1 Colors (named exactly as in Figma)

| Token | Hex | Source |
|---|---|---|
| surface/primary | #FFFFFF | [figma] |
| fill/primary | #FFFFFF | [figma] |
| fill/secondary | #F6F6F4 | [figma] (chips, "See all", month pill) |
| border/primary | #F4F4F2 | [figma] (1pt ring on transaction icon circle) |
| text/primary | #4D4845 | [figma] (= palette/charcoal/16) |
| text/tertiary | #928F8B | [figma] |
| icon/secondary | #A6A4A0 | [figma] |
| icon/inverse | #FFFFFF | [figma] |
| text/accent/ruby/secondary | #C9362B | [figma] (expense amounts, red) |
| fill/accent/ember/primary | #FD8240 | [figma] (budget "spent" bar on dashboard, orange) |
| fill/accent/verdant/primary | #4E886F | [figma] (FAB, brand green) |
| palette/charcoal/16 | #4D4845 | [figma] |

Seen in the screenshot but hex NOT retrieved (use token names, values `[assumed]` until fetched): text/secondary (mid grey for "Budget" title), category bar colors green/orange/amber/red (likely verdant/ember/marigold/ruby primaries), hero background tan/orange of category detail (marigold artwork), article tags green/orange text, income green "Money In" bar (appears verdant), mastercard badge colors (brand).

Theme/accents available as background artwork: names `sanstone, verdant, ruby, ember, marigold`, each in `light` and `dark` (see 5). The accent palette is therefore 5 hues; primary/secondary variants exist (`.../primary`, `.../secondary` naming). [figma]

Light/dark: the file has no dark UI variables. Dark exists only for background artwork. [figma]

### 3.2 Typography (family Geist) [figma]

| Token | Size / line height | Weight | Used for |
|---|---|---|---|
| large title/regular | 32 / 48 | 400 | Big amounts ($2,215.90, $345.90) |
| subheadline/medium | 14 / 20 | 500 | Row titles, section titles |
| footnote/medium | 12 / 16 | 500 | Pill/chip labels ("February", "See all") |
| footnote/regular | 12 / 16 | 400 | Captions, subtitles, dates |
| (title, ~24/30 amount in lists) | - | - | Visible in metadata: text heights 36 (category amounts, e.g. `$332.75`), 48 ($7.99 sheet), 24 (nav title, sheet title, category name) - sizes not fetched `[assumed]` |

Letter spacing 0 on all fetched styles. [figma]. Geist is not an iOS system font; it must be bundled or substituted with SF Pro `[assumed]`.

### 3.3 Spacing [figma, from code of 106:3529, 106:5997]

Scale in use: 4, 8, 12, 16, 20, 24 (and 40/52 for icon + row offsets).
- Screen horizontal padding: 20. Section padding: 24 vertical / 20 horizontal.
- Section header: title and subtitle gap 4; header to content 20 (list starts 84 from section top).
- Row: 40pt icon circle, 12 gap, text column; row-to-row gap 24 (64pt pitch). Name/caption gap 4.
- Pill: horizontal 12 / vertical 8, icon-only pill padding 8 (32x32).
- Segmented bar marks gap 4.

### 3.4 Radii [figma]

- Pills/chips and "See all": 24. Round icon/avatar/FAB: 100 (fully round). Bar segments: 4. Dashboard bar height 16; category bar height 12; avg line 3. Bottom sheet cards: radius not retrieved `[assumed]` 16 from screenshot.

### 3.5 Shadows / effects

None found in fetched code. Segmented bar "left" portion uses the same hue at 40% opacity with diagonal hatch lines (2pt stroke, 135 degrees). [figma]. FAB shadow: not present in code. Sheet overlay is a dimmed rectangle (opacity not fetched `[assumed]` 0.2).

### 3.6 Layout constants [figma]

- Status bar 59, top nav 52 (back/avatar left 64 wide, action right 64 wide, icon 24 at inset 20), tab bar 60 (5 items 40x40 at 72pt pitch, content inset 32, items: Home, Budget, Savings, Invest, Wallet; labels hidden), FAB 64x64 at (309,674) i.e. 20pt from right, above tab bar, 20pt icon padding, home indicator 34.
- Bottom sheet: 393x440 at y=412, top bar 52 with close icon 24 at x=349, title "New" 24pt high; detail sheet has a 64x64 overlapping icon at top center (y=-32) with 32x32 brand logo.

## 4. Repeated components / elements

| Component | Node IDs (examples) | Anatomy |
|---|---|---|
| Transaction row | `106:3534`, `106:3544`, `106:3554` (main); `106:40292...106:40352` (list screen) | 40 circle icon (border #F4F4F2, white bg) + name (14/20 medium #4D4845) + caption (12/16 #928F8B), right-aligned amount (14/20 medium #C9362B) + date/time (12/16 #928F8B). Amount all red (expenses). No reviewed badge. |
| Bill row | `106:39672`, `106:39681` | Same as transaction row, amount single line, caption = due date. |
| Section header | `106:3530`, `106:3977`, `106:39666` | Title 14/20 medium + subtitle 12/16 tertiary. |
| Summary header | `106:5997`, `106:39399` | Month pill + adjust pill (edit icon 16), amount 32/48 + "Left" 12/16, segmented spent/left bar, caption "$1,285 / $3,500 spent". |
| Segmented progress bar | `106:6xxx` summary marks; `106:41891`, `106:3986` | Spent solid fill, left = same color 40% + hatch, radius 4, heights 16 / 12 / 4 (compact row). |
| Category row (compact) | `106:3981` | 32 icon, name 14/20, mini bar 100x4, "$367 / $700". |
| Category card (expanded) | `106:41879`, `106:42072`, `106:42265`, `106:42458` | 40 icon, name 24 high, "N Transactions", amount 36 high + "Left", bar 12, caption. 208 tall, 20 inset. |
| Spending Insight bar chart | `106:38133`, `106:40406` | 7 bars (Aug..Feb), 32 wide, 53.5 pitch, current month hatched accent, avg line with "$739"/"$223" label. "Learn more" pill `106:39397`. |
| Cash Flow chart | `106:39696`, `106:3591` | 3 gridlines (100/50/0), two bars (Money In solid, Money Out hatched), legend rows with 8x16 swatch and amount. |
| Pill button ("See all", "See more", "Learn more", month) | `106:3564`, `106:39397`, `116:6539` | fill/secondary, radius 24, 12/8 padding, footnote/medium. |
| FAB | `106:6191`, `106:39593`, `106:40112` | 64x64, #4E886F, radius 100, white add icon 24. |
| Tab bar | `106:6193`, `106:39595`, `106:40114` | 5 icon-only items. |
| Top nav | `106:6210` (avatar, title, bell), `106:40366` (back, title, filter), `106:42651` (back, title, add), `106:41870` (back, edit), `106:6919` (back, filter) | 52 high, title centered 24 high. |
| Search field | `106:40362` | 353x36 input at inset 20, 20 icon, "Search" placeholder. |
| Bottom sheet | `106:39618` (new), `106:40131` (details) | Overlay + 393x440 sheet, top bar 52, close icon. |
| New-type card | `106:39622` budget, `106:39634` bills, `106:39649` subscription | 353x96, patterned theme background (verdant / marigold / ruby), title 14/20 + description 12/16 (light text), illustration at right. |
| Detail key/value row | `106:40146`, `106:40150`, `106:40154` | 354x20, label left, value right, 44 pitch. |
| Article row | `116:6508`, `116:6708` | 100x100 thumbnail (radius not fetched), tag 12/16, 2-line title, date. |
| Category detail hero | `106:41865` | 150 tall pattern background + 80x80 icon overlapping at y=127. |

## 5. Asset / icon inventory

Base icons, 24x24 (page `74:7189`), with SF Symbol substitutes [assumed]:

| Figma name (ID) | SF Symbol |
|---|---|
| home `76:1449` | house |
| invest `76:1452` | chart.line.uptrend.xyaxis |
| budget `76:1455` | chart.pie |
| wallet `76:1458` | wallet.pass |
| savings `76:1461` | leaf (or banknote) |
| notification `76:1464` | bell |
| chevron-right/down/left/up `76:1467,1470,1472,1474` | chevron.right/.down/.left/.up |
| close `76:1477` | xmark |
| edit `76:1480` | pencil |
| search `76:1483` | magnifyingglass |
| add `76:1492` | plus |
| subtract `76:1495` | minus |
| more `76:1498` | ellipsis |
| filter `76:1501` | line.3.horizontal.decrease |
| share `76:1504` | square.and.arrow.up |
| check-circle `76:1486` | checkmark.circle |
| checkbox `76:1489` | checkmark.square |
| arrow-up-circle `77:222` / arrow-down-circle `77:220` | arrow.up.circle / arrow.down.circle |
| lock `110:384` | lock |
| arrow-down/left/right/up `110:393,395,397,399` | arrow.down/.left/.right/.up |

Featured category icons, 32x32 (multicolor artwork, no SF equivalent; export from Figma): foodstuff `76:1524`, shopping `76:1538`, transportation `76:1552`, vacation `76:1567`, retirement `76:1578`, real estate `76:1598`, business `76:1624`, family `76:1636`, home `76:1648`, academics `76:1655`, stocks `76:1663`, fixed income `76:1672`, savings `76:1697`, emergencies `76:1719`, goals `76:1729`, holidays `76:1740`. SF fallbacks [assumed]: fork.knife, bag, car, airplane, figure.walk (retirement), building.2, briefcase, person.2, house, graduationcap, chart.bar, percent, banknote, cross.case, target, gift.

Brand logos 24x24 (`80:86`..`80:98`): google, framer, apple, facebook, spotify, youtube, microsoft, amazon, tesla, figma, openai, nike, nvidia. Export as images; SF fallback only `apple.logo`.

Backgrounds (393x852 artwork, `76:3121`..`76:3130`): sanstone `76:3121`/`76:3128`, verdant `76:3126`/`76:3125`, ruby `76:3122`/`76:3129`, ember `76:3123`/`76:3130`, marigold `76:3124`/`76:3127` (light/dark). Used cropped as card/hero/thumbnail backgrounds.

Illustrations: article thumbnails, pie illustration on "Budget" card (`106:39625`), bill (`106:39637`) and subscription (`106:39652`) art: custom vector, export from Figma.

## 6. Gaps and assumptions to carry forward

1. Hex values not retrieved for: text/secondary, category bar colors, marigold/ruby primaries, hero tan, article tag colors, sheet overlay opacity. Re-run get_design_context on `106:6193`, `106:6210`, `106:3976`, `106:41877`, `106:39618`, `116:6504` after the Figma rate limit resets; get_variable_defs needs a selection in Figma desktop.
2. No reviewed/unreviewed transaction state in design; must be designed by the app (suggest small badge in fill/secondary + check-circle icon) [assumed].
3. No Add-transaction form; only the "New" type picker sheet. Build a form with the same tokens [assumed].
4. No dark-mode UI tokens; dark must be derived [assumed].
5. Geist font is not available on iOS by default; bundle it (OFL) or use SF Pro.
6. All sample amounts in the design are expenses (red); no income-positive color retrieved (Money In bar looks verdant).
7. Hatch pattern for "left/remaining" segments is vector lines; implement as 40% opacity fill with diagonal stripes or plain 40% fill.
8. The file has no shadows, strokes other than the #F4F4F2 ring, or elevation tokens.
