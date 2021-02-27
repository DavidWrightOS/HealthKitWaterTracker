//
//  SettingsViewController.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/22/21.
//

import UIKit
import HealthKit

class SettingsViewController: UIViewController {
    
    // MARK: - Properties
    
    private let healthStore = HealthData.healthStore
    
    /// The HealthKit data types we will request to read.
    private let readTypes = Set(HealthData.readDataTypes)
    /// The HealthKit data types we will request to share and have write access.
    private let shareTypes = Set(HealthData.shareDataTypes)
    
    private var hasRequestedHealthData: Bool = false
    
    private let appSettings = AppSettings.shared
    
    private let settings = [
        // Section 0
        [
            SettingModel(displayName: "Apple Health Integration",
                    getValue: { () in AppSettings.shared.healthIntegrationIsEnabled },
                    setValue: { (newValue: Bool) in AppSettings.shared.healthIntegrationIsEnabled = newValue })
        ],
        // Section 1
        [
            SettingModel(displayName: "Blue Color Theme",
                    getValue: { () in AppSettings.shared.waterColorScheme },
                    setValue: { (newValue: Bool) in AppSettings.shared.waterColorScheme = newValue })
        ]
    ]
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
        tableView.reloadData()
        
        getHealthAuthorizationRequestStatus()
    }
    
    // MARK: - Selectors
    
    @objc private func appleHealthIntegrationSwitchDidChange(sender: UISwitch) {
        appSettings.healthIntegrationIsEnabled = sender.isOn
        
        if sender.isOn {
            requestHealthAuthorization()
        } else {
            print("DEBUG: Disable Apple Health integration..")
        }
    }
    
    // MARK: - Helpers
    
    private func getHealthAuthorizationRequestStatus() {
        print("Checking HealthKit authorization status...")
        
        if !HKHealthStore.isHealthDataAvailable() {
            presentHealthDataNotAvailableError()
            turnOffAppleHealthIntegration()
            return
        }
        
        healthStore.getRequestStatusForAuthorization(toShare: shareTypes, read: readTypes) { authorizationRequestStatus, error in
            if let error = error {
                NSLog("HealthKit Request Status for Authorization Error: \(error.localizedDescription)")
            }
            
            switch authorizationRequestStatus {
            case .shouldRequest:
                self.hasRequestedHealthData = false
                if self.appSettings.healthIntegrationIsEnabled {
                    self.requestHealthAuthorization()
                }
            case .unnecessary:
                self.hasRequestedHealthData = true
            default:
                break
            }
        }
    }
    
    private func requestHealthAuthorization() {
        print("Requesting HealthKit authorization...")
        
        if !HKHealthStore.isHealthDataAvailable() {
            presentHealthDataNotAvailableError()
            turnOffAppleHealthIntegration()
            return
        }
        
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
            if let error = error {
                NSLog("Error requesting HealthKit authorization: \(error.localizedDescription)")
            }
            
            if success {
                self.hasRequestedHealthData = true
            } else {
                self.turnOffAppleHealthIntegration()
            }
        }
    }
    
    private func presentHealthDataNotAvailableError() {
        let title = "Health Data Unavailable"
        let message = "Aw, shucks! We are unable to access health data on this device. Make sure you are using device with HealthKit capabilities."
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .default)
        
        alertController.addAction(action)
        
        present(alertController, animated: true)
    }
    
    private func turnOffAppleHealthIntegration() {
        DispatchQueue.main.async {
            self.appSettings.healthIntegrationIsEnabled = false
            
            guard let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? SettingsCell else { return }
            
            cell.switchControl.setOn(false, animated: true)
        }
    }
}


// MARK: - Configure Views

extension SettingsViewController {
    
    private func setUpViews() {
        title = tabBarItem.title
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.register(SettingsCell.self, forCellReuseIdentifier: SettingsCell.reuseIdentifier)
        tableView.contentInset.top = 8
        
        view.addSubview(tableView)
        
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        configureColorScheme()
    }
}


// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        settings.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        settings[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsCell.reuseIdentifier) as? SettingsCell ?? SettingsCell()
        
        cell.setting = settings[indexPath.section][indexPath.row]
        
        return cell
    }
}


// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "App Integrations".uppercased()
        case 1: return "Appearance".uppercased()
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return "Turn on Apple Health Integration to sync water intake data with other apps."
        default: return nil
        }
    }
}
