//
//  KairosApp.swift
//  Kairos
//
//  Created by Varun Satheesh on 01/02/25.
//

import SwiftUI
import EventKit




class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var events: [EKEvent] = []
    @Published var selectedCalendar: EKCalendar?

    func requestAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
                if granted {
                    self.fetchEvents()
                }
            }
        }
    }

    func fetchEvents() {
        guard let selectedCalendar = selectedCalendar else { return }
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [selectedCalendar])
        
        DispatchQueue.main.async {
            self.events = self.eventStore.events(matching: predicate)
        }
    }
}


