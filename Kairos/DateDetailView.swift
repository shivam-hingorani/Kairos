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
                        "end_time": ISO8601DateFormatter().string(from: event.endDate)
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
    func sendToGPT(json: String) async -> OpenAIChatResponse? {
        let messages: [OpenAIChatMessage] = [
            OpenAIChatMessage(role: "system", content: "You are a helpful assistant that optimizes schedules based on tasks, location, and timing. Use the JSON input to re-order tasks optimally considering sleeping and eating times. Return the optimized schedule as a JSON string with the same structure."),
            OpenAIChatMessage(role: "user", content: json)
        ]
        
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

            DispatchQueue.main.async {
                print("GPT Response: \(response.choices.first?.message.content ?? "No response")")
            }

            return response
        } catch {
            print("Error sending request or parsing response: \(error.localizedDescription)")
            return nil
        }
    }

}
struct DateDetailView: View {
    @StateObject private var eventManager = EventManager()
    let selectedDate: Date

    var body: some View {
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

                Button(action: {
                    Task {
                        await eventManager.sendToGPT(json: eventManager.jsonEvents)
                    }
                }) {
                    Text("Tap Me")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }


//                Text("Events JSON:")
//                    .font(.headline)
//                    .padding(.top)
//                ScrollView {
//                    Text(eventManager.jsonEvents)
//                        .font(.body)
//                        .padding()
//                        .background(Color.gray.opacity(0.2))
//                        .cornerRadius(8)
//                }
            }
        }
        .navigationTitle(selectedDate.formatted(.dateTime.month().day().year()))
        .onAppear {
            eventManager.requestAccessToCalendar()
            eventManager.fetchEvents(for: selectedDate)
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
