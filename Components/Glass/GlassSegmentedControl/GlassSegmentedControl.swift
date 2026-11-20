// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A segmented control with a Liquid Glass thumb that slides between segments.
///
/// With Reduce Motion on, the thumb jumps to the new segment.
@available(iOS 26, *)
struct GlassSegmentedControl<Segment: Hashable>: View {
    /// The options, from leading to trailing, each given the same width.
    let segments: [Segment]
    /// The selected segment. The control writes it on a tap, or as a finger drags along it.
    @Binding var selection: Segment
    /// A tint for the glass thumb, or nil for plain glass.
    var tint: Color?
    /// Returns the text shown for a segment, kept to one line.
    let title: (Segment) -> LocalizedStringResource

    @ScaledMetric(relativeTo: .subheadline) private var height = 44.0
    @State private var width: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        HStack(spacing: 0) {
            ForEach(segments, id: \.self) { segment in
                button(for: segment)
            }
        }
        .background { thumb }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        // The thumb follows a finger dragged along the control, as the system's does.
        .simultaneousGesture(DragGesture(minimumDistance: 10).onChanged { select(at: $0.location.x) })
        .padding(4)
        .background(.ultraThinMaterial, in: .capsule)
        .sensoryFeedback(.selection, trigger: selection)
    }

    /// One view that moves, drawn behind the labels so they stay readable on top of it.
    private var thumb: some View {
        GeometryReader { proxy in
            let width = proxy.size.width / CGFloat(max(segments.count, 1))
            let index = segments.firstIndex(of: selection) ?? 0

            Color.clear
                .frame(width: width)
                .glassEffect(.regular.tint(tint), in: .capsule)
                .offset(x: width * CGFloat(index))
        }
    }

    private func select(at x: CGFloat) {
        guard width > 0, !segments.isEmpty else { return }
        // A gesture reports screen points, and a right-to-left layout counts from the other edge.
        let leading = layoutDirection == .rightToLeft ? width - x : x
        let index = min(max(Int(leading / width * CGFloat(segments.count)), 0), segments.count - 1)
        guard segments[index] != selection else { return }
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.4)) {
            selection = segments[index]
        }
    }

    private func button(for segment: Segment) -> some View {
        let isSelected = segment == selection

        return Button {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.4)) {
                selection = segment
            }
        } label: {
            Text(title(segment))
                .font(.subheadline.weight(isSelected ? .semibold : .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: height)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct GlassSegmentedControlDemo: View {
    private enum Period: CaseIterable {
        case day, week, month, year

        var title: LocalizedStringResource {
            switch self {
            case .day: "Day"
            case .week: "Week"
            case .month: "Month"
            case .year: "Year"
            }
        }

        var steps: Int {
            switch self {
            case .day: 8_214
            case .week: 61_730
            case .month: 248_902
            case .year: 2_904_117
            }
        }
    }

    @State private var period = Period.week
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(colors: [.teal, .blue, .indigo], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 4) {
                    Text("Steps walked")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))

                    Text(period.steps, format: .number)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .contentTransition(.numericText())
                        .foregroundStyle(.white)
                        .animation(reduceMotion ? nil : .snappy, value: period)
                }

                GlassSegmentedControl(segments: Period.allCases, selection: $period) { $0.title }
                    .padding(.horizontal, 24)
            }
        }
    }
}

@available(iOS 26, *)
#Preview {
    GlassSegmentedControlDemo()
}
