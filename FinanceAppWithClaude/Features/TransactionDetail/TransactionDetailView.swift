import SwiftUI

struct TransactionDetailView: View {
    let transactionService: any TransactionService
    let onChanged: () -> Void
    @State private var viewModel: TransactionDetailViewModel
    /// The state the failed action was trying to reach, so Retry repeats exactly that.
    @State private var failedTarget: Bool?

    init(transaction: Transaction, transactionService: any TransactionService, onChanged: @escaping () -> Void) {
        self.transactionService = transactionService
        self.onChanged = onChanged
        _viewModel = State(initialValue: TransactionDetailViewModel(transaction: transaction, transactionService: transactionService))
    }

    private var transaction: Transaction { viewModel.transaction }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                hero
                statusSection
                detailsCard
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xl)
        }
        .background(AppColor.surface)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: AppSpacing.sm) {
            CategoryIcon(category: transaction.category, size: .large)
            Text(transaction.title)
                .font(AppFont.titleScreen)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            AmountText(amount: transaction.amount, currencyCode: transaction.currencyCode, style: .hero)
                .multilineTextAlignment(.center)
            Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: Review status + action

    private var statusSection: some View {
        VStack(spacing: AppSpacing.md) {
            ReviewedStatusBadge(isReviewed: viewModel.isReviewed, style: .full)
            PrimaryButton(viewModel.isReviewed ? "Mark as unreviewed" : "Mark as reviewed",
                          isLoading: viewModel.isUpdating) {
                perform(target: !viewModel.isReviewed)
            }
            if let error = viewModel.error {
                errorBanner(error)
            }
        }
    }

    private func errorBanner(_ error: UserFacingError) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Label(error.message, systemImage: "exclamationmark.triangle.fill")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.expense)
                .multilineTextAlignment(.center)
            if error.isRetryable, let target = failedTarget {
                Button("Try again") { perform(target: target) }
                    .font(AppFont.chipLabel)
                    .foregroundStyle(AppColor.accentBrandStrong)
                    .frame(minHeight: AppSize.minTapTarget)
                    .disabled(viewModel.isUpdating)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private func perform(target: Bool) {
        Task {
            let ok = await viewModel.setReviewed(target)
            if ok {
                failedTarget = nil
                onChanged()
                AccessibilityNotification.Announcement(target ? "Marked as reviewed" : "Marked as unreviewed").post()
            } else {
                failedTarget = target
                let message = viewModel.error?.message ?? "Couldn't update. Please try again."
                AccessibilityNotification.Announcement("Update failed. \(message)").post()
            }
        }
    }

    // MARK: Details list

    private var detailsCard: some View {
        VStack(spacing: 0) {
            DetailRow(label: "Category") { CategoryBadge(category: transaction.category) }
            divider
            DetailRow(label: "Date", value: transaction.date.formatted(date: .long, time: .omitted))
            divider
            DetailRow(label: "Time", value: transaction.date.formatted(date: .omitted, time: .shortened))
            divider
            DetailRow(label: "Type", value: transaction.isIncome ? "Income" : "Expense")
            if let note = transaction.note, !note.isEmpty {
                divider
                DetailRow(label: "Note", value: note)
            }
            divider
            DetailRow(label: "Status") { ReviewedStatusBadge(isReviewed: viewModel.isReviewed, style: .full) }
        }
        .padding(.horizontal, AppSpacing.md)
        .background(AppColor.fillSecondary, in: RoundedRectangle(cornerRadius: AppRadius.card))
    }

    private var divider: some View {
        Rectangle().fill(AppColor.borderPrimary).frame(height: 1)
    }
}

/// Key/value row. Label above value at accessibility sizes, side by side otherwise.
private struct DetailRow<Value: View>: View {
    let label: String
    @ViewBuilder let value: () -> Value
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: AppSpacing.xxs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: AppSpacing.sm))
        layout {
            Text(label)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            if !typeSize.isAccessibilitySize { Spacer(minLength: AppSpacing.sm) }
            value()
        }
        .multilineTextAlignment(typeSize.isAccessibilitySize ? .leading : .trailing)
        .padding(.vertical, AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private extension DetailRow where Value == Text {
    init(label: String, value: String) {
        self.label = label
        self.value = {
            Text(value)
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
        }
    }
}

#if DEBUG
#Preview("Unreviewed") {
    let env = AppEnvironment.preview()
    NavigationStack {
        TransactionDetailView(transaction: PreviewData.transactions[0],
                              transactionService: env.transactionService, onChanged: {})
    }
    .environment(env)
}

#Preview("Reviewed, AX size") {
    let env = AppEnvironment.preview()
    NavigationStack {
        TransactionDetailView(transaction: PreviewData.transactions[0].with(isReviewed: true),
                              transactionService: env.transactionService, onChanged: {})
    }
    .environment(env)
    .dynamicTypeSize(.accessibility3)
}
#endif
