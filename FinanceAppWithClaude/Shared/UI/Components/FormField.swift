import SwiftUI

/// Label + input + helper/validation text in a `fillSecondary` capsule-ish container.
struct FormField<Content: View>: View {
    let label: String
    var error: String?
    var helper: String?
    @ViewBuilder var content: () -> Content

    init(label: String, error: String? = nil, helper: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.error = error
        self.helper = helper
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(AppFont.chipLabel)
                .foregroundStyle(AppColor.textSecondary)
            content()
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .frame(minHeight: AppSize.minTapTarget)
                .background(AppColor.fillSecondary, in: RoundedRectangle(cornerRadius: AppRadius.card))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.card)
                    .strokeBorder(error == nil ? .clear : AppColor.expense, lineWidth: 1.5))
                .accessibilityLabel(label)
            if let error {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.expense)
            } else if let helper {
                Text(helper)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiaryAccessible)
            }
        }
    }
}

#Preview("FormField") {
    @Previewable @State var text = ""
    return VStack(spacing: AppSpacing.md) {
        FormField(label: "Merchant", helper: "Up to 60 characters") {
            TextField("e.g. Whole Foods", text: $text)
        }
        FormField(label: "Amount", error: "Enter an amount greater than zero") {
            TextField("0.00", text: $text).keyboardType(.decimalPad)
        }
    }
    .padding(AppSpacing.lg)
    .background(AppColor.surface)
}
