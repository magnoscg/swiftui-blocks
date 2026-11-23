// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A box to sign with a finger over a baseline, with a button that clears it.
///
/// The ink follows the finger with rounded, smoothed lines. A signature counts once its ink adds up
/// to ``SignaturePadStrokes/isSigned(_:minimumLength:)``, so a stray tap does not. VoiceOver reads the
/// prompt and whether the pad is signed, and lets its user sign with direct touch.
/// ``SignaturePadStrokes/image(of:ink:lineWidth:scale:)`` turns the strokes into an image cropped
/// to the ink.
struct SignaturePad: View {
    /// The strokes of the signature, each a list of points in the coordinate space of the pad.
    @Binding var strokes: [[CGPoint]]
    /// The text under the baseline.
    var prompt: LocalizedStringResource = "Sign here"
    /// The color of the ink.
    var ink: Color = .primary
    /// The width of the ink, in points.
    var lineWidth: CGFloat = 3

    @State private var size = CGSize.zero

    private var isSigned: Bool { SignaturePadStrokes.isSigned(strokes) }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 6) {
                Rectangle()
                    .fill(.separator)
                    .frame(height: 1)

                Text(prompt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            Canvas { context, _ in
                context.stroke(
                    SignaturePadStrokes.path(for: strokes),
                    with: .color(ink),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .frame(minHeight: 160)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            size = newSize
        }
        .contentShape(.rect)
        .gesture(draw)
        .background(.background, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.separator)
        }
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(prompt))
        .accessibilityValue(isSigned ? Text("Signed") : Text("Empty"))
        .accessibilityDirectTouch(options: .silentOnTouch)
        .overlay(alignment: .topTrailing) {
            if !strokes.isEmpty {
                Button("Clear", systemImage: "eraser") {
                    strokes.removeAll()
                }
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(13)
                .contentShape(.rect)
                .padding(-13)
                .padding(12)
            }
        }
    }

    private var draw: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                SignaturePadStrokes.add(value.location, startedAt: value.startLocation, in: size, to: &strokes)
            }
    }
}

/// What a ``SignaturePad`` knows about its strokes: their length, their bounds and their path.
nonisolated enum SignaturePadStrokes {
    /// The total length of the ink, in points.
    static func length(of strokes: [[CGPoint]]) -> CGFloat {
        strokes.reduce(0) { total, stroke in
            zip(stroke, stroke.dropFirst()).reduce(total) { sum, pair in
                sum + hypot(pair.1.x - pair.0.x, pair.1.y - pair.0.y)
            }
        }
    }

    /// Whether the ink adds up to a signature rather than a stray tap.
    ///
    /// - Parameter minimumLength: The least ink, in points, that counts as signing.
    static func isSigned(_ strokes: [[CGPoint]], minimumLength: CGFloat = 20) -> Bool {
        !strokes.isEmpty && length(of: strokes) >= minimumLength
    }

    /// Adds a point of a drag: to the stroke of that drag while it goes on, or as a new stroke
    /// when another drag begins, even if the last one never ended. Points outside a pad of
    /// `size` move to its edge.
    static func add(_ point: CGPoint, startedAt start: CGPoint, in size: CGSize, to strokes: inout [[CGPoint]]) {
        let point = clamped(point, to: size)
        if let stroke = strokes.last, stroke.first == clamped(start, to: size) {
            strokes[strokes.count - 1].append(point)
        } else {
            strokes.append([point])
        }
    }

    private static func clamped(_ point: CGPoint, to size: CGSize) -> CGPoint {
        guard size.width > 0, size.height > 0 else { return point }
        return CGPoint(x: min(max(point.x, 0), size.width), y: min(max(point.y, 0), size.height))
    }

    /// The smallest rectangle that holds every point, or `nil` when there are none.
    static func bounds(of strokes: [[CGPoint]]) -> CGRect? {
        let points = strokes.joined()
        guard let first = points.first else { return nil }
        var minimum = first
        var maximum = first
        for point in points {
            minimum = CGPoint(x: min(minimum.x, point.x), y: min(minimum.y, point.y))
            maximum = CGPoint(x: max(maximum.x, point.x), y: max(maximum.y, point.y))
        }
        return CGRect(x: minimum.x, y: minimum.y, width: maximum.x - minimum.x, height: maximum.y - minimum.y)
    }

    /// The strokes as one path, smoothed through the middle of each pair of points. A stroke
    /// of a single point is a dot.
    static func path(for strokes: [[CGPoint]]) -> Path {
        var path = Path()
        for stroke in strokes {
            guard let first = stroke.first, let last = stroke.last else { continue }
            guard stroke.count > 1 else {
                path.addEllipse(in: CGRect(x: first.x - 0.5, y: first.y - 0.5, width: 1, height: 1))
                continue
            }
            path.move(to: first)
            for (point, next) in zip(stroke.dropFirst(), stroke.dropFirst(2)) {
                path.addQuadCurve(to: CGPoint(x: (point.x + next.x) / 2, y: (point.y + next.y) / 2), control: point)
            }
            path.addLine(to: last)
        }
        return path
    }

    /// Draws strokes into an image cropped to the ink, on a clear background.
    ///
    /// - Parameters:
    ///   - ink: The color of the ink. Pick a fixed color, like black, for an image that is
    ///     kept or sent: a dynamic one resolves in the light appearance.
    ///   - lineWidth: The width of the ink, in points.
    ///   - scale: The pixels per point of the image.
    /// - Returns: The image, or `nil` when there is no ink.
    @MainActor static func image(of strokes: [[CGPoint]], ink: Color = .black, lineWidth: CGFloat = 3, scale: CGFloat = 3) -> UIImage? {
        guard let bounds = bounds(of: strokes) else { return nil }
        let frame = bounds.insetBy(dx: -lineWidth, dy: -lineWidth)
        let ink = path(for: strokes)
            .offsetBy(dx: -frame.minX, dy: -frame.minY)
            .stroke(ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .frame(width: frame.width, height: frame.height)
        let renderer = ImageRenderer(content: ink)
        renderer.scale = scale
        return renderer.uiImage
    }
}

// MARK: - Demo

struct SignaturePadDemo: View {
    /// A scribble in the shape of a signature, for the demo to draw by itself.
    private static let sample: [[CGPoint]] = {
        let loops = (0...150).map { step in
            let t = Double(step) / 150
            let angle = t * 2 * .pi * 6
            let envelope = 0.65 + 0.35 * sin(t * 3 * .pi)
            return CGPoint(x: 40 + 250 * t - 16 * sin(angle), y: 118 - 26 * cos(angle) * envelope - 14 * t)
        }
        let flourish = (0...40).map { step in
            let t = Double(step) / 40
            return CGPoint(x: 70 + 230 * t, y: 162 - 18 * t + 10 * sin(t * .pi))
        }
        return [loops, flourish]
    }()

    /// Only for this demo: it plays by itself until someone touches it.
    @State private var isAutoPlaying = true
    @State private var strokes: [[CGPoint]] = []
    @State private var sampleStrokes = 0
    @State private var signature: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Delivery confirmation")
                .font(.title2.bold())

            Text("Sign to confirm you received the parcel.")
                .foregroundStyle(.secondary)

            if let signature {
                VStack(alignment: .leading, spacing: 12) {
                    Image(uiImage: signature)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 120)
                        .padding(12)
                        .background(.white, in: .rect(cornerRadius: 12))
                        .accessibilityLabel(Text("Your signature"))

                    Label("Signed", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)

                    Button("Sign again") {
                        self.signature = nil
                        strokes.removeAll()
                    }
                }
                .padding(16)
                .background(.fill.tertiary, in: .rect(cornerRadius: 16))
            } else {
                SignaturePad(strokes: $strokes)
                    .frame(height: 220)

                Button {
                    signature = SignaturePadStrokes.image(of: strokes)
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!SignaturePadStrokes.isSigned(strokes))
            }
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false })
        .onChange(of: isAutoPlaying) {
            strokes.removeFirst(min(sampleStrokes, strokes.count))
            sampleStrokes = 0
        }
        .task {
            while isAutoPlaying {
                strokes.removeAll()
                sampleStrokes = 0
                for stroke in Self.sample {
                    strokes.append([])
                    sampleStrokes += 1
                    for point in stroke {
                        try? await Task.sleep(for: .milliseconds(12))
                        guard !Task.isCancelled, isAutoPlaying else { return }
                        strokes[sampleStrokes - 1].append(point)
                    }
                }
                try? await Task.sleep(for: .seconds(1.3))
                guard !Task.isCancelled, isAutoPlaying else { return }
                strokes.removeAll()
                sampleStrokes = 0
                try? await Task.sleep(for: .seconds(0.5))
            }
        }
    }
}

#Preview {
    SignaturePadDemo()
}
