import SwiftUI

/// Typography seam. System font (SF Pro) via text styles so Dynamic Type works everywhere.
/// Figma reference sizes are in doc 03 section 1.2.
enum AppFont {
    static let amountHero = Font.largeTitle.weight(.regular)
    static let amountCard = Font.title2.weight(.regular)
    static let titleScreen = Font.headline.weight(.medium)
    static let rowTitle = Font.subheadline.weight(.medium)
    static let chipLabel = Font.footnote.weight(.medium)
    static let caption = Font.footnote
}
