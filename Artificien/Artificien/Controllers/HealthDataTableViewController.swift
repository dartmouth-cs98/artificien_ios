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
    @IBOutlet weak var modelLossLabel: UILabel!
    
    private let userHealthProfile = HealthProfile()
    
    var spinner = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkHealthKitStatus()
        updateLabels()
        updateHealthKitDataCell.addGradientBackground(firstColor: UIColor(red: 0.24, green: 0.04, blue: 0.42, alpha: 1.00),
                                                      secondColor:  UIColor(red: 0.69, green: 0.44, blue: 0.92, alpha: 1.00))
        self.navigationController?.navigationBar.largeTitleTextAttributes = [.font: UIFont(name: "Avenir", size: 30)!]
        
        spinner.hidesWhenStopped = true
        spinner.center = self.view.center
        spinner.backgroundColor = .gray
        self.view.addSubview(spinner)
        self.view.bringSubviewToFront(spinner)
    }
    
    // MARK: UI Helpers
    
    // Check whether HealthKit has already been authorized and toggle relevant indicators
    private func checkHealthKitStatus() {
        
        spinner.startAnimating()
        
        let healthKitAuthorized = HKHealthStore.isHealthDataAvailable()
        self.authorizedStatusLabel.text = healthKitAuthorized ? "Authorized" : "Unauthorized"
        self.authorizedStatusLabel.textColor = healthKitAuthorized ? UIColor.systemGreen : UIColor.systemRed
        // self.authorizeHealthKitCell.isHidden = healthKitAuthorized
        
        spinner.stopAnimating()
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
        spinner.startAnimating()
        loadAndDisplayAgeSexAndBloodType()
        loadAndDisplayMostRecentHeight()
        loadAndDisplayMostRecentWeight()
        loadAndDisplayMostRecentSteps()
        UserDefaults.standard.set(self.userHealthProfile.bodyMassIndex, forKey: "bodyMassIndex")
        updateLabels()
        spinner.stopAnimating()
    }
    
    private func updateLabels() {
        
        if let loss = UserDefaults.standard.object(forKey: "modelLoss") {
            modelLossLabel.text = "\(loss)"
        }
        
        if let age = UserDefaults.standard.object(forKey: "age") {
            ageLabel.text = "\(age)"
        }
        
        if let biologicalSex = UserDefaults.standard.object(forKey: "biologicalSex") {
            biologicalSexLabel.text = biologicalSex as? String
        }
        
        if let bloodType = UserDefaults.standard.object(forKey: "bloodType") {
            bloodTypeLabel.text = bloodType as? String
        }
        
        if let weight = UserDefaults.standard.object(forKey: "weightInKilograms") {
            let weightFormatter = MassFormatter()
            weightFormatter.isForPersonMassUse = true
            weightLabel.text = weightFormatter.string(fromKilograms: weight as! Double)
        }
        
        if let height = UserDefaults.standard.object(forKey: "heightInMeters") {
            let heightFormatter = LengthFormatter()
            heightFormatter.isForPersonHeightUse = true
            heightLabel.text = heightFormatter.string(fromMeters: height as! Double)
        }
        
        if let bodyMassIndex = UserDefaults.standard.object(forKey: "bodyMassIndex") {
            bodyMassIndexLabel.text = String(format: "%.02f", bodyMassIndex as! Double)
        }
        
        if let stepCount = UserDefaults.standard.object(forKey: "stepCount") {
            stepCountLabel.text = "\(stepCount)"
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
            
            UserDefaults.standard.set(userHealthProfile.age, forKey: "age")
            UserDefaults.standard.set(userHealthProfile.biologicalSex?.toString, forKey: "biologicalSex")
            UserDefaults.standard.set(userHealthProfile.bloodType?.toString, forKey: "bloodType")
            
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
        
        HealthKitCalls.getSamples(for: heightSampleType, startDate: Date.distantPast) {
            (sample, error) in

            guard let sample = sample?.first as? HKQuantitySample else {
                self.displayAlert(for: error, title: "Error Loading Height", message: nil)
                return
            }
            
            // Convert the height sample to meters, save to the profile model, and update the user interface.
            let heightInMeters = sample.quantity.doubleValue(for: HKUnit.meter())
            self.userHealthProfile.heightInMeters = heightInMeters
            
            UserDefaults.standard.set(self.userHealthProfile.heightInMeters, forKey: "heightInMeters")
            UserDefaults.standard.set(self.userHealthProfile.bodyMassIndex, forKey: "bodyMassIndex")
            
            self.updateLabels()
        }
    }
    
    private func loadAndDisplayMostRecentWeight() {
        
        guard let weightSampleType = HKSampleType.quantityType(forIdentifier: .bodyMass) else {
            self.displayAlert(for: nil, title: "Body Mass Sample Error", message: "Body Mass Sample Type is no longer available in HealthKit")
            return
        }
        
        HealthKitCalls.getSamples(for: weightSampleType, startDate: Date.distantPast) {
            (sample, error) in
            
            guard let sample = sample?.first as? HKQuantitySample else {
                self.displayAlert(for: error, title: "Error Loading Weight", message: nil)
                return
            }
            
            let weightInKilograms = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            self.userHealthProfile.weightInKilograms = weightInKilograms
            
            UserDefaults.standard.set(self.userHealthProfile.weightInKilograms, forKey: "weightInKilograms")
            UserDefaults.standard.set(self.userHealthProfile.bodyMassIndex, forKey: "bodyMassIndex")

            self.updateLabels()
        }
    }
    
    private func loadAndDisplayMostRecentSteps() {
        
        guard let stepCountSampleType = HKSampleType.quantityType(forIdentifier: .stepCount) else {
            self.displayAlert(for: nil, title: "Step Count Sample Error", message: "Step Count Sample Type is no longer available in HealthKit")
            return
        }
        
        HealthKitCalls.getSamples(for: stepCountSampleType, startDate: Calendar.current.startOfDay(for: Date()), mostRecentOnly: false) {
            (samples, error) in
            
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
            
            UserDefaults.standard.set(self.userHealthProfile.stepCount, forKey: "stepCount")

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
        if indexPath.section == 4 && indexPath.row == 1 {
            authorizeHealthKit()
        }
        
        // Refresh HealthKit button
        if indexPath.section == 5 {
            updateHealthInfo()
        }
    }
}
