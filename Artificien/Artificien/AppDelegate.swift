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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var syftJob: SyftJob?
    private var syftClient: SyftClient?

    // Flag that indicates if the background task has been cancelled.
    private var backgroundTaskCancelled = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "edu.dartmouth.Artificien-Mobile", using: DispatchQueue.global()) { task in

            self.executeSyftJob(backgroundTask: task)

        }

        self.scheduleTrainingJob()

        return true
    }

    func scheduleTrainingJob() {
        do {
            let processingTaskRequest = BGProcessingTaskRequest(identifier: "edu.dartmouth.Artificien-Mobile")
            processingTaskRequest.requiresExternalPower = true
            processingTaskRequest.requiresNetworkConnectivity = true
            try BGTaskScheduler.shared.submit(processingTaskRequest)

        } catch {
            print(error.localizedDescription)
        }
    }

    func executeSyftJob(backgroundTask: BGTask) {

        // This is a demonstration of how to use SwiftSyft with PyGrid to train a plan on local data on an iOS device
        // Get token from here on the "Model-Centric Test" notebook: https://github.com/dartmouth-cs98/artificien_experimental/blob/main/deploymentExamples/model_centric_test.ipynb
        // swiftlint:disable:next line_length
        let authToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.e30.Cn_0cSjCw1QKtcYDx_mYN_q9jO2KkpcUoiVbILmKVB4LUCQvZ7YeuyQ51r9h3562KQoSas_ehbjpz2dw1Dk24hQEoN6ObGxfJDOlemF5flvLO_sqAHJDGGE24JRE4lIAXRK6aGyy4f4kmlICL6wG8sGSpSrkZlrFLOVRJckTptgaiOTIm5Udfmi45NljPBQKVpqXFSmmb3dRy_e8g3l5eBVFLgrBhKPQ1VbNfRK712KlQWs7jJ31fGpW2NxMloO1qcd6rux48quivzQBCvyK8PV5Sqrfw_OMOoNLcSvzePDcZXa2nPHSu3qQIikUdZIeCnkJX-w0t8uEFG3DfH1fVA"
        let pyGridNodeAddress = "https://pygri-pygri-frtwp3inl2zq-2ea21a767266378c.elb.us-east-1.amazonaws.com:5000"
        
        // Create a client with a PyGrid server URL
        guard let syftClient = SyftClient(url: URL(string: pyGridNodeAddress)!, authToken: authToken) else {

            // Set background task failed if creating a client fails
            backgroundTask.setTaskCompleted(success: false)
            return
        }

        // Store the client as a property so it doesn't get deallocated during training.
        self.syftClient = syftClient

        // Create a new federated learning job with the model name and version
        self.syftJob = syftClient.newJob(modelName: "perceptron", version: "1.0")

        // This function is called when SwiftSyft has downloaded the plans and model parameters from PyGrid
        // You are ready to train your model on your data
        // plan - Use this to generate diffs using our training data
        // clientConfig - contains the configuration for the training cycle (batchSize, learning rate) and metadata for the model (name, version)
        // modelReport - Used as a completion block and reports the diffs to PyGrid.
        self.syftJob?.onReady(execute: { plan, clientConfig, modelReport in
            
            guard let age = UserDefaults.standard.object(forKey: "age") as? Int,
                  let bodyMassIndex = UserDefaults.standard.object(forKey: "bodyMassIndex") as? Double,
                  let stepCount = UserDefaults.standard.object(forKey: "stepCount") as? Double else {
                return
            }
            
            let healthData: [Any] = [age, bodyMassIndex, stepCount]

            do {
                
                // Since we don't have native tensor wrappers in Swift yet, we use `TrainingData` and `ValidationData` classes to store the data and shape.
                let healthTrainingData = try TrainingData(data: healthData, shape: [1, healthData.count])
                let healthValidationData = try ValidationData(data: healthData, shape: [1, healthData.count])
                
                // Execute the plan with the training data and validation data. `plan.execute()` returns the loss and you can use it if you want to (plan.execute() has the @discardableResult attribute)
                let loss = plan.execute(trainingData: healthTrainingData, validationData: healthValidationData, clientConfig: clientConfig)
                UserDefaults.standard.set(loss, forKey: "modelLoss")
                
                // Generate diff data and report the final diffs as
                let diffStateData = try plan.generateDiffData()
                modelReport(diffStateData)

                // Finish the background task
                backgroundTask.setTaskCompleted(success: true)

            } catch let error {

                // Handle any error from the training cycle
                debugPrint(error.localizedDescription)

                // Set the background task as failed after an error
                backgroundTask.setTaskCompleted(success: false)
            }

        })

        // This is the error handler for any job exeuction errors like connecting to PyGrid
        self.syftJob?.onError(execute: { error in
            print(error.localizedDescription)
            backgroundTask.setTaskCompleted(success: false)
        })

        // This is the error handler for being rejected in a cycle. You can retry again
        // after the suggested timeout.
        self.syftJob?.onRejected(execute: { timeout in
            if let timeout = timeout {
                // Retry again after timeout
                print(timeout)
            }
        })

        // Start the job. You can set that the job should only execute if the device is being charge and there is a WiFi connection.
        // These options are true by default if you don't specify them.
        self.syftJob?.start(chargeDetection: true, wifiDetection: true)

        // If the background task has expired,
        // we set this flag as true so that the training cycle
        // can be informed and cancel any following cycles
        backgroundTask.expirationHandler = {
            self.backgroundTaskCancelled = true
        }
    }
}

