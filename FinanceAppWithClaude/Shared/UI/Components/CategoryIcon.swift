import SwiftUI

struct CategoryIcon: View {
    enum Size {
        case small, regular, large, hero
        var points: CGFloat {
            switch self {
            case .small: 32
            case .regular: 40
            case .large: 64
            case .hero: 80
            }
        }
    }

    let category: TransactionCategory
    let size: Size
    /// Set true when standalone (VoiceOver reads the category name); rows hide it.
    var isAccessibilityElement = false

    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = 40

    init(category: TransactionCategory, size: Size = .regular, isAccessibilityElement: Bool = false) {
        self.category = category
        self.size = size
        self.isAccessibilityElement = isAccessibilityElement
        _diameter = ScaledMetric(wrappedValue: size.points, relativeTo: .body)
    }

    var body: some View {
        Image(systemName: category.systemImage)
            .font(.system(size: diameter * 0.45, weight: .regular))
            .foregroundStyle(category.tint)
            .frame(width: diameter, height: diameter)
            .background(AppColor.fillPrimary, in: Circle())
            .overlay(Circle().strokeBorder(AppColor.borderPrimary, lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityHidden(!isAccessibilityElement)
            .accessibilityLabel(category.displayName)
    }
}

#Preview("CategoryIcon") {
    VStack(spacing: 16) {
        ForEach(TransactionCategory.allCases) { c in
            HStack {
                CategoryIcon(category: c, size: .small)
                CategoryIcon(category: c, size: .regular)
                CategoryIcon(category: c, size: .large)
                Text(c.displayName).font(AppFont.rowTitle)
            }
        }
    }
    .padding()
    .background(AppColor.surface)
}
