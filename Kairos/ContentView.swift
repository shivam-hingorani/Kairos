//
//  ContentView.swift
//  Kairos
//
//  Created by Shivam Hingorani on 2/1/25.
//

import SwiftUI
import EventKit

class CalendarViewModel: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var events: [EKEvent] = []
    
    init() {
        requestAccess()
    }
    
    private func requestAccess() {
        eventStore.requestFullAccessToEvents { granted, error in
            if granted {
                DispatchQueue.main.async {
                    self.fetchEvents()
                }
            } else {
                print("Access denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func fetchEvents() {
        let calendars = eventStore.calendars(for: .event)
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        
        self.events = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = CalendarViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.events, id: \.eventIdentifier) { event in
                VStack(alignment: .leading) {
                    Text(event.title)
                        .font(.headline)
                    Text("\(event.startDate, style: .date) at \(event.startDate, style: .time)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Today's Events")
        }
    }
}

#Preview {
    ContentView()
}
