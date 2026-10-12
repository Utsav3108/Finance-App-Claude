import SwiftUI

/// PLACEHOLDER: replaced by the Transactions feature agent.
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
        StateContainer(
            state: viewModel.state,
            empty: EmptyStateConfig(title: "No transactions", message: "Add your first transaction.",
                                    actionTitle: "Add transaction", action: onAdd),
            retry: { Task { await viewModel.load() } }
        ) { items in
            List(items) { item in
                Button { onSelectTransaction(item) } label: { TransactionRow(model: TransactionRowModel(item)) }
                    .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
        .navigationTitle("Transactions")
        .task(id: environment.dataVersion) { await viewModel.load() }
    }
}

#if DEBUG
#Preview {
    let env = AppEnvironment.preview()
    NavigationStack {
        TransactionListView(transactionService: env.transactionService, onSelectTransaction: { _ in }, onAdd: {})
    }
    .environment(env)
}
#endif
