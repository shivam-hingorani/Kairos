//
//  ContentView.swift
//  Kairos
//
//  Created by Shivam Hingorani on 2/1/25.
//

import SwiftUI
import EventKit
import AVFoundation
import Speech

struct CalendarOverview: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Hello, world")
                    .font(.largeTitle)
                    .padding()
                
                NavigationLink(destination: DayView()) {
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

struct DayView: View {
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var newEventTitle = ""
    @State private var showReorderConfirmation = false

    var body: some View {
        VStack {
            // Large day number
            Text("\(Calendar.current.component(.day, from: Date()))")
                .font(.system(size: 80, weight: .bold))
                .padding(.top, 20)

            // List of events
            List(calendarManager.events, id: \.eventIdentifier) { event in
                Text(event.title)
            }

            Spacer()
            
            // Input field with rounded bubble style and mic button
            HStack {
                TextField("What else would you like to do today?", text: $newEventTitle)
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

struct ReorderConfirmation: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Text("New Order")
                .font(.largeTitle)
                .padding()
            
            HStack {
                Button("Accept") {
                    dismiss()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Decline") {
                    dismiss()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
