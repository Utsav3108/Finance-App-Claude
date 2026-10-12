//
//  Item.swift
//  FinanceAppWithClaude
//
//  Created by Utsav Hitendrabhai Pandya on 12/10/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
