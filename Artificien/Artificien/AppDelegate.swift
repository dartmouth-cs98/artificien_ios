//
//  AppDelegate.swift
//  Artificien
//
//  Created by Shreyas Agnihotri on 10/19/20.
//  Copyright © 2020 Shreyas Agnihotri. All rights reserved.
//

import UIKit
import SwiftSyft
import BackgroundTasks
import Artificien

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.artificien.background", using: DispatchQueue.global()) { task in
                        
            let artificien = Artificien()
            guard let appData = HealthDataTableViewController.prepareAppData() else { return }
            artificien.train(data: appData, backgroundTask: task)
        }

        do {
            let processingTaskRequest = BGProcessingTaskRequest(identifier: "com.artificien.background")
            processingTaskRequest.requiresExternalPower = true
            processingTaskRequest.requiresNetworkConnectivity = true
            try BGTaskScheduler.shared.submit(processingTaskRequest)
        } catch {
            print(error.localizedDescription)
        }

        return true
    }
}

