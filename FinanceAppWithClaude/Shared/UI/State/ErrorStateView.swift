import SwiftUI

struct ErrorStateView: View {
    var title: String
    let message: String
    let isRetryable: Bool
    let retry: () -> Void

    init(title: String = "Something went wrong", message: String, isRetryable: Bool = true,
         retry: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.isRetryable = isRetryable
        self.retry = retry
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(AppColor.accentWarning)
                .accessibilityHidden(true)
            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.titleScreen)
                    .foregroundStyle(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiaryAccessible)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            if isRetryable {
                PrimaryButton("Try again", systemImage: "arrow.clockwise", action: retry)
                    .frame(maxWidth: 280)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
        .onAppear {
            AccessibilityNotification.Announcement("\(title). \(message)").post()
        }
    }
}

#Preview("ErrorStateView") {
    ErrorStateView(message: "Something went wrong while loading your transactions.") {}
        .background(AppColor.surface)
}
