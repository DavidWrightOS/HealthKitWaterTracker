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
    
    // MARK: - UI Components
    
    private let appleHealthIntegrationLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.text = "Apple Health Integration"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let appleHealthIntegrationSwitch: UISwitch = {
        let healthSwitch = UISwitch()
        healthSwitch.translatesAutoresizingMaskIntoConstraints = false
        healthSwitch.addTarget(self, action: #selector(appleHealthIntegrationSwitchDidChange), for: .valueChanged)
        return healthSwitch
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .caption1)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViews()
        appleHealthIntegrationSwitch.isOn = appSettings.healthIntegrationIsEnabled
        
        title = tabBarItem.title
        navigationController?.navigationBar.prefersLargeTitles = true
        
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
        
        healthStore.getRequestStatusForAuthorization(toShare: shareTypes, read: readTypes) { (authorizationRequestStatus, error) in
            
            var status: String = ""
            
            if let error = error {
                status = "HealthKit Authorization Error: \(error.localizedDescription)"
                self.turnOffAppleHealthIntegration()
                
            } else {
                switch authorizationRequestStatus {
                case .shouldRequest:
                    self.hasRequestedHealthData = false
                    status = "The application has not yet requested authorization for all of the specified data types."
                    if self.appSettings.healthIntegrationIsEnabled {
                        self.requestHealthAuthorization()
                    }
                case .unknown:
                    status = "The authorization request status could not be determined because an error occurred."
                case .unnecessary:
                    self.hasRequestedHealthData = true
                    status = "The application has already requested authorization for the specified data types. "
                    status += self.createAuthorizationStatusDescription(for: self.shareTypes)
                default:
                    break
                }
            }
            
            print(status)
            
            // Results come back on a background thread. Dispatch UI updates to the main thread.
            DispatchQueue.main.async {
                self.descriptionLabel.text = status
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
        
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
            
            var status: String = ""
            
            if let error = error {
                status = "HealthKit Authorization Error: \(error.localizedDescription)"
                self.turnOffAppleHealthIntegration()
                
            } else {
                if success {
                    if self.hasRequestedHealthData {
                        status = "You've already requested access to health data. "
                    } else {
                        status = "HealthKit authorization request was successful! "
                    }
                    
                    status += self.createAuthorizationStatusDescription(for: self.shareTypes)
                    
                    self.hasRequestedHealthData = true
                    
                } else {
                    status = "HealthKit authorization did not complete successfully."
                    self.turnOffAppleHealthIntegration()
                }
            }
            
            print(status)
            
            // Results come back on a background thread. Dispatch UI updates to the main thread.
            DispatchQueue.main.async {
                self.descriptionLabel.text = status
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
            self.appleHealthIntegrationSwitch.isOn = false
            self.appSettings.healthIntegrationIsEnabled = false
        }
    }
}


// MARK: - Configure Views

extension SettingsViewController {
    
    private func configureViews() {
        
        configureColorScheme()
        
        let inset: CGFloat = 20
        let padding: CGFloat = 12
        
        let imageView: UIImageView = {
            let imageView = UIImageView()
            
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
            imageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            let image = UIImage(named: "Icon - Apple Health")
            imageView.image = image
            
            imageView.layer.borderWidth = 0.4
            imageView.layer.borderColor = UIColor.separator.cgColor
            imageView.layer.cornerRadius = 7
            imageView.layer.cornerCurve = .continuous
            imageView.layer.masksToBounds = true
            
            return imageView
        }()
        
        let containerView: UIView = {
            let containerView = UIView()
            containerView.backgroundColor = .secondaryBackgroundColor
            containerView.translatesAutoresizingMaskIntoConstraints = false
            
            appleHealthIntegrationLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            appleHealthIntegrationSwitch.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            
            let stackView = UIStackView(arrangedSubviews: [imageView, appleHealthIntegrationLabel, appleHealthIntegrationSwitch])
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.distribution = .fill
            stackView.spacing = padding
            stackView.translatesAutoresizingMaskIntoConstraints = false
            
            containerView.addSubview(stackView)
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8).isActive = true
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8).isActive = true
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: inset).isActive = true
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -inset).isActive = true
            
            return containerView
        }()
        
        func makeSeparator() -> UIView {
            let separator = UIView()
            separator.backgroundColor = .separator
            separator.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(separator)
            
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            separator.heightAnchor.constraint(equalToConstant: 0.3).isActive = true
            
            return separator
        }
        
        let separator1 = makeSeparator()
        let separator2 = makeSeparator()
        
        view.addSubview(containerView)
        view.addSubview(descriptionLabel)
        
        separator1.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60).isActive = true
        
        containerView.topAnchor.constraint(equalTo: separator1.bottomAnchor).isActive = true
        containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        
        separator2.topAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        
        descriptionLabel.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: padding).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: inset).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -inset).isActive = true
    }
    
    private func configureColorScheme() {
        view.backgroundColor = .backgroundColor
        
        navigationController?.navigationBar.tintColor = .actionColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.textColor]
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        
        appleHealthIntegrationSwitch.onTintColor = .switchOnTintColor
        appleHealthIntegrationLabel.textColor = .textColor
        descriptionLabel.textColor = .detailTextColor
    }
}


// MARK: - Authorization Status Description

extension SettingsViewController {
    
    private func createAuthorizationStatusDescription(for types: Set<HKObjectType>) -> String {
        var dictionary = [HKAuthorizationStatus: Int]()
        
        for type in types {
            let status = healthStore.authorizationStatus(for: type)
            
            if let existingValue = dictionary[status] {
                dictionary[status] = existingValue + 1
            } else {
                dictionary[status] = 1
            }
        }
        
        var descriptionArray: [String] = []
        
        if let numberOfAuthorizedTypes = dictionary[.sharingAuthorized] {
            let format = NSLocalizedString("AUTHORIZED_NUMBER_OF_TYPES", comment: "")
            let formattedString = String(format: format, locale: .current, arguments: [numberOfAuthorizedTypes])
            
            descriptionArray.append(formattedString)
        }
        if let numberOfDeniedTypes = dictionary[.sharingDenied] {
            let format = NSLocalizedString("DENIED_NUMBER_OF_TYPES", comment: "")
            let formattedString = String(format: format, locale: .current, arguments: [numberOfDeniedTypes])
            
            descriptionArray.append(formattedString)
        }
        if let numberOfUndeterminedTypes = dictionary[.notDetermined] {
            let format = NSLocalizedString("UNDETERMINED_NUMBER_OF_TYPES", comment: "")
            let formattedString = String(format: format, locale: .current, arguments: [numberOfUndeterminedTypes])
            
            descriptionArray.append(formattedString)
        }
        
        // Format the sentence for grammar if there are multiple clauses.
        if let lastDescription = descriptionArray.last, descriptionArray.count > 1 {
            descriptionArray[descriptionArray.count - 1] = "and \(lastDescription)"
        }
        
        let description = "Sharing is " + descriptionArray.joined(separator: ", ") + "."
        
        return description
    }
}
