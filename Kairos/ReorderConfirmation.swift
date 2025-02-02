//
//  ReorderConfirmation.swift
//  Kairos
//
//  Created by Shivam Hingorani on 2/1/25.
//

import SwiftUI

struct ReorderConfirmation: View {
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var eventManager = EventManager()

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.red)
                .padding(.leading)
                
                Spacer()
                
                Text("Suggestion")
                    .bold()
                    .padding([.top, .bottom])
                
                Spacer()
                
                Button("Accept") {
                    dismiss()
                }
                .bold()
                .foregroundColor(.red)
                .padding(.trailing)
            }
            
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
        }
        .presentationDetents([.large])
    }
}
