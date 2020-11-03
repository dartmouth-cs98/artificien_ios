//
//  HealthDataTableViewController.swift
//  Artificien
//
//  Created by Shreyas Agnihotri on 10/25/20.
//  Copyright © 2020 Shreyas Agnihotri. All rights reserved.
//

import UIKit
import HealthKit

class HealthDataTableViewController: UITableViewController {
    
    // MARK: Outlets & Setup
    
    @IBOutlet weak var authorizeHealthKitCell: UITableViewCell!
    @IBOutlet weak var updateHealthKitDataCell: UITableViewCell!
    @IBOutlet weak var authorizedStatusLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var biologicalSexLabel: UILabel!
    @IBOutlet weak var bloodTypeLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var bodyMassIndexLabel: UILabel!
    @IBOutlet weak var stepCountLabel: UILabel!
    
    private let userHealthProfile = HealthProfile()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkHealthKitStatus()
        updateLabels()
        updateHealthKitDataCell.addGradientBackground(firstColor: UIColor(red: 0.24, green: 0.04, blue: 0.42, alpha: 1.00),
                                                      secondColor:  UIColor(red: 0.69, green: 0.44, blue: 0.92, alpha: 1.00))
        self.navigationController?.navigationBar.largeTitleTextAttributes = [.font: UIFont(name: "Avenir", size: 30)!]
    }
    
    // MARK: UI Helpers
    
    // Check whether HealthKit has already been authorized and toggle relevant indicators
    private func checkHealthKitStatus() {
        let healthKitAuthorized = HKHealthStore.isHealthDataAvailable()
        self.authorizedStatusLabel.text = healthKitAuthorized ? "Authorized" : "Unauthorized"
        self.authorizedStatusLabel.textColor = healthKitAuthorized ? UIColor.systemGreen : UIColor.systemRed
        // self.authorizeHealthKitCell.isHidden = healthKitAuthorized
    }
    
    // Display alert as popup with OK message given error or hard-coded message
    private func displayAlert(for error: Error?, title: String, message: String?) {
        
        let alert = UIAlertController(title: title,
                                      message: error?.localizedDescription ?? message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default,
                                      handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func updateHealthInfo() {
        loadAndDisplayAgeSexAndBloodType()
        loadAndDisplayMostRecentWeight()
        loadAndDisplayMostRecentHeight()
        loadAndDisplayMostRecentSteps()
    }
    
    private func updateLabels() {
        
        if let age = userHealthProfile.age {
            ageLabel.text = "\(age)"
        }
        
        if let biologicalSex = userHealthProfile.biologicalSex {
            biologicalSexLabel.text = biologicalSex.toString
        }
        
        if let bloodType = userHealthProfile.bloodType {
            bloodTypeLabel.text = bloodType.toString
        }
        
        if let weight = userHealthProfile.weightInKilograms {
            let weightFormatter = MassFormatter()
            weightFormatter.isForPersonMassUse = true
            weightLabel.text = weightFormatter.string(fromKilograms: weight)
        }
        
        if let height = userHealthProfile.heightInMeters {
            let heightFormatter = LengthFormatter()
            heightFormatter.isForPersonHeightUse = true
            heightLabel.text = heightFormatter.string(fromMeters: height)
        }
        
        if let bodyMassIndex = userHealthProfile.bodyMassIndex {
            bodyMassIndexLabel.text = String(format: "%.02f", bodyMassIndex)
        }
        
        if let stepCount = userHealthProfile.stepCount {
            stepCountLabel.text = "\(stepCount)"
//            bodyMassIndexLabel.text = String(format: "%.02f", bodyMassIndex)
        }
    }
    
    // MARK: HealthKit Authorization
        
    // Call helper function to present HealthKit Authorization flow
    private func authorizeHealthKit() {
      
        HealthKitCalls.authorizeHealthKit { (authorized, error) in
        
            guard authorized else {
                
                // Display error alert
                DispatchQueue.main.sync {
                    self.displayAlert(for: error, title: "HealthKit Authorization Error", message: "Please give Artificien access to all HealthKit data.")
                }
                return
            }
            
            DispatchQueue.main.sync {
                self.checkHealthKitStatus()
            }
        }
    }
    
    // MARK: HealthKit Data Loading
    
    private func loadAndDisplayAgeSexAndBloodType() {
        
        do {
            let userAgeSexAndBloodType = try HealthKitCalls.getAgeSexAndBloodType()
            userHealthProfile.age = userAgeSexAndBloodType.age
            userHealthProfile.biologicalSex = userAgeSexAndBloodType.biologicalSex
            userHealthProfile.bloodType = userAgeSexAndBloodType.bloodType
            updateLabels()
        } catch let error {
            self.displayAlert(for: error, title: "Error Loading Sex And Blood Type", message: nil)
        }
    }
    
    private func loadAndDisplayMostRecentHeight() {
        
        // Use HealthKit to create the Height Sample Type
        guard let heightSampleType = HKSampleType.quantityType(forIdentifier: .height) else {
            self.displayAlert(for: nil, title: "Height Sample Error", message: "Height Sample Type is no longer available in HealthKit")
            return
        }
        
        HealthKitCalls.getSamples(for: heightSampleType,
                                  startDate: Date.distantPast) { (sample, error) in

            guard let sample = sample?.first as? HKQuantitySample else {
                self.displayAlert(for: error, title: "Error Loading Height", message: nil)
                return
            }
            
            // Convert the height sample to meters, save to the profile model, and update the user interface.
            let heightInMeters = sample.quantity.doubleValue(for: HKUnit.meter())
            self.userHealthProfile.heightInMeters = heightInMeters
            self.updateLabels()
        }
    }
    
    private func loadAndDisplayMostRecentWeight() {
        
        guard let weightSampleType = HKSampleType.quantityType(forIdentifier: .bodyMass) else {
            self.displayAlert(for: nil, title: "Body Mass Sample Error", message: "Body Mass Sample Type is no longer available in HealthKit")
            return
        }
        
        HealthKitCalls.getSamples(for: weightSampleType,
                                  startDate: Date.distantPast) { (sample, error) in
            
            guard let sample = sample?.first as? HKQuantitySample else {
                self.displayAlert(for: error, title: "Error Loading Weight", message: nil)
                return
            }
            
            let weightInKilograms = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            self.userHealthProfile.weightInKilograms = weightInKilograms
            self.updateLabels()
        }
    }
    
    private func loadAndDisplayMostRecentSteps() {
        
        guard let stepCountSampleType = HKSampleType.quantityType(forIdentifier: .stepCount) else {
            self.displayAlert(for: nil, title: "Step Count Sample Error", message: "Step Count Sample Type is no longer available in HealthKit")
            return
        }
        
        HealthKitCalls.getSamples(for: stepCountSampleType,
                                  startDate: Calendar.current.startOfDay(for: Date()),
                                  mostRecentOnly: false) { (samples, error) in
            
            guard let samples = samples else {
                self.displayAlert(for: error, title: "Error Loading Step Count", message: nil)
                return
            }
            
            var stepCount = 0.0
            for sample in samples {
                
                guard let quantitySample = sample as? HKQuantitySample else {
                    self.displayAlert(for: error, title: "Error Loading Step Count", message: nil)
                    return
                }
                stepCount += quantitySample.quantity.doubleValue(for: HKUnit.count())
            }
            self.userHealthProfile.stepCount = stepCount
            self.updateLabels()
        }
    }
    
    // MARK: UITableView Delegate
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: "Avenir", size: 14)
    }
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      
        tableView.deselectRow(at: indexPath, animated: true)   // Handle issue of cell remaining depressed

        // Authorize HealthKit button
        if indexPath.section == 0 && indexPath.row == 1 {
            authorizeHealthKit()
        }
        
        // Refresh HealthKit button
        if indexPath.section == 4 {
            updateHealthInfo()
        }
    }
}
