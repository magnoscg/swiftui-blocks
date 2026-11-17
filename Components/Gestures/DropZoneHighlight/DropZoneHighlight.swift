// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A drop target that lights up and shows a hint while something hovers over it.
///
/// `onDrop` returns whether the drop was accepted. With Reduce Motion on, the
/// highlight changes color without growing.
struct DropZoneHighlight<Payload: Transferable>: View {
    /// The text shown while nothing hovers over the zone.
    var title: LocalizedStringResource = "Drop here"
    /// The text that replaces `title` while something hovers over the zone.
    var hint: LocalizedStringResource = "Release to add"
    /// The SF Symbol above the text.
    var systemImage = "tray.and.arrow.down"
    /// The color of the icon, the text and the dashed border, and the fill while something hovers, when the text turns white.
    var tint: Color = .blue
    /// Called with the dropped items, never empty. Returns whether the drop was accepted.
    var onDrop: ([Payload]) -> Bool

    @State private var isTargeted = false
    @ScaledMetric(relativeTo: .headline) private var minimumHeight = 150.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .accessibilityHidden(true)
            Text(isTargeted ? hint : title)
                .font(.headline)
                .contentTransition(.opacity)
        }
        .foregroundStyle(isTargeted ? .white : tint)
        .frame(maxWidth: .infinity, minHeight: minimumHeight)
        .padding()
        .background(isTargeted ? tint : tint.opacity(0.1), in: shape)
        .overlay {
            shape.strokeBorder(tint, style: StrokeStyle(lineWidth: 2, dash: isTargeted ? [] : [8, 6]))
        }
        .scaleEffect(isTargeted && !reduceMotion ? 1.04 : 1)
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.3, bounce: 0.35), value: isTargeted)
        .contentShape(shape)
        .dropDestination(for: Payload.self) { items, _ in
            guard !items.isEmpty else { return false }
            return onDrop(items)
        } isTargeted: { targeted in
            isTargeted = targeted
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Demo

struct DropZoneHighlightDemo: View {
    private static let files = ["Report.pdf", "Photo.heic", "Notes.txt", "Budget.xlsx"]
    @State private var waiting = files
    @State private var dropped: [String] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Files")
                        .font(.largeTitle.bold())

                    ForEach(waiting, id: \.self) { name in
                        chip(name)
                            // Without it the preview of the drag is the chip on a white rectangle.
                            .contentShape(.dragPreview, .capsule)
                            .draggable(name)
                            .accessibilityAction(named: "Add to the box") { add([name]) }
                    }

                    DropZoneHighlight<String> { items in
                        add(items)
                        return true
                    }

                    Text(dropped.isEmpty ? "Nothing in the box yet" : "In the box: \(dropped.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Only for this demo: a way back once every file is in the box.
                    if waiting.isEmpty {
                        Button("Start over") {
                            withAnimation(reduceMotion ? nil : .snappy) {
                                waiting = Self.files
                                dropped = []
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(24)
            }
        }
    }

    private func add(_ items: [String]) {
        withAnimation(reduceMotion ? nil : .snappy) {
            waiting.removeAll(where: items.contains)
            dropped.append(contentsOf: items)
        }
    }

    private func chip(_ name: String) -> some View {
        Label(name, systemImage: "doc.fill")
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.background, in: .capsule)
    }
}

#Preview {
    DropZoneHighlightDemo()
}
