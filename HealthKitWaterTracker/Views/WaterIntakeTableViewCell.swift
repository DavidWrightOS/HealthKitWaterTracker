//
//  WaterIntakeTableViewCell.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/23/21.
//

import UIKit

/// A table view cell with a title and detail value label.
class WaterIntakeTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "WaterIntakeTableViewCellReuseIdentifier"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
