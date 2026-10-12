import Foundation

/// Value-based navigation destinations pushed inside a tab's NavigationStack.
enum Route: Hashable {
    case transaction(Transaction)
}

enum AppTab: Hashable, CaseIterable {
    case dashboard, transactions, budget
}
