import SwiftUI

struct TransactionListView: View {
    let transactionService: any TransactionService
    let onSelectTransaction: (Transaction) -> Void
    let onAdd: () -> Void

    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: TransactionListViewModel

    init(
        transactionService: any TransactionService,
        onSelectTransaction: @escaping (Transaction) -> Void,
        onAdd: @escaping () -> Void
    ) {
        self.transactionService = transactionService
        self.onSelectTransaction = onSelectTransaction
        self.onAdd = onAdd
        _viewModel = State(initialValue: TransactionListViewModel(transactionService: transactionService))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        StateContainer(
            state: viewModel.state,
            empty: EmptyStateConfig(title: "No transactions", message: "Add your first transaction to see it here.",
                                    actionTitle: "Add transaction", action: onAdd),
            retry: { Task { await viewModel.load() } },
            placeholder: { TransactionListPlaceholder() }
        ) { _ in
            if viewModel.sections.isEmpty {
                noResults
            } else {
                list
            }
        }
        .background(AppColor.surface)
        .navigationTitle("Transactions")
        .searchable(text: $viewModel.searchText, prompt: "Search merchant or category")
        .toolbar { filterMenu }
        .refreshable { await viewModel.load() }
        .task(id: environment.dataVersion) { await viewModel.load() }
    }

    private var list: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(Array(zip(section.transactions, section.rows)), id: \.0.id) { transaction, row in
                        Button { onSelectTransaction(transaction) } label: { TransactionRow(model: row) }
                            .buttonStyle(.plain)
                            .listRowBackground(AppColor.surface)
                    }
                } header: {
                    Text(section.title)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textTertiaryAccessible)
                        .textCase(nil)
                        .accessibilityAddTraits(.isHeader)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var noResults: some View {
        ScrollView {
            EmptyStateView(config: EmptyStateConfig(
                systemImage: "magnifyingglass",
                title: "No matching transactions",
                message: "Try a different search or filter.",
                actionTitle: "Clear filters",
                action: { viewModel.clearFilters() }))
                .containerRelativeFrame(.vertical, alignment: .center)
        }
    }

    @ToolbarContentBuilder
    private var filterMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            @Bindable var viewModel = viewModel
            Menu {
                Picker("Filter", selection: $viewModel.filter) {
                    ForEach(TransactionListFilter.allCases) { filter in
                        Label(filter.title, systemImage: filter.systemImage).tag(filter)
                    }
                }
            } label: {
                Image(systemName: viewModel.filter == .all
                      ? "line.3.horizontal.decrease.circle"
                      : "line.3.horizontal.decrease.circle.fill")
            }
            .accessibilityLabel("Filter transactions")
            .accessibilityValue(viewModel.filter.title)
        }
    }
}

/// Skeleton rows shown while the first load is in flight.
private struct TransactionListPlaceholder: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(0..<6, id: \.self) { _ in
                TransactionRow(model: .placeholder)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.md)
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)
    }
}

#if DEBUG
private struct TransactionListPreview: View {
    let behavior: PreviewTransactionService.Behavior
    var body: some View {
        let env = AppEnvironment.preview(behavior: behavior)
        NavigationStack {
            TransactionListView(transactionService: env.transactionService, onSelectTransaction: { _ in }, onAdd: {})
        }
        .environment(env)
    }
}

#Preview("Loaded") { TransactionListPreview(behavior: .loaded) }
#Preview("Empty") { TransactionListPreview(behavior: .empty) }
#Preview("Failing") { TransactionListPreview(behavior: .failing) }
#Preview("Slow") { TransactionListPreview(behavior: .slow) }
#Preview("AX5") { TransactionListPreview(behavior: .loaded).dynamicTypeSize(.accessibility5) }
#endif
