//
//  FoodEntry.swift
//  CalTracker
//
//  Created by Shoaib Farooq on 08/12/2025.
//

import Foundation
import SwiftData

@Model
class FoodEntry{
    var id: UUID
    var timestamp: Date
    var foodDescription: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    
    init(id: UUID = UUID(), timestamp: Date = Date(), foodDescription: String, calories: Int, protein: Double, carbs: Double, fats: Double) {
        self.id = id
        self.timestamp = timestamp
        self.foodDescription = foodDescription
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
    }
}
    
