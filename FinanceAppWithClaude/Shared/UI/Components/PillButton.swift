import SwiftUI

struct PillButton: View {
    var title: String?
    var systemImage: String?
    var accessibilityLabel: String?
    let action: () -> Void

    init(title: String? = nil, systemImage: String? = nil, accessibilityLabel: String? = nil,
         action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xxs) {
                if let systemImage {
                    Image(systemName: systemImage).accessibilityHidden(true)
                }
                if let title {
                    Text(title)
                }
            }
            .font(AppFont.chipLabel)
            .foregroundStyle(AppColor.textPrimary)
            .padding(.horizontal, title == nil ? AppSpacing.xs : AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColor.fillSecondary, in: Capsule())
            // Visual stays 32pt; hit area grows to 44pt.
            .frame(minWidth: AppSize.minTapTarget, minHeight: AppSize.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? title ?? "")
    }
}

#Preview("PillButton") {
    HStack {
        PillButton(title: "See all") {}
        PillButton(title: "October", systemImage: "chevron.down") {}
        PillButton(systemImage: "pencil", accessibilityLabel: "Edit budget") {}
    }
    .padding()
    .background(AppColor.surface)
}
