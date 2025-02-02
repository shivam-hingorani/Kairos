import EventKit
import SwiftUI

func loadAPIKey() -> String {
    if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
       let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
       let apiKey = dict["OPENAI_API_KEY"] as? String {
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
    func sendToGPT(prompt: String, json: String) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": prompt],
                ["role": "user", "content": json]
            ],
            "temperature": 0.7
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            print("Error creating request body: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending request: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    DispatchQueue.main.async {
                        print("GPT Response: \(content)")
                    }
                }
            } catch {
                print("Error parsing GPT response: \(error.localizedDescription)")
            }
        }.resume()
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
