//
//  WaterIntakeTableViewController.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/22/21.
//

import UIKit
import HealthKit

/// A protocol for a class that manages a HealthKit query.
protocol HealthQueryDataSource: class {
    /// Create and execute a query on a health store. Note: The completion handler returns on a background thread.
    func performQuery(completion: @escaping () -> Void)
}

protocol HealthDataTableViewControllerDelegate: class {
    func didAddNewData(with value: Double)
}

/// A representation of health data related to mobility.
class WaterIntakeTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    let calendar = Calendar.current
    let healthStore = HealthData.healthStore
    
    let quantityType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
    let unit = HKUnit.fluidOunceUS()
    var query: HKStatisticsCollectionQuery?
    
    let dataTypeName = "Water Intake"
    let unitSuffix = "fl oz (US)"
    
    var dataValues: [HealthDataTypeValue] = [] // tableView data source
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }()
    
    // MARK: Initializers

    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForhealthIntegrationIsEnabledChanges()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add Data", style: .plain, target: self, action: #selector(didTapRightBarButtonItem))
        title = tabBarItem.title
        
        tableView.register(WaterIntakeTableViewCell.self, forCellReuseIdentifier: WaterIntakeTableViewCell.reuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = tabBarItem.title
        
        if AppSettings.shared.healthIntegrationIsEnabled {
            requestAuthorizationAndQueryData()
        } else {
            print("Warning: Unable to configure query. The user has disabled Apple Health integration.")
            dataValues.removeAll()
            reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopQuery()
    }
    
    // MARK: - HKStatisticsCollectionQuery
    
    func requestAuthorizationAndQueryData() {
        print("Setting up HealthKit query...")
        
        let dataTypeValues = Set([quantityType])
        
        print("Requesting HealthKit authorization...")
        healthStore.requestAuthorization(toShare: dataTypeValues, read: dataTypeValues) { (success, error) in
            if let error = error {
                NSLog("Error requesting authorization to HealthStore: \(error.localizedDescription)")
            }
            
            guard success else {
                NSLog("Unable to query daily steps data: HealthStore authorization failed.")
                return
            }
            
            print("HealthKit authorization successful!")
            self.queryDailyQuantitySamplesForPastWeek()
        }
    }
    
    func stopQuery() {
        if let query = query {
            print("Stopping HealthKit query...")
            healthStore.stop(query)
        }
    }
    
    // MARK: - Read Steps Data
    
    /// Create and execute an HKStatisticsCollectionQuery for daily step count totals over the last seven days
    func queryDailyQuantitySamplesForPastWeek() {
        performQuery {
            DispatchQueue.main.async { [weak self] in
                self?.reloadData()
            }
        }
    }
    
    // MARK: - Data Life Cycle
    
    func reloadData() {
        self.dataValues.isEmpty ? self.setEmptyDataView() : self.removeEmptyDataView()
        self.dataValues.sort { $0.startDate > $1.startDate }
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }
    
    private func setEmptyDataView() {
        let title = dataTypeName
        let subtitle = "No data recorded. Please add some \(dataTypeName.lowercased()) data."
        let image = tabBarItem.image
        
        tableView.addSplashScreen(title: title, subtitle: subtitle, image: image)
    }
    
    private func removeEmptyDataView() {
        tableView.removeSplashScreen()
    }
    
    // MARK: - Selectors
    
    @objc private func didTapRightBarButtonItem() {
        presentAddDataAlert()
    }
}


// MARK: - Add Data

extension WaterIntakeTableViewController {
    
    private func presentAddDataAlert() {
        let title = dataTypeName
        let message = "Add water intake amount."
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = title
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let confirmAction = UIAlertAction(title: "Add", style: .default) { [weak self, weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            
            if let string = textField.text, let doubleValue = Double(string) {
                self?.didAddNewData(with: doubleValue)
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        
        present(alertController, animated: true)
    }
}


// MARK: - HealthQueryDataSource

extension WaterIntakeTableViewController: HealthQueryDataSource {
    
    func performQuery(completion: @escaping () -> Void) {
        
        // Construct an HKStatisticsCollectionQuery; only calculate daily steps data from the past week
        let dateSevenDaysAgo = calendar.date(byAdding: DateComponents(day: -7), to: Date())!
        let lastSevenDaysPredicate = HKQuery.predicateForSamples(withStart: dateSevenDaysAgo, end: nil, options: .strictStartDate)
        let statisticsOptions = HKStatisticsOptions.cumulativeSum
        let anchorDate = calendar.startOfDay(for: Date())
        let dailyInterval = DateComponents(day: 1)
        
        let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                quantitySamplePredicate: lastSevenDaysPredicate,
                                                options: statisticsOptions,
                                                anchorDate: anchorDate,
                                                intervalComponents: dailyInterval)
        
        // The handler block for the HKStatisticsCollection results: updates the UI with the results
        let updateUIWithStatistics: (HKStatisticsCollection) -> Void = { statisticsCollection in
            self.dataValues = []
            
            let endDate = Date()
            let startDate = self.calendar.date(byAdding: .day, value: -6, to: endDate)!
            
            statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { [weak self] statistics, stop in
                guard let self = self else { return }
                
                var dataValue = HealthDataTypeValue(startDate: statistics.startDate, endDate: statistics.endDate, value: 0)
                
                if let quantity = statistics.sumQuantity() {
                    dataValue.value = quantity.doubleValue(for: self.unit)
                }
                
                self.dataValues.append(dataValue)
            }
            
            completion()
        }
        
        // Handle initial query results
        query.initialResultsHandler = { query, statisticsCollection, error in
            print("query.initialResultsHandler()")
            if let statisticsCollection = statisticsCollection {
                updateUIWithStatistics(statisticsCollection)
            }
        }
        
        // Handle ongoing query results updates
        query.statisticsUpdateHandler = { query, statistics, statisticsCollection, error in
            print("query.statisticsUpdateHandler()")
            if let statisticsCollection = statisticsCollection {
                updateUIWithStatistics(statisticsCollection)
            }
        }
        
        // Execute query on the HealthStore
        healthStore.execute(query)
        self.query = query
    }
}


// MARK: - UITableViewDataSource

extension WaterIntakeTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataValues.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WaterIntakeTableViewCell.reuseIdentifier) as? WaterIntakeTableViewCell else {
            return WaterIntakeTableViewCell()
        }
        
        let dataValue = dataValues[indexPath.row]
        
        cell.textLabel?.text = formattedValue(dataValue.value)
        cell.detailTextLabel?.text = dateFormatter.string(from: dataValue.startDate)
        
        return cell
    }
    
    private func formattedValue(_ value: Double) -> String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let numberValue = NSNumber(value: round(value))
        
        guard let roundedValue = numberFormatter.string(from: numberValue) else { return nil }
        
        let formattedString = String.localizedStringWithFormat("%@ %@", roundedValue, unitSuffix)
        return formattedString
    }
}


// MARK: - UITableViewDelegate

extension WaterIntakeTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


// MARK: - HealthDataTableViewControllerDelegate

extension WaterIntakeTableViewController: HealthDataTableViewControllerDelegate {
    
    /// Handle a value corresponding to incoming HealthKit data.
    func didAddNewData(with value: Double) {
        let now = Date()
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        let quantitySample = HKQuantitySample(type: quantityType, quantity: quantity, start: now, end: now)

        HealthData.saveHealthData([quantitySample]) { [weak self] success, error in
            
            if let error = error {
                NSLog("WeeklyWaterIntakeTableViewController didAddNewData error:", error.localizedDescription)
            }
            
            if success {
                print("Successfully saved a new sample!", quantitySample)
                DispatchQueue.main.async { [weak self] in
                    self?.reloadData()
                }
            } else {
                NSLog("Error: Could not save new sample.", quantitySample)
            }
        }
    }
}


// MARK: - SettingsTracking

extension WaterIntakeTableViewController: SettingsTracking {
    func healthIntegrationIsEnabledChanged() {
        if AppSettings.shared.healthIntegrationIsEnabled {
            requestAuthorizationAndQueryData()
        } else {
            dataValues.removeAll()
            reloadData()
        }
    }
}
