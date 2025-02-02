//
//  DayView.swift
//  Kairos
//
//  Created by Shivam Hingorani and Varun Satheesh on 2/1/25.
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
            // Display selected date
            VStack {
                Text(getMonthName(from: selectedDate))
                    .font(.system(size: 20, weight: .bold))
                
                Text("\(Calendar.current.component(.day, from: selectedDate))")
                    .font(.system(size: 80, weight: .bold))
            }
            .padding()
            
            if eventManager.events.isEmpty {
                Text("No events for this day.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(eventManager.events, id: \.eventIdentifier) { event in
                    VStack(alignment: .leading) {
                        Text(event.title ?? "No Title")
                            .font(.headline)
                        Text("\(event.startDate.formatted(date: .omitted, time: .shortened))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            HStack {
                TextField("What will you accomplish today?", text: $newEventTitle)
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
        .onAppear {
            print("Fetching events for \(selectedDate)")
            calendarManager.requestAccess(for: selectedDate)  // Pass the selected date here
            eventManager.fetchEvents(for: selectedDate)      // You already pass the selected date here
        }
        .sheet(isPresented: $showReorderConfirmation) {
            ReorderConfirmation()
        }
    }
}

class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var events: [EKEvent] = []

    func requestAccess(for date: Date) {
        eventStore.requestAccess(to: .event) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    print("Calendar access granted for \(date.formatted(.dateTime.month().day().year()))")
                    self.fetchEvents(for: date)
                }
            } else {
                DispatchQueue.main.async {
                    if let error = error {
                        print("Calendar access denied or error: \(error.localizedDescription)")
                    } else {
                        print("Calendar access denied.")
                    }
                }
            }
        }
    }

    func fetchEvents(for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        
        DispatchQueue.main.async {
            self.events = self.eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
            print("Fetched \(self.events.count) events for \(date.formatted(.dateTime.month().day().year()))")
            
            // Debugging events
            for event in self.events {
                print("Event: \(event.title ?? "No Title") at \(event.startDate)")
            }
        }
    }
}

struct UniformButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .bold()
            .frame(width: 120, height: 50)
            .background(Color.red)
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

    init() {
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
        }
    }
}

// Function to get the month name
func getMonthName(from date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM"  // This gives the full month name
    return dateFormatter.string(from: date)
}
