//
//  FoodEntry.swift
//  CalTracker
//
//  Created by Shoaib Farooq on 08/12/2025.
//
import Foundation
import PhotosUI
import UIKit
import SwiftUI


class OpenAIService {
    private let apiKey = Config.openAIAPIKey
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    func analyzeFood(description: String, photoItem: PhotosPickerItem? = nil) async throws -> NutritionData {
        print("📡 API Key starts with: \(String(apiKey.prefix(10)))...")
        
        var messages: [[String: Any]] = []
        
        // Create the prompt
        let systemPrompt = """
        You are a nutrition expert familiar with UK food products and terminology. The user will describe their food and may provide a photo.

        IMPORTANT UK FOOD CONTEXT:
        - "Party pack" / "sharing bag" / "grab bag" = large 150-200g bag of crisps/snacks (~800-1000 calories)
        - "Multipack" = individual small packs, usually 25g each
        - "Meal deal" = sandwich + crisps + drink (typical from Tesco/Sainsbury's/Boots)
        - Asda, Tesco, Sainsbury's, Morrisons, Co-op = UK supermarkets
        - "Southern style" / "katsu" / "peri peri" chicken = breaded/fried/marinated (higher calories)
        - "Triple" / "double" = multiple layers/patties (estimate generously)
        - Greggs, Subway, McDonald's, KFC, Nando's = common UK chains (use their typical portion sizes)
        - "Meal" at fast food = includes sides + drink
        - "Large" portions in UK = actually quite large (don't underestimate)
        - "With sauce" = assume generous amounts (50-100g of mayo, ketchup, etc.)
        - Chocolate bars: "standard" = 45-50g, "king size" = 80-100g, "share size" = 200g+
        - "Pack of" biscuits = full pack not one biscuit (e.g., "pack of Oreos" = whole pack)

        COMMON PATTERNS:
        - "in a bun/wrap with X and Y" = ONE meal with multiple components
        - Multiple items separated by commas = likely separate meals
        - "and also" / "plus" = additional separate items
        - Brand names usually indicate separate products

        CALORIE APPROACH: Be conservative with estimates. Overestimate calories by 15-20% and use generous portion sizes when not specified. For takeaway/restaurant foods, assume extra oil, butter, cheese. UK portions are often larger than people think.

        EXAMPLES OF TYPICAL UK MEALS TO CALIBRATE YOUR ESTIMATES:
        - Large Big Mac meal (burger + large fries + large coke) = ~1350 calories
        - Greggs sausage roll = ~330 calories
        - Nando's half chicken with peri chips and garlic bread = ~1400 calories
        - Tesco meal deal (chicken sandwich + crisps + drink) = ~600-700 calories
        - Party pack Walkers crisps (200g) = ~1000 calories
        - Standard Cadbury Dairy Milk (45g) = ~240 calories
        - Large pizza (12") from Domino's = ~2000-2400 calories total

        IF AN IMAGE IS PROVIDED: Use the image to assess portion sizes, cooking methods, and ingredients. The image takes priority for portion estimation.

        Identify each meal/item, break it down into components, calculate nutrition generously, then return ONLY this JSON:

        {
            "items": [
                {
                    "name": "complete meal/item description",
                    "calories": <number>,
                    "protein": <number>,
                    "carbs": <number>,
                    "fats": <number>
                }
            ],
            "total": {
                "calories": <sum>,
                "protein": <sum>,
                "carbs": <sum>,
                "fats": <sum>
            }
        }

        Use larger typical serving sizes. When in doubt, overestimate. Return only the JSON, nothing else.
        """
        
        messages.append([
            "role": "system",
            "content": systemPrompt
        ])
        
        // Build user message with optional image
        var userContent: [[String: Any]] = [
            ["type": "text", "text": description]
        ]
        
        // If image provided, convert to base64 and add to content
        if let photoItem = photoItem {
            print("📸 Processing image...")
            if let imageData = try? await photoItem.loadTransferable(type: Data.self),
               let base64String = imageData.base64EncodedString() as String? {
                userContent.append([
                    "type": "image_url",
                    "image_url": [
                        "url": "data:image/jpeg;base64,\(base64String)"
                    ]
                ])
                print("✅ Image added to request")
            }
        }
        
        messages.append([
            "role": "user",
            "content": userContent
        ])
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 500
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("📤 Sending request to OpenAI...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Print raw response
        if let httpResponse = response as? HTTPURLResponse {
            print("📥 HTTP Status: \(httpResponse.statusCode)")
        }
        
        if let rawJSON = String(data: data, encoding: .utf8) {
            print("📥 Raw Response: \(rawJSON)")
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse JSON"])
        }
        
        print("📦 Parsed JSON keys: \(json.keys)")
        
        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response structure"])
        }
        
        print("💬 Content from API: \(content)")
        
        // Parse the JSON from content
        guard let nutritionJSON = content.data(using: .utf8),
              let responseDict = try JSONSerialization.jsonObject(with: nutritionJSON) as? [String: Any],
              let total = responseDict["total"] as? [String: Any] else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse nutrition data"])
        }
        
        print("✅ Nutrition data parsed successfully")
        
        return NutritionData(
            calories: total["calories"] as? Int ?? 0,
            protein: total["protein"] as? Double ?? 0.0,
            carbs: total["carbs"] as? Double ?? 0.0,
            fats: total["fats"] as? Double ?? 0.0
        )
    }
}

struct NutritionData {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
}
