//
//  CalendarOverview.swift
//  Kairos
//
//  Created by Shivam Hingorani and Varun Satheesh on 2/1/25.
//

import SwiftUI
import Foundation

struct CalendarOverview: View {
    @State private var color: Color = .red
    @State private var date = Date.now
    let daysOfWeek = Date.capitalizedFirstLettersOfWeekdays
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    @State private var days: [Date] = []
    
    var body: some View {
        NavigationView {
            VStack {
                LabeledContent("Month/Year") {
                    DatePicker("", selection: $date, displayedComponents: [.date]) // Adjusted to show only month/year
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                .padding()
                
                HStack {
                    ForEach(daysOfWeek.indices, id: \.self) { index in
                        Text(daysOfWeek[index])
                            .fontWeight(.bold)
                            .foregroundStyle(.black) // Days of the week in black
                            .frame(maxWidth: .infinity)
                    }
                }
                
                VStack(spacing: 10) { // Increased spacing between rows
                    ForEach(days.chunked(into: 7), id: \.self) { row in
                        HStack(spacing: 0) { // Wrap each row inside a HStack
                            ForEach(row, id: \.self) { day in
                                if day.getMonthInt() != date.getMonthInt() {
                                    Text("")
                                        .frame(maxWidth: .infinity, minHeight: 60) // Increased height for empty cells
                                } else {
                                    NavigationLink(destination: DayView(selectedDate: day)) {
                                        Text(day.formatted(.dateTime.day()))
                                            .fontWeight(.bold)
                                            .foregroundStyle(
                                                // First, check if it's today and apply the red circle with white text
                                                day.startOfDay == Date.now.startOfDay ? .white : // White text for today's date
                                                (day.isWeekend() ? .gray : .black) // Gray text for weekends, black for weekdays
                                            )
                                            .frame(maxWidth: .infinity, minHeight: 60) // Increased height for each day cell
                                            .background(
                                                // Apply a circle only if it's today
                                                day.startOfDay == Date.now.startOfDay ?
                                                Circle()
                                                    .foregroundStyle(.red) // Full opacity for today
                                                    .overlay(
                                                        Text(day.formatted(.dateTime.day()))
                                                            .fontWeight(.bold)
                                                            .foregroundStyle(.white) // White text inside red circle
                                                    ) : nil
                                            )
                                    }
                                }
                            }
                            // Add blank cells if there are fewer than 7 days in the last row
                            if row.count < 7 {
                                ForEach(row.count..<7, id: \.self) { _ in
                                    Text("")
                                        .frame(maxWidth: .infinity, minHeight: 60) // Empty cells to fill the row
                                }
                            }
                        }
                        if row != days.chunked(into: 7).last { // Avoid a divider after the last row
                            Divider()
                                .background(Color.gray.opacity(0.2)) // Light gray divider
                        }
                    }
                }
            }
            .padding()
            .onAppear {
                days = date.calendarDisplayDaysWithOffset()
            }
            .onChange(of: date) { _ in
                days = date.calendarDisplayDaysWithOffset()
            }
            .navigationTitle("My Schedule")
        }
    }
}

extension Date {
    static var capitalizedFirstLettersOfWeekdays: [String] {
        let formatter = DateFormatter()
        return formatter.shortWeekdaySymbols.map { $0.capitalized }
    }
    
    func calendarDisplayDaysWithOffset() -> [Date] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: self) else { return [] }
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let paddingDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date] = []
        for i in -paddingDays..<range.count {
            if let day = calendar.date(byAdding: .day, value: i, to: startOfMonth) {
                days.append(day)
            }
        }
        return days
    }
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    func getMonthInt() -> Int {
        return Calendar.current.component(.month, from: self)
    }
    
    func isWeekend() -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        return weekday == 1 || weekday == 7 // 1 = Sunday, 7 = Saturday
    }
}

extension Array {
    // Helper function to chunk the days array into rows of 7
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)]) // Ensure the index doesn't go out of bounds
        }
    }
}
