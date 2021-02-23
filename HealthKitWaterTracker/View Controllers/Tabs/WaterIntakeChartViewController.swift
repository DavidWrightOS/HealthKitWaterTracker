//
//  WaterIntakeChartViewController.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/22/21.
//

import UIKit
import HealthKit

/// A representation of health data related to mobility.
class WaterIntakeChartViewController: UIViewController {
    
    // MARK: - Properties
    
    let calendar = Calendar.current
    
    let quantityType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
    let unit = HKUnit.fluidOunceUS()
    
    var query: HKAnchoredObjectQuery?
    
    var values: [Double] = [] // chart view data source
    
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
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if AppSettings.shared.healthIntegrationIsEnabled {
            requestAuthorizationAndQueryData()
        } else {
            print("Warning: Unable to configure query. The user has disabled Apple Health integration.")
            values.removeAll()
            reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopQuery()
    }
    
    // MARK: - Data
    
    func requestAuthorizationAndQueryData() {
        HealthData.requestHealthDataAccessIfNeeded(toShare: [quantityType], read: [quantityType]) { success in
            if success {
                self.createAnchoredObjectQuery(for: self.quantityType)
                self.loadData()
            }
        }
    }
    
    func stopQuery() {
        if let query = query {
            print("Stopping HealthKit query...")
            HealthData.healthStore.stop(query)
            self.query = nil
        }
    }
    
    func loadData() {
        performQuery {
            DispatchQueue.main.async { [weak self] in
                self?.reloadData()
            }
        }
    }
    
    func reloadData() {
        chartView.reloadChart()
    }
    
    // MARK: - Create Anchored Object Query
    
    func createAnchoredObjectQuery(for sampleType: HKSampleType) {
        // Customize query parameters
        let dateSevenDaysAgo = calendar.date(byAdding: DateComponents(day: -7), to: Date())!
        let lastSevenDaysPredicate = HKQuery.predicateForSamples(withStart: dateSevenDaysAgo, end: nil, options: .strictStartDate)
        let limit = HKObjectQueryNoLimit
        
        // Fetch anchor persisted in memory
        let anchor = HealthData.getAnchor(for: sampleType)
        
        // The handler block for the HKAnchoredObjecyQuery results: updates the UI with the results
        let queryResultsUpdateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
            if let error = errorOrNil {
                NSLog("HKAnchoredObjectQuery updateHandler with identifier \(sampleType.identifier) error: \(error.localizedDescription)")
                return
            }
            
            print("HKAnchoredObjectQuery updateHandler has returned for \(sampleType.identifier)!")
            
            // Update anchor for sample type
            HealthData.updateAnchor(newAnchor, from: query)
            
            // The results come back on an anonymous background queue.
            Network.push(addedSamples: samplesOrNil, deletedSamples: deletedObjectsOrNil)
        }
        
        // Create HKAnchoredObjecyQuery
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: lastSevenDaysPredicate, anchor: anchor, limit: limit, resultsHandler: queryResultsUpdateHandler)
        
        // Set the ongoing query results update handler for long-running background query
        query.updateHandler = queryResultsUpdateHandler
        
        HealthData.healthStore.execute(query)
        self.query = query
    }
    
    // MARK: - Perform Query
    
    func performQuery(completion: @escaping () -> Void) {
        // Set dates
        let endDate = Date()
        let startDate = self.calendar.date(byAdding: .day, value: -6, to: endDate)!
        let dateSevenDaysAgo = calendar.date(byAdding: DateComponents(day: -7), to: Date())!
        let lastSevenDaysPredicate = HKQuery.predicateForSamples(withStart: dateSevenDaysAgo, end: nil, options: .strictStartDate)
        let statisticsOptions = HKStatisticsOptions.cumulativeSum
        let dateInterval = DateComponents(day: 1)
        
        let initialResultsHandler: (HKStatisticsCollection) -> Void = { statisticsCollection in
            var values: [Double] = []
            
            statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                
                let statisticsQuantity = statistics.sumQuantity()
                
                let value = statisticsQuantity?.doubleValue(for: self.unit) ?? 0
                values.append(value)
            }
            
            self.values = values
            completion()
        }
        
        // Fetch statistics.
        HealthData.fetchStatistics(with: HKQuantityTypeIdentifier(rawValue: quantityType.identifier),
                                   predicate: lastSevenDaysPredicate,
                                   options: statisticsOptions,
                                   startDate: startDate,
                                   interval: dateInterval,
                                   completion: initialResultsHandler)
    }
    
    // MARK: - Date Formatters
    
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

extension WaterIntakeChartViewController {
    
    private func setupViews() {
        navigationController?.navigationBar.prefersLargeTitles = true
        title = tabBarItem.title
        view.backgroundColor = .systemBackground
        
        chartView.backgroundColor = .systemBackground
        
        view.addSubview(chartView)
        
        let verticalMargin: CGFloat = 8
        let horizontalMargin: CGFloat = 20
        let widthInset = (horizontalMargin * 2) + view.safeAreaInsets.left + view.safeAreaInsets.right
        let chartHeight = view.bounds.width - widthInset
        
        chartView.heightAnchor.constraint(equalToConstant: chartHeight).isActive = true
        chartView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: verticalMargin).isActive = true
        chartView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: horizontalMargin).isActive = true
        chartView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -horizontalMargin).isActive = true
    }
}


// MARK: - ChartViewDataSource

extension WaterIntakeChartViewController: ChartViewDataSource {
    var chartValues: [CGFloat] {
        values.map { CGFloat($0) }
    }
}


// MARK: - ChartViewDelegate

extension WaterIntakeChartViewController: ChartViewDelegate {
    
    var chartTitle: String? {
        "Water Intake"
    }
    
    var chartSubtitle: String? {
        self.createChartWeeklyDateRangeLabel()
    }
    
    var chartUnitTitle: String? {
        "fl oz (US)"
    }
    
    var chartHorizontalAxisMarkers: [String]? {
        self.createHorizontalAxisMarkers()
    }
}


// MARK: - ChartView Helpers

extension WaterIntakeChartViewController {
    
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


// MARK: - SettingsTracking

extension WaterIntakeChartViewController: SettingsTracking {
    func healthIntegrationIsEnabledChanged() {
        if AppSettings.shared.healthIntegrationIsEnabled {
            requestAuthorizationAndQueryData()
        } else {
            stopQuery()
            values.removeAll()
            reloadData()
        }
    }
}
