import SwiftUI

/// PLACEHOLDER: replaced by the Transaction detail feature agent.
struct TransactionDetailView: View {
    let transactionService: any TransactionService
    let onChanged: () -> Void
    @State private var viewModel: TransactionDetailViewModel

    init(transaction: Transaction, transactionService: any TransactionService, onChanged: @escaping () -> Void) {
        self.transactionService = transactionService
        self.onChanged = onChanged
        _viewModel = State(initialValue: TransactionDetailViewModel(transaction: transaction, transactionService: transactionService))
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            CategoryIcon(category: viewModel.transaction.category, size: .large, isAccessibilityElement: true)
            Text(viewModel.transaction.title).font(AppFont.titleScreen)
            AmountText(amount: viewModel.transaction.amount, currencyCode: viewModel.transaction.currencyCode, style: .hero)
            ReviewedStatusBadge(isReviewed: viewModel.transaction.isReviewed)
            PrimaryButton(viewModel.transaction.isReviewed ? "Mark as not reviewed" : "Mark as reviewed",
                          isLoading: viewModel.isUpdating) {
                Task {
                    if await viewModel.setReviewed(!viewModel.transaction.isReviewed) { onChanged() }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            if let error = viewModel.error {
                Text(error.message).font(AppFont.caption).foregroundStyle(AppColor.expense)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    let env = AppEnvironment.preview()
    NavigationStack {
        TransactionDetailView(transaction: PreviewData.transactions[0],
                              transactionService: env.transactionService, onChanged: {})
    }
}
#endif
