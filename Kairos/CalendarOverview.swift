//
//  CalendarOverview.swift
//  Kairos
//
//  Created by Shivam Hingorani on 2/1/25.
//

import SwiftUI
//import Foundation

//struct CalendarView: View {
//    @State private var color: Color = .blue
//    @State private var date = Date.now
//    let daysOfWeek = capitalizedFirstLettersOfWeekdays()
//    let columns = Array(repeating: GridItem(.flexible()), count: 7)
//    @State private var days: [Date] = []
//    
//    var body: some View {
//        NavigationView { // Wrap in NavigationView for navigation functionality
//            VStack {
//                LabeledContent("Calendar Color") {
//                    ColorPicker("", selection: $color, supportsOpacity: false)
//                }
//                LabeledContent("Date/Time") {
//                    DatePicker("", selection: $date)
//                }
//                HStack {
//                    ForEach(daysOfWeek.indices, id: \.self) { index in
//                        Text(daysOfWeek[index])
//                            .fontWeight(.black)
//                            .foregroundStyle(color)
//                            .frame(maxWidth: .infinity)
//                    }
//                }
//                LazyVGrid(columns: columns) {
//                    ForEach(days, id: \.self) { day in
//                        if day.monthInt != date.monthInt {
//                            Text("")
//                        } else {
//                            NavigationLink(destination: DateDetailView(selectedDate: day)) { // Navigate to new view
//                                Text(day.formatted(.dateTime.day()))
//                                    .fontWeight(.bold)
//                                    .foregroundStyle(.secondary)
//                                    .frame(maxWidth: .infinity, minHeight: 40)
//                                    .background(
//                                        Circle()
//                                            .foregroundStyle(
//                                                Date.now.startOfDay == day.startOfDay
//                                                ? .red.opacity(0.3)
//                                                : color.opacity(0.3)
//                                            )
//                                    )
//                            }
//                        }
//                    }
//                }
//            }
//            .padding()
//            .onAppear {
//                days = date.calendarDisplayDays
//            }
//            .onChange(of: date) {
//                days = date.calendarDisplayDays
//            }
//            .navigationTitle("Custom Calendar") // Add a title for the navigation bar
//        }
//    }
//}
//
//func capitalizedFirstLettersOfWeekdays() -> [String] {
//    let dateFormatter = DateFormatter()
//    dateFormatter.locale = Locale(identifier: "en_US") // Set locale to US English
//    let weekdays = dateFormatter.weekdaySymbols // Get full weekday names
//    
//    // Capitalize the first letter of each weekday name
//    return weekdays.map { $0.prefix(1).capitalized + $0.dropFirst() }
//}

struct CalendarOverview: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Hello, world")
                    .font(.largeTitle)
                    .padding()
                
                NavigationLink(destination: DayView(selectedDate: Date())) {
                    Text("Tap me")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}
