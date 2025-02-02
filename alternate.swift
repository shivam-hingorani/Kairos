//import EventKit
//import Alamofire
//import SwiftUI
//import OpenAISwift
//
//func loadAPIKey() -> String {
//    if let path = Bundle.main.path(forResource: "secrets", ofType: "plist"),
//       let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
//       let apiKey = dict["OPEN_AI_KEY"] as? String {
//        return apiKey
//    }
//    return "" // Return empty string if not found
//}
//
//class EventManager: ObservableObject {
//    private let eventStore = EKEventStore()
//    @Published var events: [EKEvent] = []
//    @Published var jsonEvents: String = "" // JSON string to store events
//    private var openAIAPIKey: String
//    
//    init() {
//        self.openAIAPIKey = loadAPIKey()
//    }
//    
//    func requestAccessToCalendar(){
//        eventStore.requestAccess(to: .event){
//            success, error in
//        }
//    }
//    
//    func fetchEvents(for date: Date) {
//        let startOfDay = Calendar.current.startOfDay(for: date)
//        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
//        
//        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
//        DispatchQueue.main.async {
//            self.events = self.eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
//            print("Fetched \(self.events.count) events for \(date.formatted(.dateTime.month().day().year()))")
//            
//            // Convert events to JSON
//            let eventDictionaries = self.events.map { event in
//                [
//                    "name": event.title ?? "No Title",
//                    "location": event.location ?? "No Location",
//                    "start_time": ISO8601DateFormatter().string(from: event.startDate),
//                    "end_time": ISO8601DateFormatter().string(from: event.endDate)
//                ]
//            }
//            
//            do {
//                let jsonData = try JSONSerialization.data(withJSONObject: eventDictionaries, options: .prettyPrinted)
//                self.jsonEvents = String(data: jsonData, encoding: .utf8) ?? "Error generating JSON"
//            } catch {
//                print("Error serializing JSON: \(error.localizedDescription)")
//            }
//        }
//    }
//    private let endpointURL = "https://api.openai.com/v1/chat/completions"
//    
//    func sendToGPT(json: String) async -> OpenAIChatResponse? {
//        let messages: [OpenAIChatMessage] = [
//            OpenAIChatMessage(role:"system", content: "You are a helpful assistant that optimizes schedules based on tasks, location, and timing. Use the JSON input to re-order tasks optimally considering sleeping and eating times. Return the optimized schedule as a JSON string with the same structure."),
//            OpenAIChatMessage(role: "user", content: json)
//        ]
//        
//        let body = OpenAIChatBody(model: "gpt-4", messages: messages)
//        let headers: HTTPHeaders = [
//            "Authorization": "Bearer \(openAIAPIKey)",
//            "Content-Type": "application/json"
//        ]
//        
//        do {
//            let response = try await AF.request(endpointURL, method: .post, parameters: body, encoder: .json, headers: headers)
//                .serializingDecodable(OpenAIChatResponse.self).value
//            
//            DispatchQueue.main.async {
//                print("GPT Response: \(response.choices.first?.message.content ?? "No response")")
//            }
//            
//            return response
//        } catch {
//            print("Error sending request or parsing response: \(error.localizedDescription)")
//            return nil
//        }
//    }
//}
//
//struct DateDetailView: View {
//    @StateObject private var eventManager = EventManager()
//    let selectedDate: Date
//
//    var body: some View {
//        VStack {
//            Text("Events")
//                .font(.title)
//                .bold()
//                .padding()
//            
//            if eventManager.events.isEmpty {
//                Text("No events for this day.")
//                    .foregroundColor(.gray)
//                    .padding()
//            } else {
//                List(eventManager.events, id: \.eventIdentifier) { event in
//                    VStack(alignment: .leading) {
//                        Text(event.title)
//                            .font(.headline)
//                        Text("\(event.startDate.formatted(date: .omitted, time: .shortened))")
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                    }
//                }
//                
//                Button(action: {
//                    Task {
//                        await eventManager.sendToGPT(json: eventManager.jsonEvents)
//                    }
//                }) {
//                    Text("Tap Me")
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                }
//
//                
////                Text("Events JSON:")
////                    .font(.headline)
////                    .padding(.top)
////                ScrollView {
////                    Text(eventManager.jsonEvents)
////                        .font(.body)
////                        .padding()
////                        .background(Color.gray.opacity(0.2))
////                        .cornerRadius(8)
////                }
//            }
//        }
//        .navigationTitle(selectedDate.formatted(.dateTime.month().day().year()))
//        .onAppear {
//            eventManager.requestAccessToCalendar()
//            eventManager.fetchEvents(for: selectedDate)
//        }
//    }
//}
//
//#Preview {
//    DateDetailView(selectedDate: Date())
//}
import Foundation
import Alamofire
import EventKitUI
import SwiftUI

func loadAPIKey() -> String {
    if let path = Bundle.main.path(forResource: "secrets", ofType: "plist"),
       let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
       let apiKey = dict["OPEN_AI_KEY"] as? String {
        return apiKey
    }
    return "" // Return empty string if not found
}

struct Event: Identifiable, Decodable {
    let id = UUID()
    let name: String
    let location: String
    let start_time: String
    let end_time: String
}

struct ScheduleView: View {
    let out: String
    
    @State private var events: [Event] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else if events.isEmpty {
                    Text("No events available.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(events) { event in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(event.name)
                                .font(.headline)
                            Text("📍 \(event.location)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("🕒 \(formatTime(event.start_time)) - \(formatTime(event.end_time))")
                                .font(.footnote)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Schedule")
            .onAppear {
                parseOutString()
            }
        }
    }
    
    private func parseOutString() {
        guard let data = out.data(using: .utf8) else {
            errorMessage = "Invalid JSON string."
            return
        }
        
        do {
            events = try JSONDecoder().decode([Event].self, from: data)
        } catch {
            errorMessage = "Failed to parse JSON: \(error.localizedDescription)"
        }
    }
    
    private func formatTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: isoString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "h:mm a"  // Example: "4:00 PM"
            return displayFormatter.string(from: date)
        }
        return isoString  // Fallback to raw string if parsing fails
    }
}


class EventManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var events: [EKEvent] = []
    @Published var jsonEvents: String = "" // JSON string to store events
    private var openAIAPIKey: String
    
    init() {
        self.openAIAPIKey = loadAPIKey()
    }
    
    private let endpointURL = "https://api.openai.com/v1/chat/completions"
    
    func requestAccessToCalendar(){
            eventStore.requestAccess(to: .event){
                success, error in
            }
        }
        func fetchEvents(for date: Date) {
            let startOfDay = Calendar.current.startOfDay(for: date)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
    
            let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
            DispatchQueue.main.async {
                self.events = self.eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
                print("Fetched \(self.events.count) events for \(date.formatted(.dateTime.month().day().year()))")
    
                // Convert events to JSON
                let eventDictionaries = self.events.map { event in
                    [
                        "name": event.title ?? "No Title",
                        "location": event.location ?? "No Location",
                        "start_time": ISO8601DateFormatter().string(from: event.startDate),
                        "end_time": ISO8601DateFormatter().string(from: event.endDate),
                        "new": "false"
                    ]
                }
    
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: eventDictionaries, options: .prettyPrinted)
                    self.jsonEvents = String(data: jsonData, encoding: .utf8) ?? "Error generating JSON"
                } catch {
                    print("Error serializing JSON: \(error.localizedDescription)")
                }
            }
        }
    
//    func sendToGPT(json: String) async -> OpenAIChatResponse? {
//        let messages: [OpenAIChatMessage] = [
//            OpenAIChatMessage(role: "system", content: "You are a helpful assistant that optimizes schedules based on tasks, location, and timing. Use the JSON input to re-order tasks optimally considering sleeping and eating times. Return the optimized schedule as a JSON string with the same structure."),
//            OpenAIChatMessage(role: "user", content: json)
//        ]
//        
//        let body = OpenAIChatBody(model: "gpt-4", messages: messages)
//        let headers: HTTPHeaders = [
//            "Authorization": "Bearer \(openAIAPIKey)",
//            "Content-Type": "application/json"
//        ]
//        
//        do {
//            let response = try await AF.request(endpointURL, method: .post, parameters: body, encoder: .json, headers: headers)
//                .serializingDecodable(OpenAIChatResponse.self).value
//            
//            DispatchQueue.main.async {
//                print("GPT Response: \(response.choices.first?.message.content ?? "No response")")
//            }
//            
//            return response
//        } catch {
//            print("Error sending request or parsing response: \(error.localizedDescription)")
//            return nil
//        }
//    }
    
    func sendToGPT(flag: Int, json: String) async -> String? {
        var messages = [OpenAIChatMessage]()
        if flag == 1 {//Means that it needs reshuffling
            messages = [
                OpenAIChatMessage(role: "system", content: """
                You are a helpful assistant that optimizes schedules based on tasks, location, and timing. Use the JSON input to re-order tasks optimally considering sleeping and eating times. And change the start time and end time. After Re-ordering, the events need to be in chronological order

                ### Constraints:
                
                - Do not change the timings of existing events. Just add the new event where it is optimal
                - Return the optimized schedule as a **JSON array**, without nesting it under a `"schedule"` key.
                - Maintain the same structure as the input, ensuring each event has `"name"`, `"location"`, `"start_time"`, and `"end_time"` fields.

                ### Expected JSON Output Format:
                [
                    {
                        "name": "Advanced CG",
                        "location": "CIT 368",
                        "start_time": "2025-02-05T16:00:00Z",
                        "end_time": "2025-02-05T16:50:00Z"
                    },
                    {
                        "name": "Deep Learning",
                        "location": "Saloman Center 001",
                        "start_time": "2025-02-05T17:00:00Z",
                        "end_time": "2025-02-05T17:50:00Z"
                    }
                ]

                """),
                OpenAIChatMessage(role: "user", content: json)
            ]
        }
        else{  // Means it need just adding in empty space
            messages = [
                OpenAIChatMessage(role: "system", content: """
                You are a helpful assistant that optimizes schedules based on tasks, location, and timing. Use the JSON input to re-order tasks optimally considering sleeping and eating times. And change the start time and end time. After Re-ordering, the events need to be in chronological order

                ### Constraints:
                - if field 'new' is true, you are allowed to move event to different orders and timings.
                - Return the optimized schedule as a **JSON array**, without nesting it under a `"schedule"` key.
                - Maintain the same structure as the input, ensuring each event has `"name"`, `"location"`, `"start_time"`, and `"end_time"` fields.

                ### Expected JSON Output Format:
                [
                    {
                        "name": "Advanced CG",
                        "location": "CIT 368",
                        "start_time": "2025-02-05T16:00:00Z",
                        "end_time": "2025-02-05T16:50:00Z"
                    },
                    {
                        "name": "Deep Learning",
                        "location": "Saloman Center 001",
                        "start_time": "2025-02-05T17:00:00Z",
                        "end_time": "2025-02-05T17:50:00Z"
                    }
                ]

                """),

                OpenAIChatMessage(role: "user", content: json)
            ]
        }
        
        
        let body = OpenAIChatBody(model: "gpt-3.5-turbo", messages: messages)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(openAIAPIKey)",
            "Content-Type": "application/json"
        ]
        
        do {
            let responseData = try await AF.request(endpointURL, method: .post, parameters: body, encoder: .json, headers: headers)
                .serializingData().value

            if let jsonString = String(data: responseData, encoding: .utf8) {
                print("Raw GPT Response: \(jsonString)")
                
            }

            let response = try JSONDecoder().decode(OpenAIChatResponse.self, from: responseData)
            
            let out = response.choices.first?.message.content
            DispatchQueue.main.async {
                //out = response.choices.first?.message.content
                print("GPT Response: \(response.choices.first?.message.content ?? "No response")")
            }

            return out
        } catch {
            print("Error sending request or parsing response: \(error.localizedDescription)")
            return nil
        }
    }

}

struct ScheduleResultView: View {
    let optimizedSchedule: String


    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    if let jsonData = optimizedSchedule.data(using: .utf8),
                       let scheduleArray = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: String]] {
                        
                        ForEach(scheduleArray, id: \.self) { event in
                            VStack(alignment: .leading) {
                                Text(event["name"] ?? "No Title")
                                    .font(.headline)
                                Text("Location: \(event["location"] ?? "No Location")")
                                    .font(.subheadline)
                                Text("Start: \(formattedDate(event["start_time"] ?? ""))")
                                    .font(.subheadline)
                                Text("End: \(formattedDate(event["end_time"] ?? ""))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.bottom, 5)
                        }
                    } else {
                        Text("Invalid response format. Unable to parse schedule.")
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Optimized Schedule")
            .navigationBarItems(trailing: Button("Close") {
                UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
            })
        }
    }
    
    /// Function to format ISO 8601 date into a readable format
    func formattedDate(_ isoDate: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: isoDate) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return isoDate // Return original string if parsing fails
    }
}



import SwiftUI

import SwiftUI

struct DateDetailView: View {
    @StateObject private var eventManager = EventManager()
    @State private var showResult = false
    @State private var optimizedSchedule = ""
    
    @State private var eventName = ""
    @State private var eventLocation = ""
    @State private var eventStartDate = Date()
    @State private var eventEndDate = Date()

    let selectedDate: Date

    var body: some View {
        NavigationStack {
            VStack {
                Text("Events")
                    .font(.title)
                    .bold()
                    .padding()

                if eventManager.events.isEmpty {
                    Text("No events for this day.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(eventManager.events, id: \.eventIdentifier) { event in
                        VStack(alignment: .leading) {
                            Text(event.title)
                                .font(.headline)
                            Text("\(event.startDate.formatted(date: .omitted, time: .shortened))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }

                // User Inputs for New Event
                Form {
                    Section(header: Text("Add New Event")) {
                        TextField("Event Name", text: $eventName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Location", text: $eventLocation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        DatePicker("Start Date", selection: $eventStartDate, displayedComponents: [.date, .hourAndMinute])

                        DatePicker("End Date", selection: $eventEndDate, displayedComponents: [.date, .hourAndMinute])

                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()

                HStack {
                    Button(action: {
                        Task {
                            addEventToJSON()
                            if let response = await eventManager.sendToGPT(flag: 1, json: eventManager.jsonEvents) {
                                optimizedSchedule = response
                                showResult = true
                            }
                        }
                    }) {
                        Text("Reshuffle")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        Task {
                            // Add new event to JSON before sending it
                            addEventToJSON()

                            if let response = await eventManager.sendToGPT(flag: 0, json: eventManager.jsonEvents) {
                                optimizedSchedule = response
                                showResult = true
                            }
                        }
                    }) {
                        Text("Add") // This now also adds the event before sending
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle(selectedDate.formatted(.dateTime.month().day().year()))
            .onAppear {
                eventManager.requestAccessToCalendar()
                eventManager.fetchEvents(for: selectedDate)
            }
            .sheet(isPresented: $showResult) {
                ScheduleView(out: optimizedSchedule)
            }
        }
    }

    // Function to Convert User Input to JSON and Append
    private func addEventToJSON() {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        let newEvent: [String: String] = [
            "name": eventName,
            "location": eventLocation,
            "start_time": isoFormatter.string(from: eventStartDate),
            "end_time": isoFormatter.string(from: eventEndDate),
            "new": "true"
        ]

        // Convert JSON String to Array, Append New Event, Convert Back
        if var jsonData = eventManager.jsonEvents.data(using: .utf8) {
            do {
                var eventsArray = try JSONDecoder().decode([[String: String]].self, from: jsonData)
                eventsArray.append(newEvent)

                // Convert back to JSON string
                let updatedJsonData = try JSONEncoder().encode(eventsArray)
                eventManager.jsonEvents = String(data: updatedJsonData, encoding: .utf8) ?? ""

                print("Updated JSON: \(eventManager.jsonEvents)")
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }
    }
}




#Preview {
    DateDetailView(selectedDate: Date())
}

struct OpenAIChatBody: Encodable {
    let model: String
    let messages: [OpenAIChatMessage]
}

struct OpenAIChatMessage: Codable {
    let role: String
    let content: String
}

enum SenderRole: String, Codable {
    case system
    case user
    case assistant
}

struct OpenAIChatResponse: Decodable {
    let choices: [OpenAIChatChoice]
}

struct OpenAIChatChoice: Decodable {
    let message: OpenAIChatMessage
}
