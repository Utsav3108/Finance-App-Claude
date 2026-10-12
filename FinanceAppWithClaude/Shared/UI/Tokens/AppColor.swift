import SwiftUI

/// Semantic colors, backed by the asset catalog (Any/Dark per set). Names mirror Figma tokens.
enum AppColor {
    static let surface = Color("Surface")
    static let fillPrimary = Color("FillPrimary")
    static let fillSecondary = Color("FillSecondary")
    static let borderPrimary = Color("BorderPrimary")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")
    /// Use for all caption-sized text (4.5:1 on surface).
    static let textTertiaryAccessible = Color("TextTertiaryAccessible")
    static let iconSecondary = Color("IconSecondary")
    static let iconInverse = Color("IconInverse")
    static let expense = Color("Expense")
    static let income = Color("Income")
    static let accentBrand = Color("AccentBrand")
    /// Darker brand fill so white text on it reaches 4.5:1 (PrimaryButton).
    static let accentBrandStrong = Color("AccentBrandStrong")
    static let accentWarning = Color("AccentWarning")
    static let accentMarigold = Color("AccentMarigold")
    static let accentRuby = Color("AccentRuby")
    static let accentSanstone = Color("AccentSanstone")
}
