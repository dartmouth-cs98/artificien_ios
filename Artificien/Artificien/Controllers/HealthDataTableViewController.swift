//
//  HealthDataTableViewController.swift
//  Artificien
//
//  Created by Shreyas Agnihotri on 10/25/20.
//  Copyright © 2020 Shreyas Agnihotri. All rights reserved.
//

import UIKit
import HealthKit
import Artificien
import NVActivityIndicatorView

class HealthDataTableViewController: UITableViewController {
    
    // MARK: Setup
    
    // Outlets
    @IBOutlet weak var authorizeHealthKitLabel: UILabel!
    @IBOutlet weak var authorizedStatusLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var biologicalSexLabel: UILabel!
    @IBOutlet weak var bloodTypeLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var bodyMassIndexLabel: UILabel!
    @IBOutlet weak var stepCountLabel: UILabel!
    @IBOutlet weak var modelLossLabel: UILabel!
    
    // Health data
    private let userHealthProfile = HealthProfile()
    
    // Artificien
    let artificien = Artificien(chargeDetection: false, wifiDetection: false)
    
    // Spinner UI
    var spinner: NVActivityIndicatorView!
    var fadeView: UIView!
    
    // Helper to restrict UserDefaults keys
    enum UserDefaultsKey: String {
        case healthKitAuthorized = "healthKitAuthorized"
        case trainingResult = "trainingResult"
        case BMI = "bodyMassIndex"
        case age = "age"
        case sex = "biologicalSex"
        case bloodType = "bloodType"
        case weight = "weightInKilograms"
        case height = "heightInMeters"
        case steps = "stepCount"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.largeTitleTextAttributes = [.font: UIFont(name: "Avenir", size: 30)!]
        configureSpinner()
        updateLabels()
    }
    
    // MARK: UI Helpers
    
    // Configure loading view
    func configureSpinner() {
        spinner = NVActivityIndicatorView(frame: UIScreen.main.bounds, type: .pacman, color: .white, padding: view.frame.width / 3)
        fadeView = UIView(frame: self.view.frame)
        fadeView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.view.addSubview(fadeView)
        self.view.bringSubviewToFront(fadeView)
        fadeView.isHidden = true
        self.view.addSubview(spinner)
        self.view.bringSubviewToFront(spinner)
    }
    
    // Start animating loading view on faded back screen
    public func showSpinner() {
        fadeView.isHidden = false
        spinner.startAnimating()
    }
    
    // Stop animating loading view
    public func hideSpinner() {
        fadeView.isHidden = true
        spinner.stopAnimating()
    }
    
    // Display alert as popup with OK message given error or hard-coded message
    private func displayAlert(for error: Error?, title: String, message: String?, completion: (() -> Void)? = nil) {
        
        DispatchQueue.main.async {
            self.hideSpinner()
            
            let alert = UIAlertController(title: title,
                                          message: error?.localizedDescription ?? message,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK",
                                          style: .default,
                                          handler: nil))
            self.present(alert, animated: true, completion: completion)
        }
    }
    
    // Refresh health data from HealthKit; store in UserDefaults
    private func updateHealthInfo() {
        showSpinner()
        loadAndDisplayAgeSexAndBloodType()
        loadAndDisplayMostRecentHeight()
        loadAndDisplayMostRecentWeight()
        loadAndDisplayMostRecentSteps()
        hideSpinner()
    }
    
    // Update table data from UserDefaults stored values
    private func updateLabels() {
        
        showSpinner()
        
        if let authorized = UserDefaults.standard.object(forKey: UserDefaultsKey.healthKitAuthorized.rawValue) as? Bool {
            self.authorizedStatusLabel.text = authorized ? "Authorized" : "Unauthorized"
            self.authorizedStatusLabel.textColor = authorized ? UIColor.systemGreen : UIColor.systemRed
            // self.authorizeHealthKitLabel.text = authorized ? "Refresh Health Data" : "Authorize HealthKit"
        }
        
        if let result = UserDefaults.standard.string(forKey: UserDefaultsKey.trainingResult.rawValue) {
            modelLossLabel.text = result
        }
        
        if let age = UserDefaults.standard.object(forKey: UserDefaultsKey.age.rawValue) {
            ageLabel.text = "\(age)"
        }
        
        if let biologicalSex = UserDefaults.standard.object(forKey: UserDefaultsKey.sex.rawValue) {
            biologicalSexLabel.text = biologicalSex as? String
        }
        
        if let bloodType = UserDefaults.standard.object(forKey: UserDefaultsKey.bloodType.rawValue) {
            bloodTypeLabel.text = bloodType as? String
        }
        
        if let weight = UserDefaults.standard.object(forKey: UserDefaultsKey.weight.rawValue) {
            let weightFormatter = MassFormatter()
            weightFormatter.isForPersonMassUse = true
            weightLabel.text = weightFormatter.string(fromKilograms: weight as! Double)
        }
        
        if let height = UserDefaults.standard.object(forKey: UserDefaultsKey.height.rawValue) {
            let heightFormatter = LengthFormatter()
            heightFormatter.isForPersonHeightUse = true
            heightLabel.text = heightFormatter.string(fromMeters: height as! Double)
        }
        
        if let bodyMassIndex = UserDefaults.standard.object(forKey: UserDefaultsKey.BMI.rawValue) {
            bodyMassIndexLabel.text = String(format: "%.02f", bodyMassIndex as! Double)
        }
        
        if let stepCount = UserDefaults.standard.object(forKey: UserDefaultsKey.steps.rawValue) {
            stepCountLabel.text = "\(stepCount)"
        }
        
        hideSpinner()
    }
    
    // MARK: HealthKit
        
    // Call helper function to present HealthKit Authorization flow
    private func authorizeHealthKit() {
        
        showSpinner()
      
        HealthKitCalls.authorizeHealthKit { (authorized, error) in
        
            guard authorized else {
                
                UserDefaults.standard.set(false, forKey: UserDefaultsKey.healthKitAuthorized.rawValue)
                self.updateLabels()
                
                // Display error alert
                DispatchQueue.main.sync {
                    self.displayAlert(for: error,
                                      title: "HealthKit Authorization Error",
                                      message: "Please give Artificien access to all HealthKit data.")
                }
                return
            }
            
            DispatchQueue.main.sync {
                UserDefaults.standard.set(true, forKey: UserDefaultsKey.healthKitAuthorized.rawValue)
                self.updateLabels()
                self.updateHealthInfo()
                self.hideSpinner()
            }
        }
    }
        
    // Pull age, sex, and blood type from HealthKit; else show error
    private func loadAndDisplayAgeSexAndBloodType() {
        
        do {
            let userAgeSexAndBloodType = try HealthKitCalls.getAgeSexAndBloodType()
            userHealthProfile.age = userAgeSexAndBloodType.age
            userHealthProfile.biologicalSex = userAgeSexAndBloodType.biologicalSex
            userHealthProfile.bloodType = userAgeSexAndBloodType.bloodType
            
            UserDefaults.standard.set(userHealthProfile.age, forKey: "age")
            UserDefaults.standard.set(userHealthProfile.biologicalSex?.toString, forKey: UserDefaultsKey.sex.rawValue)
            UserDefaults.standard.set(userHealthProfile.bloodType?.toString, forKey: UserDefaultsKey.bloodType.rawValue)
            
            updateLabels()
            
        } catch let error {
            self.displayAlert(for: error,
                              title: "Error Loading Sex And Blood Type",
                              message: nil)
        }
    }
    
    // Pull height from HealthKit; else show error
    private func loadAndDisplayMostRecentHeight() {
        
        // Use HealthKit to create the Height Sample Type
        guard let heightSampleType = HKSampleType.quantityType(forIdentifier: .height) else {
            self.displayAlert(for: nil,
                              title: "Height Sample Error",
                              message: "Height Sample Type is no longer available in HealthKit")
            return
        }
        
        HealthKitCalls.getSamples(for: heightSampleType, startDate: Date.distantPast) {
            (sample, error) in

            guard let sample = sample?.first as? HKQuantitySample else {
                self.displayAlert(for: error,
                                  title: "Error Loading Height",
                                  message: nil)
                return
            }
            
            // Convert the height sample to meters, save to the profile model, and update the user interface
            let heightInMeters = sample.quantity.doubleValue(for: HKUnit.meter())
            self.userHealthProfile.heightInMeters = heightInMeters
            
            UserDefaults.standard.set(self.userHealthProfile.heightInMeters, forKey: UserDefaultsKey.height.rawValue)
            UserDefaults.standard.set(self.userHealthProfile.bodyMassIndex, forKey: UserDefaultsKey.BMI.rawValue)
            
            self.updateLabels()
        }
    }
    
    // Pull weight from HealthKit; else show error
    private func loadAndDisplayMostRecentWeight() {
        
        // Use HealthKit to create the Weight Sample Type
        guard let weightSampleType = HKSampleType.quantityType(forIdentifier: .bodyMass) else {
            self.displayAlert(for: nil,
                              title: "Body Mass Sample Error",
                              message: "Body Mass Sample Type is no longer available in HealthKit")
            return
        }
        
        HealthKitCalls.getSamples(for: weightSampleType, startDate: Date.distantPast) {
            (sample, error) in
            
            guard let sample = sample?.first as? HKQuantitySample else {
                self.displayAlert(for: error, title: "Error Loading Weight", message: nil)
                return
            }
            
            // Convert the weight sample to kilograms, save to the profile model, and update the user interface
            let weightInKilograms = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            self.userHealthProfile.weightInKilograms = weightInKilograms
            
            UserDefaults.standard.set(self.userHealthProfile.weightInKilograms, forKey: UserDefaultsKey.weight.rawValue)
            UserDefaults.standard.set(self.userHealthProfile.bodyMassIndex, forKey: UserDefaultsKey.BMI.rawValue)

            self.updateLabels()
        }
    }
    
    // Pull step count from HealthKit; else show error
    private func loadAndDisplayMostRecentSteps() {
        
        guard let stepCountSampleType = HKSampleType.quantityType(forIdentifier: .stepCount) else {
            self.displayAlert(for: nil,
                              title: "Step Count Sample Error",
                              message: "Step Count Sample Type is no longer available in HealthKit")
            return
        }
        
        // Pull all step samples from one week ago until now
        HealthKitCalls.getSamples(for: stepCountSampleType, startDate: Date(timeIntervalSinceNow: -7*24*60*60), mostRecentOnly: false) {
            (samples, error) in
            
            guard let samples = samples else {
                self.displayAlert(for: error,
                                  title: "Error Loading Step Count",
                                  message: nil)
                return
            }
            
            // Sum step counts, save to the profile model, and update the user interface
            var stepCount = 0.0
            for sample in samples {
                guard let quantitySample = sample as? HKQuantitySample else {
                    self.displayAlert(for: error,
                                      title: "Error Loading Step Count",
                                      message: nil)
                    return
                }
                stepCount += quantitySample.quantity.doubleValue(for: HKUnit.count())
            }
            self.userHealthProfile.stepCount = stepCount
            
            UserDefaults.standard.set(self.userHealthProfile.stepCount, forKey: UserDefaultsKey.steps.rawValue)

            self.updateLabels()
        }
    }
    
    // MARK: Training
    
    public static func prepareAppData() -> [String: Float]? {
        guard let age = UserDefaults.standard.object(forKey: "age") as? Int,
              let bodyMassIndex = UserDefaults.standard.object(forKey: "bodyMassIndex") as? Double,
              let sex = UserDefaults.standard.object(forKey: "biologicalSex") as? String,
              let stepCount = UserDefaults.standard.object(forKey: "stepCount") as? Int else {
            
            return nil
        }
        
        let sexAsInt = sex == "Male" ? 1 : 0
        
        let appData: [String: Float] = [
            "Age": Float(age),
            "Body Mass Index": Float(bodyMassIndex),
            "Sex": Float(sexAsInt),
            "Weekly Step Count": Float(stepCount)
        ]
        
        return appData
    }
    
    // Function to prepare and send data to Artificien for training synchronously (as an example)
    func trainModelWithArtificien() {
            
        showSpinner()
        guard let appData = HealthDataTableViewController.prepareAppData() else { return }
        self.artificien.train(data: appData)
        updateLabels()
        hideSpinner()
    }
    
    // MARK: UITableView Delegate
    
    // Set table fonts
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: "Avenir", size: 14)
    }
        
    // Handle button actions
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            
        tableView.deselectRow(at: indexPath, animated: true)   // Handle issue of cell remaining depressed
        
        let healthKitIsAuthorized = UserDefaults.standard.bool(forKey: UserDefaultsKey.healthKitAuthorized.rawValue)

        // Model actions
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                if healthKitIsAuthorized { trainModelWithArtificien() }
                else {
                    displayAlert(for: nil,
                                 title: "Hold up!",
                                 message: "Please authorize access to your health data to enable the model to train on it.")
                }
            }
            if indexPath.row == 2 {
                if healthKitIsAuthorized { updateHealthInfo() }
                else {
                    displayAlert(for: nil,
                                 title: "Hold up!",
                                 message: "Please authorize access to your health data to enable the model to train on it.")
                }
            }
        }
        
        // HealthKit actions
        if indexPath.section == 1 {
            if indexPath.row == 1 {
                // Authorize HealthKit
                
                if healthKitIsAuthorized { return }
                else {
                    authorizeHealthKit()
                }
            }
        }
        
        // Health data display
        if indexPath.section == 2 {
            if indexPath.row == 0 {
                if healthKitIsAuthorized { updateHealthInfo() }
                else {
                    displayAlert(for: nil,
                                 title: "Hold up!",
                                 message: "Please authorize access to your health data to enable the model to train on it.")
                }
            }
        }
    }
}
