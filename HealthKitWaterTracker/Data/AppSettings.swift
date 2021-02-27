//
//  AppSettings.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/23/21.
//

import Foundation

@objc protocol SettingsTracking {
    @objc func healthIntegrationIsEnabledChanged()
    @objc func blueColorThemeIsEnabledChanged()
}

extension SettingsTracking {
    func registerForhealthIntegrationIsEnabledChanges() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(healthIntegrationIsEnabledChanged),
                                               name: .healthIntegrationIsEnabledChanged,
                                               object: nil)
    }
    
    func registerForBlueColorThemeIsEnabledChanges() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(blueColorThemeIsEnabledChanged),
                                               name: .blueColorThemeIsEnabledChanged,
                                               object: nil)
    }
}

class AppSettings {
    static let shared = AppSettings()
    private init() {}
    
    // MARK: - Public Properties
    
    var healthIntegrationIsEnabled: Bool {
        get {
            value(for: healthIntegrationIsEnabledKey) ?? false // defaults to `false`
        }
        set {
            guard newValue != healthIntegrationIsEnabled else { return }
            updateDefaults(for: healthIntegrationIsEnabledKey, value: newValue)
            sendNotification(.healthIntegrationIsEnabledChanged)
        }
    }
    
    var blueColorThemeIsEnabled: Bool {
        get {
            value(for: blueColorThemeIsEnabledKey) ?? false // defaults to `false`
        }
        set {
            guard newValue != blueColorThemeIsEnabled else { return }
            updateDefaults(for: blueColorThemeIsEnabledKey, value: newValue)
            sendNotification(.blueColorThemeIsEnabledChanged)
        }
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let healthIntegrationIsEnabledKey = "healthIntegrationIsEnabledKey"
    private let blueColorThemeIsEnabledKey = "blueColorThemeIsEnabledKey"
}


// MARK: - Private Methods

extension AppSettings {
    
    private func updateDefaults(for key: String, value: Any) {
        userDefaults.set(value, forKey: key)
    }
    
    private func value<T>(for key: String) -> T? {
        userDefaults.value(forKey: key) as? T
    }
    
    private func sendNotification(_ notificationName: Notification.Name) {
        let notification = Notification(name: notificationName)
        NotificationQueue.default.enqueue(notification,
                                          postingStyle: .asap,
                                          coalesceMask: .onName,
                                          forModes: [.common])
    }
}


extension Notification.Name {
    static let healthIntegrationIsEnabledChanged = Notification.Name("healthIntegrationIsEnabledChanged")
    static let blueColorThemeIsEnabledChanged = Notification.Name("blueColorThemeIsEnabledChanged")
}
