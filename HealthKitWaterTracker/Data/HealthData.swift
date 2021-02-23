//
//  HealthData.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/23/21.
//

import Foundation
import HealthKit

class HealthData {
    
    static let healthStore: HKHealthStore = HKHealthStore()
    
    // MARK: - Data Types
    
    static var readDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    static var shareDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    private static var allHealthDataTypes: [HKSampleType] {
        let typeIdentifiers: [String] = [
            HKQuantityTypeIdentifier.dietaryWater.rawValue,
        ]
        
        return typeIdentifiers.compactMap { getSampleType(for: $0) }
    }
    
    // MARK: - Authorization
    
    /// Request health data from HealthKit if needed, using the data types within `HealthData.allHealthDataTypes`
    class func requestHealthDataAccessIfNeeded(dataTypeIdentifiers: [String]? = nil, completion: @escaping (_ success: Bool) -> Void) {
        var readDataTypes = Set(allHealthDataTypes)
        var shareDataTypes = Set(allHealthDataTypes)
        
        if let dataTypeIdentifiers = dataTypeIdentifiers {
            readDataTypes = Set(dataTypeIdentifiers.compactMap { getSampleType(for: $0) })
            shareDataTypes = readDataTypes
        }
        
        requestHealthDataAccessIfNeeded(toShare: shareDataTypes, read: readDataTypes, completion: completion)
    }
    
    /// Request health data from HealthKit if needed.
    class func requestHealthDataAccessIfNeeded(toShare shareTypes: Set<HKSampleType>?, read readTypes: Set<HKObjectType>?, completion: @escaping (_ success: Bool) -> Void) {
        
        guard HKHealthStore.isHealthDataAvailable() else {
            fatalError("Health data is not available!")
        }
        
        print("Requesting HealthKit authorization...")
        
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
            if let error = error {
                print("requestAuthorization error:", error.localizedDescription)
            }
            
            if success {
                print("HealthKit authorization request was successful!")
            } else {
                print("HealthKit authorization was not successful.")
            }
            
            completion(success)
        }
    }
    
    // MARK: - HKHealthStore
    
    class func saveHealthData(_ data: [HKObject], completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        healthStore.save(data, withCompletion: completion)
    }
    
    // MARK: - HKStatisticsCollectionQuery
    
    class func fetchStatistics(with identifier: HKQuantityTypeIdentifier,
                               predicate: NSPredicate? = nil,
                               options: HKStatisticsOptions,
                               startDate: Date,
                               endDate: Date = Date(),
                               interval: DateComponents,
                               completion: @escaping (HKStatisticsCollection) -> Void) {
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            fatalError("*** Unable to create a step count type ***")
        }
        
        let anchorDate = Calendar.current.startOfDay(for: Date())
        
        // Create the query
        let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                quantitySamplePredicate: predicate,
                                                options: options,
                                                anchorDate: anchorDate,
                                                intervalComponents: interval)
        
        // Set the results handler
        query.initialResultsHandler = { query, results, error in
            if let statsCollection = results {
                completion(statsCollection)
            }
        }
         
        healthStore.execute(query)
    }
    
    // MARK: - Helper Functions
    
    class func updateAnchor(_ newAnchor: HKQueryAnchor?, from query: HKAnchoredObjectQuery) {
        if let sampleType = query.objectType as? HKSampleType {
            setAnchor(newAnchor, for: sampleType)
        } else {
            if let identifier = query.objectType?.identifier {
                print("anchoredObjectQueryDidUpdate error: Did not save anchor for \(identifier) – Not an HKSampleType.")
            } else {
                print("anchoredObjectQueryDidUpdate error: query doesn't not have non-nil objectType.")
            }
        }
    }
    
    private static let userDefaults = UserDefaults.standard
    
    private static let anchorKeyPrefix = "Anchor_"
    
    private class func anchorKey(for type: HKSampleType) -> String {
        return anchorKeyPrefix + type.identifier
    }
    
    /// Returns the saved anchor used in a long-running anchored object query for a particular sample type.
    /// Returns nil if a query has never been run.
    class func getAnchor(for type: HKSampleType) -> HKQueryAnchor? {
        if let anchorData = userDefaults.object(forKey: anchorKey(for: type)) as? Data {
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: anchorData)
        }
        
        return nil
    }
    
    /// Update the saved anchor used in a long-running anchored object query for a particular sample type.
    private class func setAnchor(_ queryAnchor: HKQueryAnchor?, for type: HKSampleType) {
        if let queryAnchor = queryAnchor,
            let data = try? NSKeyedArchiver.archivedData(withRootObject: queryAnchor, requiringSecureCoding: true) {
            userDefaults.set(data, forKey: anchorKey(for: type))
        }
    }
}


// MARK: - Helpers

extension HealthData {
    
    /// Return an HKSampleType based on the input identifier that corresponds to an HKQuantityTypeIdentifier, HKCategoryTypeIdentifier
    /// or other valid HealthKit identifier. Returns nil otherwise.
    private class func getSampleType(for identifier: String) -> HKSampleType? {
        if let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: identifier)) {
            return quantityType
        }
        
        if let categoryType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: identifier)) {
            return categoryType
        }
        
        return nil
    }
    
    /// Return an anchor date for a statistics collection query.
    private class func createAnchorDate() -> Date {
        // Set the arbitrary anchor date to Monday at 3:00 a.m.
        let calendar: Calendar = .current
        var anchorComponents = calendar.dateComponents([.day, .month, .year, .weekday], from: Date())
        let offset = (7 + (anchorComponents.weekday ?? 0) - 2) % 7
        
        anchorComponents.day! -= offset
    //    anchorComponents.hour = 3
        
        let anchorDate = calendar.date(from: anchorComponents)!
        
        return anchorDate
    }
}
