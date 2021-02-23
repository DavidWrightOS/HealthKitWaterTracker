//
//  HealthDataTypeValue.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/23/21.
//

import Foundation

/// A representation of health data to use for `HealthDataTypeTableViewController`.
struct HealthDataTypeValue {
    let startDate: Date
    let endDate: Date
    var value: Double
}
