import SwiftUI

struct NavIconButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppColor.textPrimary)
                .frame(minWidth: AppSize.minTapTarget, minHeight: AppSize.minTapTarget)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }
}

#Preview("NavIconButton") {
    HStack {
        NavIconButton(systemImage: "plus", label: "Add transaction") {}
        NavIconButton(systemImage: "line.3.horizontal.decrease", label: "Filter transactions") {}
        NavIconButton(systemImage: "xmark", label: "Close") {}
    }
    .background(AppColor.surface)
}
