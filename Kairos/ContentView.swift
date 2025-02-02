//
//  ContentView.swift
//  Kairos
//
//  Created by Shivam Hingorani on 2/1/25.
//

import SwiftUI

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
    @State private var showReorderConfirmation = false
    @State private var newEvent = ""
    @State private var events: [String] = ["Meeting at 10 AM", "Lunch with Alex", "Workout at 6 PM"]

    var body: some View {
        VStack {
            // Large number for the day of the month
            Text("\(Calendar.current.component(.day, from: Date()))")
                .font(.system(size: 80, weight: .bold))
                .padding(.top, 20)

            // Events List
            List {
                ForEach(events, id: \.self) { event in
                    Text(event)
                }
            }
            .frame(maxHeight: 200) // Limit the list height

            // Text Input for Adding New Events
            HStack {
                TextField("Enter new event", text: $newEvent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)

                Button("Add") {
                    if !newEvent.isEmpty {
                        events.append(newEvent)
                        newEvent = ""
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()

            Spacer()

            // Buttons at the Bottom
            HStack(spacing: 20) {
                Button("Add") {
                    showReorderConfirmation = true
                }
                .buttonStyle(UniformButtonStyle())

                Button("Optimize") {
                    showReorderConfirmation = true
                }
                .buttonStyle(UniformButtonStyle())
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Day View")
        .sheet(isPresented: $showReorderConfirmation) {
            ReorderConfirmation()
        }
    }
}

// Custom button style to ensure uniform size
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
