// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// An empty screen with a breathing symbol, a message and an optional call to action.
///
/// With Reduce Motion on, the symbol stays still.
struct EmptyStatePlaceholder: View {
    /// The SF Symbol above the title. It breathes unless Reduce Motion is on.
    var systemImage: String
    /// The headline, like "No messages".
    var title: LocalizedStringResource
    /// The line below the title that explains why it is empty or what to do.
    var message: LocalizedStringResource
    /// The text of the prominent button. The button shows only when this and `action` are both set.
    var actionTitle: LocalizedStringResource?
    /// Runs when the button is tapped. The button shows only when this and `actionTitle` are both set.
    var action: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .symbolEffect(.breathe, isActive: !reduceMotion)
            }
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Demo

struct EmptyStatePlaceholderDemo: View {
    @State private var messages: [String] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if messages.isEmpty {
                EmptyStatePlaceholder(
                    systemImage: "tray",
                    title: "No messages",
                    message: "New conversations will show up here.",
                    actionTitle: "Load samples"
                ) {
                    withAnimation(reduceMotion ? nil : .snappy) {
                        messages = ["Welcome aboard", "Your invoice is ready", "Lunch on Friday?"]
                    }
                }
                .transition(.opacity)
            } else {
                List {
                    ForEach(messages, id: \.self) { message in
                        Label(message, systemImage: "envelope")
                    }
                    Button("Clear all", role: .destructive) {
                        withAnimation(reduceMotion ? nil : .snappy) { messages = [] }
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    EmptyStatePlaceholderDemo()
}
