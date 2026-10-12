import SwiftUI

struct FloatingAddButton: View {
    let action: () -> Void
    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = 64

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppColor.iconInverse)
                .frame(width: min(diameter, 96), height: min(diameter, 96))
                .background(AppColor.accentBrand, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add transaction")
    }
}

#Preview("FloatingAddButton") {
    FloatingAddButton {}
        .padding()
        .background(AppColor.surface)
}
