//
//  ContentView.swift
//  CalTracker
//
//  Created by Shoaib Farooq on 08/12/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            CalorieInputView()
                .tabItem {
                    Label("Add Food", systemImage: "plus.circle.fill")
                }

            DailyLogView()
                .tabItem {
                    Label("Daily Log", systemImage: "list.bullet")
                }
            WeeklyStatsView()
                .tabItem {
                    Label("Weekly Stats", systemImage: "chart.bar.fill")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
