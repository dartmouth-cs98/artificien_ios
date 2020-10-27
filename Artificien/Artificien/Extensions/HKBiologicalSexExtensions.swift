//
//  HKBiologicalSexExtensions.swift
//  Artificien
//
//  Created by Shreyas Agnihotri on 10/25/20.
//  Copyright © 2020 Shreyas Agnihotri. All rights reserved.
//

import HealthKit

extension HKBiologicalSex {
    
    var toString: String {
        switch self {
            case .notSet: return "Unknown"
            case .female: return "Female"
            case .male: return "Male"
            case .other: return "Other"
        }
    }
}