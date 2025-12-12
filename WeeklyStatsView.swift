//
//  FoodEntry.swift
//  CalTracker
//
//  Created by Shoaib Farooq on 08/12/2025.
//
import SwiftUI
import SwiftData
import Charts

struct WeeklyStatsView: View {
    @Query private var entries: [FoodEntry]
    
    @State private var selectedDate = Date()
    @State private var selectedDay: Date?
    @State private var showingDayDetail = false
    
    // Get current week dates
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysFromMonday = (weekday + 5) % 7 // Monday = 0
        
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: selectedDate) else {
            return []
        }
        
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: monday)
        }
    }
    
    // Get nutrition for a specific date
    private func nutritionForDate(_ date: Date) -> DayNutrition {
        let calendar = Calendar.current
        let dayEntries = entries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
        
        return DayNutrition(
            calories: dayEntries.reduce(0) { $0 + $1.calories },
            protein: dayEntries.reduce(0.0) { $0 + $1.protein },
            carbs: dayEntries.reduce(0.0) { $0 + $1.carbs },
            fats: dayEntries.reduce(0.0) { $0 + $1.fats }
        )
    }
    

    // Chart data - use actual logged calories, show macro proportions
    private var chartData: [MacroBar] {
        var data: [MacroBar] = []
        
        for date in weekDates {
            let nutrition = nutritionForDate(date)
            let dayName = date.formatted(.dateTime.weekday(.abbreviated))
            let isToday = Calendar.current.isDateInToday(date)
            
            // Calculate total macro calories to get proportions
            let totalMacroCals = (nutrition.protein * 4) + (nutrition.carbs * 4) + (nutrition.fats * 9)
            
            // If no calories logged, show empty bars
            if nutrition.calories == 0 || totalMacroCals == 0 {
                // Add placeholder bars with 0 height
                data.append(MacroBar(
                    date: date,
                    dayName: dayName,
                    macroType: "Protein",
                    calories: 0,
                    color: .green,
                    isToday: isToday
                ))
                continue
            }
            
            // Use actual logged calories, split proportionally by macros
            let actualCalories = Double(nutrition.calories)
            
            let proteinProportion = (nutrition.protein * 4) / totalMacroCals
            let carbsProportion = (nutrition.carbs * 4) / totalMacroCals
            let fatsProportion = (nutrition.fats * 9) / totalMacroCals
            
            // Create 3 bars per day with proportional calories
            data.append(MacroBar(
                date: date,
                dayName: dayName,
                macroType: "Protein",
                calories: actualCalories * proteinProportion,
                color: .green,
                isToday: isToday
            ))
            
            data.append(MacroBar(
                date: date,
                dayName: dayName,
                macroType: "Carbs",
                calories: actualCalories * carbsProportion,
                color: .orange,
                isToday: isToday
            ))
            
            data.append(MacroBar(
                date: date,
                dayName: dayName,
                macroType: "Fats",
                calories: actualCalories * fatsProportion,
                color: .red,
                isToday: isToday
            ))
        }
        
        return data
    }
    
    // For the daily breakdown list
    private var dayData: [DayData] {
        weekDates.map { date in
            let nutrition = nutritionForDate(date)
            return DayData(
                date: date,
                nutrition: nutrition,
                dayName: date.formatted(.dateTime.weekday(.abbreviated))
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header - COMPACT
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weekly Stats")
                            .font(.headline)
                            .bold()
                        Text("Track your weekly progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Week selector
                        HStack {
                            Button(action: { previousWeek() }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                            }
                            
                            Spacer()
                            
                            Text(weekRangeText())
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: { nextWeek() }) {
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                            }
                            .disabled(isCurrentWeek())
                        }
                        .padding()
                        
                        // Stacked bar chart showing macros
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Daily Nutrition Breakdown")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Chart(chartData) { item in
                                BarMark(
                                    x: .value("Day", item.dayName),
                                    y: .value("Calories", item.calories)
                                )
                                .foregroundStyle(by: .value("Macro", item.macroType))
                                .opacity(item.isToday ? 1.0 : 0.7)
                            }
                            .chartForegroundStyleScale([
                                "Protein": Color.green,
                                "Carbs": Color.orange,
                                "Fats": Color.red
                            ])
                            .frame(height: 250)
                            .padding(.horizontal)
                            
                            // Legend
                            HStack(spacing: 20) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 10, height: 10)
                                    Text("Protein")
                                        .font(.caption)
                                }
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 10, height: 10)
                                    Text("Carbs")
                                        .font(.caption)
                                }
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                    Text("Fats")
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Daily breakdown - CLICKABLE
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Daily Breakdown")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(dayData, id: \.date) { day in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(day.date.formatted(.dateTime.weekday(.wide)))
                                            .font(.subheadline)
                                            .bold()
                                        Text(day.date.formatted(.dateTime.month().day()))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(day.nutrition.calories) kcal")
                                        .font(.headline)
                                        .foregroundColor(day.nutrition.calories > 0 ? .primary : .secondary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(
                                    Calendar.current.isDateInToday(day.date) ?
                                    Color.blue.opacity(0.1) : Color.clear
                                )
                                .cornerRadius(10)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedDay = day.date
                                    showingDayDetail = true
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Weekly average
                        VStack(spacing: 8) {
                            Text("Weekly Average")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(weeklyAverage()) kcal/day")
                                .font(.title2)
                                .bold()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingDayDetail) {
                if let day = selectedDay {
                    DayDetailView(date: day, nutrition: nutritionForDate(day))
                }
            }
        }
    }
    
    private func previousWeek() {
        guard let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) else { return }
        selectedDate = newDate
    }
    
    private func nextWeek() {
        guard let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) else { return }
        selectedDate = newDate
    }
    
    private func isCurrentWeek() -> Bool {
        Calendar.current.isDate(selectedDate, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    private func weekRangeText() -> String {
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }
    
    private func weeklyAverage() -> Int {
        let total = dayData.reduce(0) { $0 + $1.nutrition.calories }
        return total / 7
    }
}

// Day detail sheet
struct DayDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let nutrition: DayNutrition
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Date header
                VStack(spacing: 4) {
                    Text(date.formatted(.dateTime.weekday(.wide)))
                        .font(.title2)
                        .bold()
                    Text(date.formatted(.dateTime.month().day().year()))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Big calorie number
                VStack(spacing: 8) {
                    Text("\(nutrition.calories)")
                        .font(.system(size: 60, weight: .bold))
                    Text("calories")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Divider()
                
                // Macros breakdown
                VStack(spacing: 16) {
                    MacroRow(
                        name: "Protein",
                        grams: nutrition.protein,
                        calories: Int(nutrition.protein * 4),
                        color: .green
                    )
                    
                    MacroRow(
                        name: "Carbs",
                        grams: nutrition.carbs,
                        calories: Int(nutrition.carbs * 4),
                        color: .orange
                    )
                    
                    MacroRow(
                        name: "Fats",
                        grams: nutrition.fats,
                        calories: Int(nutrition.fats * 9),
                        color: .red
                    )
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MacroRow: View {
    let name: String
    let grams: Double
    let calories: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.headline)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(grams, specifier: "%.1f")g")
                    .font(.headline)
                Text("\(calories) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct MacroBar: Identifiable {
    let id = UUID()
    let date: Date
    let dayName: String
    let macroType: String
    let calories: Double
    let color: Color
    let isToday: Bool
}

struct DayData: Identifiable {
    let id = UUID()
    let date: Date
    let nutrition: DayNutrition
    let dayName: String
}

struct DayNutrition {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
}

#Preview {
    WeeklyStatsView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
