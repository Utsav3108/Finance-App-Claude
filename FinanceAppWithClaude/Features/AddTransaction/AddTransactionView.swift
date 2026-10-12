import SwiftUI

/// RootView presents this inside its own NavigationStack in a `.large` sheet.
struct AddTransactionView: View {
    let onSaved: (Transaction) -> Void
    let onCancel: () -> Void
    @State private var viewModel: AddTransactionViewModel
    @FocusState private var focus: AddTransactionField?

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
            typeSection(viewModel: $viewModel.draft.isExpense)

            row {
                FormField(label: "Amount", error: viewModel.visibleError(for: .amount),
                          helper: "Up to 2 decimal places") {
                    HStack(spacing: AppSpacing.xs) {
                        Text(currencySymbol).foregroundStyle(AppColor.textSecondary)
                            .accessibilityHidden(true)
                        TextField("0.00", text: $viewModel.draft.amountText)
                            .keyboardType(.decimalPad)
                            .focused($focus, equals: .amount)
                    }
                    .font(AppFont.amountHero)
                }
            }

            row {
                FormField(label: "Merchant or title", error: viewModel.visibleError(for: .title)) {
                    TextField("e.g. Whole Foods", text: $viewModel.draft.title)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($focus, equals: .title)
                }
            }

            row {
                FormField(label: "Category",
                          helper: viewModel.draft.isExpense ? nil : "Income is saved in the Income category") {
                    categoryControl(selection: $viewModel.draft.category)
                }
            }

            row {
                FormField(label: "Date", error: viewModel.visibleError(for: .date)) {
                    DatePicker("Date", selection: $viewModel.draft.date,
                               in: ...viewModel.latestDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            row {
                FormField(label: "Note (optional)") {
                    TextField("Add a note", text: $viewModel.draft.note, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(.vertical, AppSpacing.xs)
                        .focused($focus, equals: .note)
                }
            }

            if let error = viewModel.submitError {
                row {
                    Label {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(error.title).font(AppFont.rowTitle)
                            Text(error.message).font(AppFont.caption)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .foregroundStyle(AppColor.expense)
                    .accessibilityElement(children: .combine)
                }
            }

            row {
                PrimaryButton(viewModel.submitError?.isRetryable == true ? "Try again" : "Save",
                              isLoading: viewModel.isSubmitting) {
                    save()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColor.surface)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("New transaction")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.isSubmitting)
        .disabled(viewModel.isSubmitting)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel).disabled(viewModel.isSubmitting)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.disabled(viewModel.isSubmitting)
            }
        }
        .onChange(of: focus) { old, _ in
            if let old { viewModel.touch(old) }
        }
        .onChange(of: viewModel.draft.date) { _, _ in viewModel.touch(.date) }
        .onChange(of: viewModel.submitError) { _, error in
            if let error { announce("Couldn't save. \(error.message)") }
        }
    }

    // MARK: Pieces

    private func typeSection(viewModel isExpense: Binding<Bool>) -> some View {
        row {
            Picker("Type", selection: isExpense) {
                Text("Expense").tag(true)
                Text("Income").tag(false)
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private func categoryControl(selection: Binding<TransactionCategory>) -> some View {
        if viewModel.draft.isExpense {
            Menu {
                Picker("Category", selection: selection) {
                    ForEach(viewModel.selectableCategories) { category in
                        Label(category.displayName, systemImage: category.systemImage).tag(category)
                    }
                }
            } label: {
                HStack {
                    CategoryBadge(category: viewModel.effectiveCategory, isSelected: true)
                    Spacer(minLength: AppSpacing.xs)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.iconSecondary)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .accessibilityValue(viewModel.effectiveCategory.displayName)
            .accessibilityHint("Opens a menu of categories")
        } else {
            HStack {
                CategoryBadge(category: .income)
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityValue(TransactionCategory.income.displayName)
        }
    }

    private func row<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md,
                                      bottom: AppSpacing.xs, trailing: AppSpacing.md))
    }

    private var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }

    // MARK: Actions

    private func save() {
        focus = nil
        Task {
            if let saved = await viewModel.submit() {
                announce("Transaction saved")
                onSaved(saved)
            } else if !viewModel.isValid {
                if let first = viewModel.firstInvalidField, first == .amount || first == .title || first == .note {
                    focus = first
                }
                let messages = viewModel.visibleErrorMessages
                announce(messages.isEmpty ? "Please check the form" : messages.joined(separator: " "))
            }
        }
    }

    private func announce(_ text: String) {
        AccessibilityNotification.Announcement(text).post()
    }
}

#if DEBUG
#Preview("Add transaction") {
    let env = AppEnvironment.preview()
    NavigationStack {
        AddTransactionView(transactionService: env.transactionService, onSaved: { _ in }, onCancel: {})
    }
}

#Preview("Large type", traits: .sizeThatFitsLayout) {
    let env = AppEnvironment.preview()
    NavigationStack {
        AddTransactionView(transactionService: env.transactionService, onSaved: { _ in }, onCancel: {})
    }
    .environment(\.dynamicTypeSize, .accessibility2)
}
#endif
