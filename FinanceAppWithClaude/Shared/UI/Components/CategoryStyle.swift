import SwiftUI

/// Presentation data for `TransactionCategory` (kept out of Domain).
extension TransactionCategory {
    var displayName: String {
        switch self {
        case .groceries: "Groceries"
        case .dining: "Dining"
        case .transport: "Transport"
        case .shopping: "Shopping"
        case .bills: "Bills"
        case .entertainment: "Entertainment"
        case .health: "Health"
        case .income: "Income"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .groceries: "cart"
        case .dining: "fork.knife"
        case .transport: "car"
        case .shopping: "bag"
        case .bills: "doc.text"
        case .entertainment: "ticket"
        case .health: "cross.case"
        case .income: "banknote"
        case .other: "circle.grid.2x2"
        }
    }

    var tint: Color {
        switch self {
        case .groceries: AppColor.accentBrand
        case .dining: AppColor.accentWarning
        case .transport: AppColor.accentSanstone
        case .shopping: AppColor.accentMarigold
        case .bills: AppColor.accentRuby
        case .entertainment: AppColor.accentWarning
        case .health: AppColor.accentBrand
        case .income: AppColor.income
        case .other: AppColor.iconSecondary
        }
    }
}
