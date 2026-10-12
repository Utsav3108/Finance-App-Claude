# 02 - Data Management and Architecture

Scope: layers, models, service protocol, persistence, state ownership, concurrency, tests, API migration. UI components and screen states live in `03-ui-components.md`; visual design in the design doc.

## 1. Facts about the repo (what drives the decisions)

| Fact | Source | Consequence |
|---|---|---|
| Deployment target **iOS 27.0** | `project.pbxproj` | Use `@Observable` (Observation), `NavigationStack`, SwiftData freely. No `ObservableObject`/`@StateObject` back-compat needed. |
| `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, Swift language mode 5 | `project.pbxproj` | Every type is `@MainActor` by default. Pure data/IO types (models, service impls, store actor) must be marked `nonisolated` / be actors explicitly, or they will silently pin work to the main thread. View models stay main-actor by default (desired). |
| Template code: `Item` (`@Model`), `ContentView` (`NavigationSplitView` + `@Query` + `modelContext.insert` in view), `FinanceAppWithClaudeApp` builds `ModelContainer(for: Item.self)` | `*.swift` | **Delete** `Item.swift` and `ContentView.swift`; **rewrite** the App file (new schema, composition root, `RootView`). The template violates the brief's "no data logic in view bodies" rule, so none of it is reusable. |
| Test targets `FinanceAppWithClaudeTests` / `UITests` exist | repo root | Unit tests go in the existing Tests target (Swift Testing or XCTest). |

## 2. Architecture: three layers, MVVM with `@Observable`

```
View (SwiftUI, dumb)  ->  ViewModel (@Observable, @MainActor)  ->  TransactionService (protocol)
                                                                      |
                                           TransactionRepository (impl) = FixtureSource + LocalStore(SwiftData)
```

| Layer | Responsibility | Knows about |
|---|---|---|
| **View** | Layout, bindings, forwarding user intents (`Task { await vm.refresh() }`, `.refreshable`). No formatting rules, no filtering, no I/O. | its view model only |
| **ViewModel** (`@Observable`, main-actor) | Owns `LoadState<Value>`, derived presentation data, form state + validation, calls service. | `TransactionService` protocol only |
| **Service** (`TransactionService`) | The seam. Async, throwing, UI-agnostic. | domain models |
| **Data sources** | `FixtureTransactionSource` (bundle JSON, stands in for the remote API) and `LocalStore` (SwiftData, `@ModelActor`). | persistence/IO |

Why MVVM + service, not "views with `@Query`": `@Query` in views puts data access in the view layer, is hard to unit test, and cannot represent loading/error/empty uniformly. We still use SwiftData, but only behind `LocalStore`.

Why not a heavier architecture (TCA, Clean Architecture with use cases): four screens and three operations. One protocol plus view models is the smallest structure that satisfies testability and the API-swap requirement. Business rules that are not UI (budget aggregation, validation) live in small pure types so they can be tested without a view model.

## 3. Folder layout

```
FinanceAppWithClaude/
  App/
    FinanceAppWithClaudeApp.swift     // composition root: builds container, service, injects
    RootView.swift                    // TabView/NavigationStack, routes
    AppEnvironment.swift              // holds service + factory methods for view models
  Domain/                             // pure Swift, nonisolated, Sendable, no SwiftUI/SwiftData
    Transaction.swift  TransactionCategory.swift  Budget.swift  AccountSummary.swift
    TransactionDraft.swift  TransactionValidator.swift
    TransactionServiceError.swift  LoadState.swift
  Data/
    TransactionService.swift          // protocols: TransactionService, BudgetProviding
    TransactionRepository.swift       // production impl: fixture + local overlay
    FixtureTransactionSource.swift    // reads transactions.json from bundle
    LocalStore.swift                  // @ModelActor over SwiftData
    PersistedModels.swift             // @Model types (never leave Data/)
    Resources/transactions.json
  Features/
    Dashboard/        DashboardView.swift  DashboardViewModel.swift
    Transactions/     TransactionListView.swift  TransactionListViewModel.swift
    TransactionDetail/ TransactionDetailView.swift  TransactionDetailViewModel.swift
    Budget/           BudgetView.swift  BudgetViewModel.swift
    AddTransaction/   AddTransactionView.swift  AddTransactionViewModel.swift
  Shared/UI/                          // reusable components (see doc 03)
FinanceAppWithClaudeTests/
  Mocks/ MockTransactionService.swift   MockBudgetProvider.swift   Fixtures.swift
  TransactionListViewModelTests.swift  AddTransactionViewModelTests.swift
  TransactionRepositoryTests.swift     BudgetCalculatorTests.swift
```

Rule: `Domain/` imports only `Foundation`. `Data/` imports `SwiftData`. `Features/` imports `SwiftUI` and `Domain`, never `Data/PersistedModels`.

## 4. Domain models

All are `nonisolated`, `Sendable`, value types, `Codable` where decoded from JSON.

```swift
nonisolated struct Transaction: Identifiable, Hashable, Sendable, Codable {
    let id: String                 // fixture: stable string id; added: UUID().uuidString
    var title: String              // merchant / title
    var amount: Decimal            // signed: negative = spending, positive = income
    var currencyCode: String       // "USD"; formatting is a view concern
    var date: Date
    var category: TransactionCategory
    var note: String?
    var isReviewed: Bool           // merged in by the service, see section 6
    var source: Source             // .fixture | .userAdded (drives e.g. a "Local" badge, not logic)
}

nonisolated enum TransactionCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case groceries, dining, transport, shopping, bills, entertainment, health, income, other
    var id: String { rawValue }
}
// Display name / SF Symbol / colour live in a UI extension in Shared/UI, not in Domain.

nonisolated struct CategorySpending: Identifiable, Sendable {   // derived, never stored
    var category: TransactionCategory
    var spent: Decimal
    var budget: Decimal?           // nil = no limit configured
    var id: TransactionCategory { category }
    var progress: Double? { ... }  // spent / budget, clamped for display by the view
}

nonisolated struct Budget: Sendable { var limits: [TransactionCategory: Decimal]; var period: DateInterval }

nonisolated struct AccountSummary: Sendable {   // derived
    var balance: Decimal
    var spentThisMonth: Decimal
    var incomeThisMonth: Decimal
    var unreviewedCount: Int
}
```

Decisions:
- **`Decimal`, never `Double`, for money.** Avoids rounding drift and `0.1 + 0.2` display bugs. JSON amounts are decoded from strings or numbers via `Decimal`'s `Codable`.
- **Signed amount, no separate income/expense enum.** One source of truth; "spending" is `amount < 0`. The add form takes a positive number plus an Expense/Income segmented control and applies the sign in `TransactionDraft.makeTransaction()`.
- **`isReviewed` lives on the domain model but is not in the fixture JSON.** The fixture is read-only seed data; review status is user state (section 6).
- **`category` is a closed enum.** Fixture values unknown to the enum decode to `.other` (custom `init(from:)`), so a server adding a category never breaks decoding.
- **Budgets** come from the fixture (`budgets` key) for the mock; a real API would serve them or they become user-configurable later. The brief only requires the screen, so no budget editing.

## 5. `TransactionService` protocol

```swift
nonisolated protocol TransactionService: Sendable {
    /// Full snapshot: transactions merged with local state, newest first.
    func fetchTransactions() async throws -> [Transaction]
    func addTransaction(_ draft: NewTransaction) async throws -> Transaction
    func setReviewed(_ isReviewed: Bool, forTransactionID id: Transaction.ID) async throws -> Transaction
}

/// Read-only budget limits. Separate from TransactionService: budgets are not transactions,
/// a real API would likely serve them from a different endpoint, and test doubles for
/// transaction logic should not have to implement them.
nonisolated protocol BudgetProviding: Sendable {
    func fetchBudget() async throws -> Budget
}
```

Design notes:
- **Budget is a separate protocol (`BudgetProviding`)**, injected only into the Dashboard and Budget view models. `FixtureTransactionSource` / the repository can conform to both; the app environment exposes them as two dependencies.
- **Async + throws only**, no Combine, no completion handlers. View models call with `await` and map errors to `LoadState.error`.
- **`setReviewed` takes an explicit Bool**, not "toggle": idempotent, safe to retry, and maps 1:1 to a `PATCH` later.
- **`addTransaction` takes `NewTransaction` (validated, id-less)** and returns the stored `Transaction`; the service assigns id and date-created. The view model never fabricates ids.
- **No `fetchSummary` / `fetchCategorySpending` on the service.** Those are derived (section 9). Keeping the service to raw data means the mock, fixture and real API all expose the same small surface, and aggregates are testable in isolation. If a real backend later serves aggregates, add a method then.
- **Returns whole `[Transaction]`**, no paging params yet (section 12 shows the additive change).
- Marked `Sendable` and `nonisolated` so impls can be actors; the `@MainActor` view model awaits across the isolation boundary and receives `Sendable` values.

Error model:

```swift
nonisolated enum TransactionServiceError: Error, Equatable, Sendable {
    case loadFailed          // fixture missing/corrupt, or network failure
    case notFound(String)    // setReviewed on unknown id
    case persistenceFailed   // SwiftData save threw
    case validation(TransactionValidationError)   // only if service re-validates
}
```

View models translate to user-facing text via a single `UserFacingError` mapping (`title`, `message`, `isRetryable`). Raw `localizedDescription` is never shown. Cancellation (`CancellationError` / `URLError.cancelled`) is swallowed, not shown as an error.

## 6. Composition: fixture + SwiftData overlay (the chosen design)

```
TransactionRepository: TransactionService, BudgetProviding
   |- FixtureTransactionSource   read-only: transactions.json  -> [Transaction], Budget
   |- LocalStore (@ModelActor)   read/write: SwiftData
         |- PersistedTransaction   user-added transactions
         |- ReviewRecord           (transactionID unique, isReviewed, updatedAt)
```

**Merge algorithm** in `fetchTransactions()`:

```
base      = fixtureSource.load()                  // [Transaction], isReviewed = false
added     = localStore.addedTransactions()        // [Transaction]
overrides = localStore.reviewOverrides()          // [id: Bool]
all       = (base + added).map { $0.with(isReviewed: overrides[$0.id] ?? $0.isReviewed) }
return all.sorted { $0.date > $1.date }
```

| Concern | Decision |
|---|---|
| Where review state lives | Only in `ReviewRecord`, keyed by transaction id, for fixture **and** added transactions. One mechanism, one merge point. |
| Fixture initial review state | Optional `"isReviewed"` in JSON is the default; a `ReviewRecord` overrides it. Deleting records resets to seed. |
| Added transactions | Stored in `PersistedTransaction`, never written back to the JSON (bundle is read-only). |
| ID collisions | Added ids are UUID strings; fixture ids are `txn-001` style. No overlap by construction. |
| Orphan review records (id no longer in fixture) | Ignored at merge time; harmless. Real API swap: prune on successful full fetch. |
| Persistence across launches | `ModelConfiguration(isStoredInMemoryOnly: false)` in the app; `true` in previews and tests. |
| Write ordering | `LocalStore` is a single actor, so writes are serialized; `setReviewed` is upsert by id. |

### Persistence choice

| Option | Verdict |
|---|---|
| **SwiftData (chosen)** | Template already wires it; iOS 27 target removes all version risk; `@ModelActor` gives off-main-actor writes with a serialized queue; two tiny entities fit it well; trivially in-memory for tests. Brief explicitly lists it. |
| Core Data | Equivalent capability, more boilerplate, no advantage here. |
| `UserDefaults` / JSON file in Application Support | Genuinely sufficient for a set of reviewed ids, but added transactions with dates/decimals are record data; hand-rolling atomic writes, migration and concurrency is more code than using SwiftData. Fine fallback, rejected for the primary path. |
| Mutating the fixture in memory only | Fails "persists across launches". |

Constraint to honor: `@Model` classes are not `Sendable` and are not main-actor-safe across contexts. They never leave `LocalStore`; it maps to/from the `Sendable` domain structs at its boundary. SwiftData `Decimal` is supported as a stored property.

Fixture source vs "real" service: the mock mode is `TransactionRepository(source: FixtureTransactionSource(), store: LocalStore)`. Swapping to a real API replaces only the `source` (section 11).

## 7. Add-transaction: validation location and flow

**Validation lives in a pure `TransactionValidator`** (Domain), called by `AddTransactionViewModel`. Not in the view, not only in the service.

```swift
nonisolated struct TransactionDraft { var title = ""; var amountText = ""; var isExpense = true
                                      var category: TransactionCategory = .other; var date = Date(); var note = "" }
nonisolated enum TransactionValidationError: Hashable, Sendable {
    case titleEmpty, titleTooLong, amountInvalid, amountNotPositive, amountTooLarge, dateInFuture
}
nonisolated enum TransactionValidator {
    static func validate(_ d: TransactionDraft, now: Date, locale: Locale) -> Result<NewTransaction, [TransactionValidationError]>
}
```

Rules: title trimmed, 1...60 chars; amount parsed with the user's `Locale` (`Decimal(string:locale:)`), > 0, <= 1,000,000, max 2 fraction digits; date not after `now`; category required (default `.other`). `now` and `locale` are injected so tests are deterministic.

Flow:
1. View binds fields to `viewModel.draft` (`@Bindable`). Per-field errors shown only after the field was touched or submit was attempted (`viewModel.visibleErrors`), so the form does not shout on open.
2. `canSubmit` is derived from `TransactionValidator.validate(...)` and `!isSubmitting`.
3. `submit()`: validate -> set `isSubmitting` -> `try await service.addTransaction(newTx)` -> on success set `didSave = true` (view dismisses via `.onChange`/`dismiss`; parent lists refresh) -> on failure set `submitError` and keep the form data.
4. The service performs only integrity checks (non-empty id, finite amount) and throws `.validation` as a defense; it does not duplicate UX rules.

After a successful add, other screens must reflect it. Mechanism: see refresh semantics (section 10), not callbacks between view models.

## 8. Dependency injection

- **Composition root** is the App struct. It builds the `ModelContainer`, `LocalStore(modelContainer:)`, `TransactionRepository`, and an `AppEnvironment`.
- `AppEnvironment` holds `service: any TransactionService` and exposes `makeDashboardViewModel()` etc. It is put in the SwiftUI environment with `.environment(appEnvironment)` (it is `@Observable`/plain class, key by type).
- **View models take the service via initializer**, never read the environment themselves. Screen root views create their model once: `@State private var viewModel: TransactionListViewModel` initialized in `init(service:)` or via the environment factory.

```swift
struct TransactionListScreen: View {
    @State private var viewModel: TransactionListViewModel
    init(service: any TransactionService) { _viewModel = State(initialValue: .init(service: service)) }
}
```

Environment is used only for the stable app-wide dependency; no singletons, no global `shared`. Previews and tests pass `MockTransactionService` or an in-memory repository.

## 9. Derived data: where it is computed

| Derived value | Computed in | Why |
|---|---|---|
| Balance, month spent/income, unreviewed count (`AccountSummary`) | `AccountSummaryCalculator.make(from:[Transaction], now:, calendar:)` pure function in Domain | testable, shared by Dashboard |
| Spending per category vs budget (`[CategorySpending]`) | `BudgetCalculator.spending(for:[Transaction], budget:, period:)` | shared by Dashboard summary and Budget screen |
| Recent transactions (first N) | Dashboard view model, `transactions.prefix(5)` over the sorted snapshot | presentation choice |
| List filtering/search/grouping by day | list view model computed property | presentation logic, still not in view body |
| Currency/date strings | `FormatStyle` in views or small formatter helpers in Shared/UI | pure presentation |

Computation is from the **same fetched `[Transaction]` snapshot**, so Dashboard totals and the Budget screen cannot disagree. The data set is small (hundreds); recompute on state change, no caching needed. Computed in the view model (cheap, synchronous, main actor); revisit with `Task.detached` only if profiling shows cost (section 12).

## 10. Concurrency, main-actor rules, refresh semantics

Rules:
1. View models are `@MainActor @Observable final class` (explicit annotation even though it is the module default, so the intent survives a build-setting change).
2. Domain types, `TransactionService`, repository, fixture source are `nonisolated` + `Sendable`; `LocalStore` is an actor (`@ModelActor`). File decode and SwiftData fetches therefore run off the main actor.
3. UI state is mutated only in view model methods, after the `await` returns, which resumes on the main actor. No `DispatchQueue.main.async`, no `MainActor.run` sprinkled in call sites, no `@unchecked Sendable`.
4. Views trigger async work with `.task { await viewModel.load() }` (auto-cancelled on disappear) and `.refreshable { await viewModel.refresh() }`. Never `Task {}` inside `body`.
5. `.refreshable` must `await` to completion, otherwise the spinner ends early; `refresh()` is `async` and returns when state is updated.
6. Check `Task.isCancelled` / catch `CancellationError` after awaits so a cancelled load does not overwrite state with an error.

`LoadState`:

```swift
enum LoadState<Value> { case idle, loading, loaded(Value), empty, error(UserFacingError) }
```

Owned by each view model as `private(set) var state: LoadState<...>`. `empty` is chosen by the view model when a successful fetch returns no items (so the view never inspects arrays to decide).

| Operation | Semantics |
|---|---|
| Initial `load()` | `idle -> loading -> loaded / empty / error`. Guard against double-trigger if already `loading`. |
| Pull-to-refresh | **Stale-while-revalidate**: keep showing `loaded` data while fetching; do not flip to full-screen `loading`. On failure keep old data and surface a transient error (banner/toast); only if there was no data go to `.error`. |
| Retry from `.error` | calls `load()` (goes through `loading`). |
| After add | Add view model does not touch the list. Parent screens refresh when the add sheet dismisses (`onDismiss` / `didSave`), or via a lightweight `TransactionsChanged` revision counter on `AppEnvironment` (`@Observable var revision: Int`) that each list/dashboard view model observes with `.task(id: revision)`. **Recommendation: revision counter**; one mechanism covers add and review changes from detail across tabs. |
| Mark reviewed | **Optimistic**: flip locally immediately, `await service.setReviewed(...)`, on failure revert and show error. Bump `revision` on success so list/dashboard counts update. |
| Fixture "latency" | `FixtureTransactionSource` accepts an injected `delay` (default ~400 ms in debug app, 0 in tests) so loading and refresh are visible; a launch argument can force error/empty for demos and UI tests. |

## 11. State ownership

| Property wrapper | Used for | Example |
|---|---|---|
| `@State` | Value-local view state **and** ownership of an `@Observable` view model for the screen's lifetime | `@State var viewModel`, `@State var showAddSheet` |
| `@Bindable` | Two-way bindings into an `@Observable` the view does not own | form fields `$viewModel.draft.title` |
| `@Binding` | Child control edits a parent-owned value | reusable `CategoryPicker(selection: $category)` |
| `@Environment` | App-wide stable dependencies and system values | `AppEnvironment`, `dismiss`, `\.locale` |
| `@Observable` class | View models and `AppEnvironment` | all `*ViewModel` |
| `@StateObject` / `ObservableObject` / `@Published` | **Not used**: replaced by `@State` + `@Observable` on the iOS 27 target | - |
| `@Query` | **Not used in views**; only the `LocalStore` talks to SwiftData | - |

Per screen:

| Screen | Owner of state | Local `@State` | Data in | Intents out |
|---|---|---|---|---|
| Dashboard | `DashboardViewModel` (`LoadState<DashboardContent>`: summary, top categories, recent) held in `@State` by `DashboardScreen` | `path` navigation selection if needed | `TransactionService` + `BudgetProviding` | `load`, `refresh` |
| Transactions list | `TransactionListViewModel` (`LoadState<[Transaction]>`, `filter`) | `searchText` bound to VM | service | `load`, `refresh`, `toggleReviewed(id)` |
| Transaction detail | `TransactionDetailViewModel` created per pushed id, seeded with the `Transaction` from the list (no refetch), owns `isReviewed`, `isUpdating`, `error` | none | seeded model + service | `setReviewed` |
| Budget | `BudgetViewModel` (`LoadState<[CategorySpending]>`) | none | `TransactionService` + `BudgetProviding` | `load`, `refresh` |
| Add transaction | `AddTransactionViewModel` (draft, touched fields, `isSubmitting`, `didSave`) created when sheet presents | focus field (`@FocusState`) | service | `submit`, `cancel` |
| Root | `NavigationStack` `path` in `@State` (typed route enum `Route.transaction(id)`) per tab; `AppEnvironment` created by App | selected tab | - | - |

Rules of thumb: state is owned by the lowest view that needs to mutate it and passed down as a value or `@Binding`; the screen-root view creates its view model exactly once (`@State`), child components receive plain values and closures, not view models. Navigation uses value-based `NavigationLink(value:)` + `navigationDestination(for:)`, so detail views are created lazily.

## 12. Test seams and the unit tests

Seams: (1) `TransactionService` and `BudgetProviding` protocols, (2) injected `now`/`Calendar`/`Locale`, (3) `LocalStore` over an in-memory `ModelContainer`, (4) fixture source takes `Data`/URL so tests feed inline JSON, (5) delay is injectable.

`MockTransactionService`: `nonisolated final class`/actor configured with `result: Result<[Transaction], Error>` and call recording.

Tests to write (Swift Testing `@Test` or XCTest; 8 listed, 2+ required, first four are mandatory):

| # | Test | Asserts |
|---|---|---|
| 1 | `TransactionListViewModel` load success | state goes `idle -> loaded`, items sorted newest first, count matches mock |
| 2 | `TransactionListViewModel` load failure | mock throws `.loadFailed` -> `.error` with retryable message; retry with success mock -> `.loaded` |
| 3 | `TransactionListViewModel` empty | mock returns `[]` -> `.empty` (not `.loaded([])`) |
| 4 | `TransactionValidator` | empty title, `"abc"`/`"0"`/`"-5"` amount, future date each produce the right error; valid draft yields `NewTransaction` with negative sign for expense |
| 5 | `TransactionRepository` merge (in-memory SwiftData + inline JSON) | review override applies to fixture txn; added txn appears; both survive recreating the repository on the same container (persistence) |
| 6 | `BudgetCalculator` | per-category totals, ignores income and out-of-period, `progress` over 1.0 when overspent |
| 7 | `AddTransactionViewModel.submit` | invalid -> service not called; valid -> service called once, `didSave == true`; service throws -> form data retained, `submitError` set |
| 8 | Refresh keeps stale data on failure | loaded state remains, error surfaced as transient |

Tests of view models are `@MainActor` (the default isolation makes them so) and use `await vm.load()` directly: no sleeping, no expectations, since `load()` is `async` and returns after state is final.

## 13. Path to a real API, plus pagination, caching, offline

**Swap steps** (no view or view-model changes):
1. Add `RemoteTransactionSource` (URLSession + `Codable` DTOs) implementing the same small internal `TransactionSource` protocol that `FixtureTransactionSource` implements. DTO -> domain mapping lives there.
2. In the composition root choose by build config / launch flag: `TransactionRepository(source: RemoteTransactionSource(baseURL:), store: localStore)`.
3. `addTransaction` / `setReviewed`: send to the API first, then upsert locally; the local overlay becomes a cache plus an outbox (below). Auth tokens and the `URLSession` are injected into the remote source; the protocol is unchanged.
4. Map `URLError`/HTTP status to `TransactionServiceError` inside the source.

**Pagination**: add `fetchTransactions(page: PageRequest) async throws -> Page<Transaction>` (cursor + `nextCursor`) as an additive overload; the list view model keeps `items`, `nextCursor`, `isLoadingMore`, triggers `loadMore()` from `.onAppear` of the last rows, and de-dupes by id. Dashboard keeps asking for page 1 / `limit: 5`. Not built now: 100-ish fixture rows do not justify it, and the protocol shape makes it additive.

**Caching**: SwiftData already is the cache layer once the remote source exists: persist fetched transactions with `updatedAt`, show cached data immediately (`loaded` from cache), then revalidate (stale-while-revalidate, already the refresh semantic). Invalidation by TTL or ETag/`If-Modified-Since`; in-memory memoization is unnecessary at this size.

**Offline**: reads work from the cache (banner "Showing saved data" when the last refresh failed with `URLError.notConnectedToInternet`). Writes go to the local store immediately with a `pendingSync` flag; an outbox processed by the repository on foreground / reachability change (`NWPathMonitor`) with idempotency keys so retries do not duplicate. Review toggles are last-write-wins by `updatedAt`.

**Avoiding off-main-actor UI updates**: UI state is only mutated by `@MainActor` view models; all I/O is behind `nonisolated`/actor types returning `Sendable` values; resuming after `await` lands back on the main actor; no completion-handler callbacks or manual `DispatchQueue`. The compiler enforces this (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; consider `SWIFT_STRICT_CONCURRENCY = complete` so violations surface as diagnostics).

## 14. Replace/keep checklist

| Item | Action |
|---|---|
| `Item.swift` | delete |
| `ContentView.swift` | delete; replaced by `App/RootView.swift` |
| `FinanceAppWithClaudeApp.swift` | rewrite: `Schema([PersistedTransaction.self, ReviewRecord.self])`, build repository + `AppEnvironment`, in-memory container when launched for UI tests |
| `Assets.xcassets` | keep; add category colors if used |
| New resource `transactions.json` | add to app target bundle (~25 transactions across 6-7 categories, mixed reviewed, one month of data, plus a `budgets` block) |
