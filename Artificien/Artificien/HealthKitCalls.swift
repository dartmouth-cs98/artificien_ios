//
//  HealthKitCalls.swift
//  Artificien
//
//  Created by Shreyas Agnihotri on 10/25/20.
//  Copyright © 2020 Shreyas Agnihotri. All rights reserved.
//
//  Adapted from https://www.raywenderlich.com/459-healthkit-tutorial-with-swift-getting-started

import HealthKit

class HealthKitCalls {
  
    private enum HealthKitSetupError: Error {
        case notAvailableOnDevice
        case dataTypeNotAvailable
    }
  
    // Present HealthKit Authorization flow with necessary data types for Artificien to access
    class func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
        
        // Check to see if HealthKit Is Available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthKitSetupError.notAvailableOnDevice)
            return
        }
        
        // Prepare the data types that will interact with HealthKit
        guard let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
            let bloodType = HKObjectType.characteristicType(forIdentifier: .bloodType),
            let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex),
            let bodyMassIndex = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
            let height = HKObjectType.quantityType(forIdentifier: .height),
            let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
            else {
                completion(false, HealthKitSetupError.dataTypeNotAvailable)
                return
            }
        
        // Prepare a list of types you want HealthKit to read and write
        let healthKitTypesToWrite: Set<HKSampleType> = [bodyMassIndex,
                                                        activeEnergy,
                                                        HKObjectType.workoutType()]
        
        let healthKitTypesToRead: Set<HKObjectType> = [dateOfBirth,
                                                       bloodType,
                                                       biologicalSex,
                                                       bodyMassIndex,
                                                       height,
                                                       bodyMass,
                                                       HKObjectType.workoutType()]
        
        // Request Authorization
        HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite,
                                             read: healthKitTypesToRead) { (success, error) in
                                                completion(success, error)
        }
    }
    
    class func getAgeSexAndBloodType() throws -> (age: Int,
                                                  biologicalSex: HKBiologicalSex,
                                                  bloodType: HKBloodType) {
                                                    
        let healthKitStore = HKHealthStore()
        
        do {
            
            // This method throws an error if these data are not available.
            let birthdayComponents = try healthKitStore.dateOfBirthComponents()
            let biologicalSex = try healthKitStore.biologicalSex()
            let bloodType = try healthKitStore.bloodType()
            
            // Use Calendar to calculate age.
            let today = Date()
            let calendar = Calendar.current
            let todayDateComponents = calendar.dateComponents([.year], from: today)
            let thisYear = todayDateComponents.year!
            let age = thisYear - birthdayComponents.year!
            
            // Unwrap the wrappers to get the underlying enum values.
            let unwrappedBiologicalSex = biologicalSex.biologicalSex
            let unwrappedBloodType = bloodType.bloodType
            
            return (age, unwrappedBiologicalSex, unwrappedBloodType)
        }
    }
    
    class func getMostRecentSample(for sampleType: HKSampleType,
                                   completion: @escaping (HKQuantitySample?, Error?) -> Swift.Void) {
        
        // Use HKQuery to load the most recent samples.
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                              end: Date(),
                                                              options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: false)
        
        let limit = 1
        
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                        predicate: mostRecentPredicate,
                                        limit: limit,
                                        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                                            
            // Always dispatch to the main thread when complete.
            DispatchQueue.main.async {
                
                guard let samples = samples,
                    let mostRecentSample = samples.first as? HKQuantitySample else {
                        
                        completion(nil, error)
                        return
                }
                
                completion(mostRecentSample, nil)
            }
        }
        
        HKHealthStore().execute(sampleQuery)
    }
}
