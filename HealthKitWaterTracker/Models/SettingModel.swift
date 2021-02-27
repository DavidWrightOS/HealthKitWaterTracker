//
//  SettingModel.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/26/21.
//

import Foundation

class SettingModel {
    var displayName: String?
    private var getValue: (() -> Bool)
    private var setValue: ((Bool) -> Void)
    
    var value: Bool {
        get { getValue() }
        set { setValue(newValue) }
    }
    
    init(displayName: String? = nil, getValue: @escaping (() -> Bool), setValue: @escaping ((Bool) -> Void)) {
        self.displayName = displayName
        self.getValue = getValue
        self.setValue = setValue
    }
}
