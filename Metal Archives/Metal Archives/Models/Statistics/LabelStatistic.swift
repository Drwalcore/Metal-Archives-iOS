//
//  LabelStatistic.swift
//  Metal Archives
//
//  Created by Thanh-Nhon Nguyen on 27/02/2019.
//  Copyright © 2019 Thanh-Nhon Nguyen. All rights reserved.
//

import Foundation
import UIKit

final class LabelStatistic {
    typealias LabelStatisticStatus = (description: String, count: Int, color: UIColor)
    
    let total: Int
    let active: LabelStatisticStatus
    let closed: LabelStatisticStatus
    let changedName: LabelStatisticStatus
    let unknown: LabelStatisticStatus
    
    init(total: Int, active: Int, closed: Int, changedName: Int, unknown: Int) {
        self.total = total
        self.active = ("Active", active, Settings.currentTheme.activeStatusColor)
        self.closed = ("Closed", closed, Settings.currentTheme.closedStatusColor)
        self.changedName = ("Changed name", changedName, Settings.currentTheme.changedNameStatusColor)
        self.unknown = ("Unknown", unknown, Settings.currentTheme.unknownStatusColor)
    }
}
