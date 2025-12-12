//
//  UserProfile.swift
//  CalTracker
//
//  Created by Shoaib Farooq on 12/12/2025.
//

import Foundation
import SwiftData

@Model
class UserProfile {
    var id: UUID
    var username: String
    var pin: String // Simple 4-digit PIN for now
    var dailyCalorieGoal: Int
    var createdAt: Date
    
    init(username: String, pin: String, dailyCalorieGoal: Int = 2000) {
        self.id = UUID()
        self.username = username
        self.pin = pin
        self.dailyCalorieGoal = dailyCalorieGoal
        self.createdAt = Date()
    }
}
