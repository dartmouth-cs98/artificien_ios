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
    
    @IBOutlet weak var authorizeHealthKitCell: UITableViewCell!
    @IBOutlet weak var authorizedStatusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkHealthKitStatus()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    //    override func numberOfSections(in tableView: UITableView) -> Int {
    //        // #warning Incomplete implementation, return the number of sections
    //        return 0
    //    }
    //
    //    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    //        // #warning Incomplete implementation, return the number of rows
    //        return 0
    //    }
    
    // MARK: HealthKit Authorization
    
    // Check whether HealthKit has already been authorized and toggle relevant indicators
    private func checkHealthKitStatus() {
        let healthKitAuthorized = HKHealthStore.isHealthDataAvailable()
        self.authorizedStatusLabel.text = healthKitAuthorized ? "Authorized" : "Unauthorized"
        self.authorizedStatusLabel.textColor = healthKitAuthorized ? UIColor.systemGreen : UIColor.systemRed
        // self.authorizeHealthKitCell.isHidden = healthKitAuthorized
    }
        
    // Call helper function to present HealthKit Authorization flow
    private func authorizeHealthKit() {
      
        HealthKitCalls.authorizeHealthKit { (authorized, error) in
        
            guard authorized else {
                
                // Displau error alert
                DispatchQueue.main.sync {
                    let alert = UIAlertController(title: "HealthKit Authorization Error", message: error?.localizedDescription ?? "Please give Artificien access to all HealthKit Data.", preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
                return
            }
            
            DispatchQueue.main.sync {
                self.checkHealthKitStatus()
            }
        }
    }
    
    // MARK: - UITableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      
        tableView.deselectRow(at: indexPath, animated: true)   // Handle issue of cell remaining depressed

        // Authorize HealthKit button
        if indexPath.section == 0 && indexPath.row == 1 {
            authorizeHealthKit()
        }
    }
}
