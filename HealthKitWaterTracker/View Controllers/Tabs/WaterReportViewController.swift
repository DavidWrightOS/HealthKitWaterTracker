//
//  WaterReportViewController.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/23/21.
//

import UIKit
import HealthKit

/// A representation of health data related to mobility.
class WaterReportViewController: UIViewController {
    
    // MARK: - Properties
    
    let calendar = Calendar.current
    let healthStore = HealthData.healthStore
    
    let quantityType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
    let unit = HKUnit.fluidOunceUS()
    var query: HKStatisticsCollectionQuery?
    
    let dataTypeName = "Water Intake"
    let unitSuffix = "fl oz (US)"
    
    var dataValues: [HealthDataTypeValue] = [] // tableView data source
    var values: [Double] { dataValues.reversed().map { $0.value } } // chartView data source
    
    // MARK: - UI Components
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    lazy var chartView: ChartView = {
        let chartView = ChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.dataSource = self
        chartView.delegate = self
        return chartView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForhealthIntegrationIsEnabledChanges()
        registerForBlueColorThemeIsEnabledChanges()
        setUpViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = dataTypeName
        
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
        dataValues.isEmpty ? setEmptyDataView() : removeEmptyDataView()
        dataValues.sort { $0.startDate > $1.startDate }
        tableView.reloadData()
        tableView.refreshControl?.endRefreshing()
        chartView.reloadChart()
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
    
    // MARK: - Date Formatters
    
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }()
    
    lazy var monthDayDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return dateFormatter
    }()
    
    lazy var monthDayYearDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        return dateFormatter
    }()
    
    lazy var dayYearDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d, yyyy"
        return dateFormatter
    }()
}

// MARK: - Setup Views

extension WaterReportViewController {
    
    private func setUpViews() {
        
        navigationController?.navigationBar.layoutMargins.left = 20
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add Data", style: .plain, target: self, action: #selector(didTapRightBarButtonItem))
        title = tabBarItem.title
        
        tableView.register(WaterIntakeTableViewCell.self, forCellReuseIdentifier: WaterIntakeTableViewCell.reuseIdentifier)
        tableView.backgroundColor = .clear
        
        view.addSubview(chartView)
        view.addSubview(tableView)
        
        // SetUp Constraints
        let verticalMargin: CGFloat = 8
        let horizontalMargin: CGFloat = 20
        
        chartView.widthAnchor.constraint(equalTo: chartView.heightAnchor, multiplier: 4/3).isActive = true
        chartView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: verticalMargin).isActive = true
        chartView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: horizontalMargin).isActive = true
        chartView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -horizontalMargin).isActive = true
        
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: verticalMargin).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        
        configureColorScheme()
    }
    
    override func configureColorScheme() {
        super.configureColorScheme()
        
        chartView.applyCurrentColorScheme()
    }
}


// MARK: - Add Data

extension WaterReportViewController {
    
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

extension WaterReportViewController: HealthQueryDataSource {
    
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

extension WaterReportViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataValues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

extension WaterReportViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


// MARK: - HealthDataTableViewControllerDelegate

extension WaterReportViewController: HealthDataTableViewControllerDelegate {
    
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

extension WaterReportViewController: SettingsTracking {
    func blueColorThemeIsEnabledChanged() {
        configureColorScheme()
    }
    
    func healthIntegrationIsEnabledChanged() {
        if AppSettings.shared.healthIntegrationIsEnabled {
            requestAuthorizationAndQueryData()
        } else {
            dataValues.removeAll()
            reloadData()
        }
    }
}


// MARK: - ChartViewDataSource

extension WaterReportViewController: ChartViewDataSource {
    var chartValues: [CGFloat] {
        values.map { CGFloat($0) }
    }
}


// MARK: - ChartViewDelegate

extension WaterReportViewController: ChartViewDelegate {
    
    var chartTitle: String? {
        "Last Seven Days"
    }
    
    var chartSubtitle: String? {
        createChartWeeklyDateRangeLabel()
    }
    
    var chartUnitTitle: String? {
        unitSuffix
    }
    
    var chartHorizontalAxisMarkers: [String]? {
        createHorizontalAxisMarkers()
    }
}


// MARK: - ChartView Helpers

extension WaterReportViewController {
    
    /// Return a label describing the date range of the chart for the last week. Example: "Jun 3 - Jun 10, 2020"
    func createChartWeeklyDateRangeLabel(lastDate: Date = Date()) -> String {
        let endOfWeekDate = lastDate
        let startOfWeekDate = calendar.date(byAdding: .day, value: -6, to: endOfWeekDate)!
        
        var startDateString = monthDayDateFormatter.string(from: startOfWeekDate)
        var endDateString = monthDayYearDateFormatter.string(from: endOfWeekDate)
        
        // If the start and end dates are in the same month.
        if calendar.isDate(startOfWeekDate, equalTo: endOfWeekDate, toGranularity: .month) {
            endDateString = dayYearDateFormatter.string(from: endOfWeekDate)
        }
        
        // If the start and end dates are in different years.
        if !calendar.isDate(startOfWeekDate, equalTo: endOfWeekDate, toGranularity: .year) {
            startDateString = monthDayYearDateFormatter.string(from: startOfWeekDate)
        }
        
        return String(format: "%@–%@", startDateString, endDateString)
    }
    
    /// Returns an array of horizontal axis markers based on the desired time frame, where the last axis marker corresponds to `lastDate`
    /// `useWeekdays` will use short day abbreviations (e.g. "Sun, "Mon", "Tue") instead.
    /// Defaults to showing the current day as the last axis label of the chart and going back one week.
    func createHorizontalAxisMarkers(lastDate: Date = Date(), useWeekdays: Bool = true) -> [String] {
        let calendar: Calendar = .current
        let weekdayTitles = calendar.shortWeekdaySymbols
        
        var titles: [String] = []
        
        if useWeekdays {
            titles = weekdayTitles
            
            let weekday = calendar.component(.weekday, from: lastDate)
            
            return Array(titles[weekday..<titles.count]) + Array(titles[0..<weekday])
            
        } else {
            let numberOfDaysInWeek = weekdayTitles.count
            let startDate = calendar.date(byAdding: DateComponents(day: -(numberOfDaysInWeek - 1)), to: lastDate)!
            
            var date = startDate
            
            while date <= lastDate {
                titles.append(monthDayDateFormatter.string(from: date))
                date = calendar.date(byAdding: .day, value: 1, to: date)!
            }
            
            return titles
        }
    }
}
