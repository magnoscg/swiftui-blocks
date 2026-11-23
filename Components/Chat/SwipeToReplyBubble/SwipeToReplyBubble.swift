// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A message bubble that can be dragged toward the trailing edge to reply to it.
///
/// A reply arrow appears behind the bubble as it moves, and the phone taps once when the drag
/// passes ``threshold``. Letting go past it calls ``onReply``, and the bubble springs back
/// either way. Only a mostly horizontal drag moves the bubble, so the conversation still
/// scrolls. VoiceOver offers the same as a Reply action, and with Reduce Motion the bubble
/// returns without a spring. In a right-to-left layout the drag goes the other way.
struct SwipeToReplyBubble<Content: View>: View {
    /// How far the bubble has to travel, in points, for letting go to reply.
    var threshold: CGFloat = 64
    /// What happens when the message is replied to.
    let onReply: () -> Void
    /// The bubble.
    @ViewBuilder let content: () -> Content

    @GestureState private var translation: CGFloat = 0
    /// Where the drag that moves the bubble began: the bubble keeps following it, and only it can reply.
    @State private var engagedDrag: CGPoint?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    /// Gestures report screen points, but layout mirrors in right-to-left layouts: 1 or -1 converts between them.
    private var forward: CGFloat { layoutDirection == .rightToLeft ? -1 : 1 }
    private var progress: CGFloat { SwipeToReplyBubblePhysics.progress(for: translation, threshold: threshold) }
    private var isPastThreshold: Bool { SwipeToReplyBubblePhysics.replies(after: translation, threshold: threshold) }

    var body: some View {
        content()
            .offset(x: SwipeToReplyBubblePhysics.offset(for: translation, threshold: threshold))
            .background(alignment: .leading) { arrow }
            .simultaneousGesture(swipe)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: isPastThreshold) { wasPast, isPast in
                !wasPast && isPast
            }
            .animation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.3), value: translation == 0)
            .accessibilityAction(named: "Reply", onReply)
    }

    private var arrow: some View {
        Image(systemName: "arrowshape.turn.up.backward.fill")
            .font(.body.weight(.semibold))
            .foregroundStyle(isPastThreshold ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .padding(8)
            .background(.fill.tertiary, in: .circle)
            .scaleEffect(reduceMotion ? 1 : 0.5 + progress / 2)
            .opacity(progress)
            .accessibilityHidden(true)
    }

    private var swipe: some Gesture {
        // In global space the start of a drag stays put while the conversation scrolls under it.
        DragGesture(minimumDistance: 14, coordinateSpace: .global)
            .updating($translation) { value, state, _ in
                if engagedDrag == value.startLocation || SwipeToReplyBubblePhysics.engages(value.translation) {
                    state = value.translation.width * forward
                }
            }
            .onChanged { value in
                if engagedDrag != value.startLocation, SwipeToReplyBubblePhysics.engages(value.translation) {
                    engagedDrag = value.startLocation
                }
            }
            .onEnded { value in
                defer { engagedDrag = nil }
                guard engagedDrag == value.startLocation,
                      SwipeToReplyBubblePhysics.replies(after: value.translation.width * forward, threshold: threshold)
                else { return }
                onReply()
            }
    }
}

/// How a ``SwipeToReplyBubble`` follows a drag, measured toward the trailing edge.
nonisolated enum SwipeToReplyBubblePhysics {
    /// Whether a drag goes mostly sideways, which is what moves the bubble.
    static func engages(_ translation: CGSize) -> Bool {
        abs(translation.width) > abs(translation.height)
    }

    /// How far the bubble moves for a drag: with the finger up to the threshold, then with
    /// growing resistance, and never toward the leading edge.
    static func offset(for translation: CGFloat, threshold: CGFloat) -> CGFloat {
        guard translation > 0, threshold > 0 else { return 0 }
        guard translation > threshold else { return translation }
        let excess = translation - threshold
        return threshold + excess / (1 + excess / threshold)
    }

    /// How far a drag has gone toward replying, from 0 to 1.
    static func progress(for translation: CGFloat, threshold: CGFloat) -> CGFloat {
        guard threshold > 0 else { return 0 }
        return min(max(translation / threshold, 0), 1)
    }

    /// Whether letting go after a drag replies.
    static func replies(after translation: CGFloat, threshold: CGFloat) -> Bool {
        threshold > 0 && translation >= threshold
    }
}

// MARK: - Demo

struct SwipeToReplyBubbleDemo: View {
    private struct Message: Identifiable {
        let id: Int
        let text: String
        let isOutgoing: Bool
        var quote: String?
    }

    @State private var messages = [
        Message(id: 1, text: "Are we still on for the hike on Saturday?", isOutgoing: false),
        Message(id: 2, text: "Yes! I found a trail with a lake at the top.", isOutgoing: true),
        Message(id: 3, text: "Perfect. How long is it?", isOutgoing: false),
        Message(id: 4, text: "About three hours there and back.", isOutgoing: true),
        Message(id: 5, text: "Should I bring lunch for both of us?", isOutgoing: false),
        Message(id: 6, text: "I'll bring the sandwiches, you bring the snacks.", isOutgoing: true),
        Message(id: 7, text: "Deal. Meet at the station at eight?", isOutgoing: false),
    ]
    @State private var replyingTo: Message?
    @State private var draft = ""
    @FocusState private var isComposing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        SwipeToReplyBubble {
                            replyingTo = message
                            isComposing = true
                        } content: {
                            bubble(message)
                        }
                        .frame(maxWidth: .infinity, alignment: message.isOutgoing ? .trailing : .leading)
                    }
                }
                .padding(16)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)

            composer
        }
        .animation(reduceMotion ? nil : .snappy, value: replyingTo?.id)
    }

    private func bubble(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let quote = message.quote {
                Text(quote)
                    .font(.footnote)
                    .lineLimit(2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.2), in: .rect(cornerRadius: 10))
            }

            Text(message.text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .foregroundStyle(message.isOutgoing ? .white : .primary)
        .background(message.isOutgoing ? Color.blue : Color(uiColor: .secondarySystemBackground), in: .rect(cornerRadius: 18))
        .frame(maxWidth: 300, alignment: message.isOutgoing ? .trailing : .leading)
    }

    private var composer: some View {
        VStack(spacing: 10) {
            if let replyingTo {
                HStack(spacing: 10) {
                    Capsule()
                        .fill(.blue)
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(replyingTo.isOutgoing ? "Replying to yourself" : "Replying to Maya")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)

                        Text(replyingTo.text)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Button("Cancel reply", systemImage: "xmark.circle.fill") {
                        self.replyingTo = nil
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                    .padding(13)
                    .contentShape(.rect)
                    .padding(-13)
                }
                .fixedSize(horizontal: false, vertical: true)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                TextField("Message", text: $draft)
                    .focused($isComposing)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .secondarySystemBackground), in: .capsule)
                    .onSubmit(send)

                Button("Send", systemImage: "arrow.up.circle.fill", action: send)
                    .labelStyle(.iconOnly)
                    .font(.title)
                    .disabled(draft.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func send() {
        guard !draft.isEmpty else { return }
        messages.append(Message(id: messages.count + 1, text: draft, isOutgoing: true, quote: replyingTo?.text))
        draft = ""
        replyingTo = nil
    }
}

#Preview {
    SwipeToReplyBubbleDemo()
}
