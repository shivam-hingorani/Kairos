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

    var body: some View {
        VStack {
            Text("Day View")
                .font(.largeTitle)
                .padding()
            
            HStack(spacing: 20) { // Add spacing between buttons
                Button("Add") {
                    showReorderConfirmation = true
                }
                .buttonStyle(UniformButtonStyle())

                Button("Optimize") {
                    showReorderConfirmation = true
                }
                .buttonStyle(UniformButtonStyle())
            }
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
            .frame(width: 120, height: 50) // Ensure same size for all buttons
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // Slight press effect
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
