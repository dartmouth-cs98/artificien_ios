# Artificien: iOS

This is the main proof-of-concept mobile companion to the Artificien platform. This repo stores a demo application that stores user health data from Apple Health and exposes it to the Artificien platform for learning/analysis using the Artificien CocoaPod. The app is deployed on TestFlight and available for users to send models towards on the Artificien website.

Download the app here: https://testflight.apple.com/join/Z6FKIuIw

<img src="./latestScreenshot.png" width="300">

## Architecture

This application is built in Swift with a StoryBoard UI scheme.

The following CocoaPods packages are utilized:
* *Artificien:* Artificien's [open source](https://github.com/dartmouth-cs98/artificien_ios_library) package that fetches relevant models and conducts on-device training
* *NVActivityIndicatorView:* Loading spinner animation

The app has the following file structure (only key files are shown):
```
├──Artificien/                                    # root directory
|  └──Artificen/                                  # stores all project code files
|    └──HealthKitCalls.swift                      # Central wrapper for all interfacing with Apple Health services
|    └──Controllers/                              # View controllers
|      └──HealthDataTableViewController.swift     # UI and logic for main health data table
|    └──Models/                                   # Data models
|    └──Views/                                    # UI and launch screen storyboards
|  └──Artificien.xcworkspace                      # CocoaPods XCode workspace: open this to access project editor
|  └──fastlane/                                   # configurations and certificates for TestFlight deployment
```

## Setup

* Download XCode
* `cd Artificien` and `pod install`
* Open the `.xcworkspace` file to bring up the project editor
* Run the project on an iOS simulator with `Cmd` + `R` or by selecting the play icon at the top left of the XCode editor

## Deployment

`fastlane ios beta` deploys the app to TestFlight. Go to the App Store Connect console to handle distribution.

## Authors

Shreyas Agnihotri, '21

## Acknowledgments

This app wouldn't be possible without the contributors at OpenMined working to create a secure federated learning architecture.

Thanks to Tim Tregubov for letting us distribute the app through the BrunchLabs account and for his help in debugging.
