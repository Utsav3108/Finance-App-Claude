import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading: Bool
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 52

    init(_ title: String, systemImage: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView().tint(AppColor.iconInverse)
                } else if let systemImage {
                    Image(systemName: systemImage).accessibilityHidden(true)
                }
                Text(title).font(AppFont.titleScreen)
            }
            .foregroundStyle(AppColor.iconInverse)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .padding(.horizontal, AppSpacing.md)
            .background(AppColor.accentBrandStrong.opacity(isEnabled ? 1 : 0.4), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "\(title), in progress" : title)
    }
}

#Preview("PrimaryButton") {
    VStack(spacing: 12) {
        PrimaryButton("Save") {}
        PrimaryButton("Retry", systemImage: "arrow.clockwise") {}
        PrimaryButton("Saving", isLoading: true) {}
        PrimaryButton("Disabled") {}.disabled(true)
    }
    .padding()
    .background(AppColor.surface)
}
