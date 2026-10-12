import SwiftUI

/// PLACEHOLDER: replaced by the Add transaction feature agent.
/// RootView presents this inside its own NavigationStack in a sheet.
struct AddTransactionView: View {
    let onSaved: (Transaction) -> Void
    let onCancel: () -> Void
    @State private var viewModel: AddTransactionViewModel

    init(transactionService: any TransactionService,
         onSaved: @escaping (Transaction) -> Void,
         onCancel: @escaping () -> Void) {
        self.onSaved = onSaved
        self.onCancel = onCancel
        _viewModel = State(initialValue: AddTransactionViewModel(transactionService: transactionService))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            TextField("Merchant", text: $viewModel.draft.title)
            TextField("Amount", text: $viewModel.draft.amountText).keyboardType(.decimalPad)
            Picker("Type", selection: $viewModel.draft.isExpense) {
                Text("Expense").tag(true)
                Text("Income").tag(false)
            }
            .pickerStyle(.segmented)
            if let error = viewModel.submitError {
                Text(error.message).foregroundStyle(AppColor.expense)
            }
        }
        .navigationTitle("New transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await viewModel.submit()
                        if let saved = viewModel.savedTransaction { onSaved(saved) }
                    }
                }
                .disabled(!viewModel.canSubmit)
            }
        }
    }
}

#if DEBUG
#Preview {
    let env = AppEnvironment.preview()
    NavigationStack {
        AddTransactionView(transactionService: env.transactionService, onSaved: { _ in }, onCancel: {})
    }
}
#endif
