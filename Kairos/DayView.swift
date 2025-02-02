//
//  DayView.swift
//  Kairos
//
//  Created by Shivam Hingorani on 2/1/25.
//

import SwiftUI
import EventKit
import AVFoundation
import Speech

struct DayView: View {
    @StateObject private var eventManager = EventManager()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var newEventTitle = ""
    @State private var showReorderConfirmation = false
    
    let selectedDate: Date

    var body: some View {
        VStack {
            // Large day number
            Text("\(Calendar.current.component(.day, from: Date()))")
                .font(.system(size: 80, weight: .bold))
                .padding(.top, 20)
            
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

            Spacer()
            
            // Input field with rounded bubble style and mic button
            HStack {
                TextField("What would you like to accomplish today?", text: $newEventTitle)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .overlay(
                        HStack {
                            Spacer()
                            Button(action: {
                                speechRecognizer.toggleTranscription()
                            }) {
                                Image(systemName: speechRecognizer.isTranscribing ? "mic.slash.fill" : "mic.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 10)
                            }
                        }
                    )
            }
            .padding()
            .onReceive(speechRecognizer.$recognizedText) { text in
                newEventTitle = text
            }
            
            // Buttons at the Bottom
            HStack(spacing: 20) {
                Button("Add") {
                    showReorderConfirmation = true
                }
                .buttonStyle(UniformButtonStyle())
                .disabled(newEventTitle.isEmpty)
                .opacity(newEventTitle.isEmpty ? 0.5 : 1)

                Button("Optimize") {
                    showReorderConfirmation = true
                }
                .buttonStyle(UniformButtonStyle())
                .disabled(newEventTitle.isEmpty)
                .opacity(newEventTitle.isEmpty ? 0.5 : 1)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("\(DateFormatter().monthSymbols[Calendar.current.component(.month, from: Date()) - 1])")
        .onAppear {
            calendarManager.requestAccess()
        }
        .sheet(isPresented: $showReorderConfirmation) {
            ReorderConfirmation()
        }
    }
}

class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var events: [EKEvent] = []

    func requestAccess() {
        eventStore.requestAccess(to: .event) { granted, error in
            if granted {
                self.fetchEvents()
            }
        }
    }

    private func fetchEvents() {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        DispatchQueue.main.async {
            self.events = self.eventStore.events(matching: predicate)
        }
    }
}

struct UniformButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 120, height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

class SpeechRecognizer: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var recognizedText = ""
    @Published var isTranscribing = false
    
    func toggleTranscription() {
        if isTranscribing {
            stopTranscribing()
        } else {
            startTranscribing()
        }
    }
    
    func startTranscribing() {
        SFSpeechRecognizer.requestAuthorization { status in
            if status == .authorized {
                DispatchQueue.main.async {
                    self.isTranscribing = true
                }
                self.startRecognition()
            }
        }
    }
    
    private func startRecognition() {
        let node = audioEngine.inputNode
        request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let request = request else { return }
        request.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
        }
        
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
    }
    
    func stopTranscribing() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        DispatchQueue.main.async {
            self.isTranscribing = false
        }
    }
}

class EventManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var events: [EKEvent] = []
//    @Published var jsonEvents: String = "" // JSON string to store events
//    private var openAIAPIKey: String
    
    init() {
//        self.openAIAPIKey = loadAPIKey()
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
        }
    }
//    func sendToGPT(prompt: String, json: String) {
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let requestBody: [String: Any] = [
//            "model": "gpt-4",
//            "messages": [
//                ["role": "system", "content": prompt],
//                ["role": "user", "content": json]
//            ],
//            "temperature": 0.7
//        ]
//        
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
//        } catch {
//            print("Error creating request body: \(error.localizedDescription)")
//            return
//        }
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Error sending request: \(error.localizedDescription)")
//                return
//            }
//            
//            guard let data = data else {
//                print("No data received")
//                return
//            }
//            
//            do {
//                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                   let choices = jsonResponse["choices"] as? [[String: Any]],
//                   let message = choices.first?["message"] as? [String: Any],
//                   let content = message["content"] as? String {
//                    DispatchQueue.main.async {
//                        print("GPT Response: \(content)")
//                    }
//                }
//            } catch {
//                print("Error parsing GPT response: \(error.localizedDescription)")
//            }
//        }.resume()
//    }
}

//struct DateDetailView: View {
////    @StateObject private var eventManager = EventManager()
////    let selectedDate: Date
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
