// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import MapKit
import SwiftUI

/// A map with a pin fixed at its center, to pick a place by moving the map under the pin.
///
/// The pin lifts while the map moves and lands with a small bounce where it stops, and only
/// then does the picker update ``coordinate``. Setting ``coordinate`` from outside moves the
/// map there. With Reduce Motion the pin stays down and only its shadow changes.
///
/// The pin marks the center of the picker's frame, so controls placed over the map can hide
/// it: put them next to the map instead.
struct MapPinLocationPicker: View {
    /// The point under the tip of the pin. The picker writes it each time the map comes to rest.
    @Binding var coordinate: CLLocationCoordinate2D
    /// How much of the map shows around the pin when the picker moves the map, in meters.
    var span: CLLocationDistance = 800
    /// The color of the head of the pin.
    var tint: Color = .red

    @State private var position: MapCameraPosition = .automatic
    @State private var isMoving = false
    @State private var reported: [Double] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let headSize: CGFloat = 28
    private let stemHeight: CGFloat = 16
    private let lift: CGFloat = 14

    var body: some View {
        Map(position: $position)
            .onMapCameraChange(frequency: .continuous) { context in
                let center = context.camera.centerCoordinate
                if [center.latitude, center.longitude] != reported {
                    isMoving = true
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                let center = context.camera.centerCoordinate
                reported = [center.latitude, center.longitude]
                isMoving = false
                coordinate = center
            }
            .overlay {
                pin
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .onAppear {
                move(to: coordinate)
            }
            .onChange(of: [coordinate.latitude, coordinate.longitude]) { _, new in
                if new != reported {
                    withAnimation(reduceMotion ? nil : .smooth) { move(to: coordinate) }
                }
            }
            .animation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.45), value: isMoving)
    }

    private var pin: some View {
        ZStack {
            Ellipse()
                .fill(.black.opacity(isMoving ? 0.15 : 0.3))
                .frame(width: isMoving ? 16 : 10, height: isMoving ? 6 : 4)

            VStack(spacing: 0) {
                Circle()
                    .fill(tint)
                    .frame(width: headSize, height: headSize)
                    .overlay {
                        Circle()
                            .fill(MapPinLocationPickerContrastingForeground(background: tint))
                            .frame(width: headSize / 3, height: headSize / 3)
                    }
                    .shadow(color: .black.opacity(0.25), radius: isMoving ? 6 : 2, y: isMoving ? 4 : 1)

                Capsule()
                    .fill(Color(white: 0.3))
                    .frame(width: 3, height: stemHeight)
            }
            .offset(y: -(headSize + stemHeight) / 2 - (isMoving && !reduceMotion ? lift : 0))
        }
    }

    private func move(to coordinate: CLLocationCoordinate2D) {
        position = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: span, longitudinalMeters: span))
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct MapPinLocationPickerContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct MapPinLocationPickerDemo: View {
    private static let start = CLLocationCoordinate2D(latitude: 40.4169, longitude: -3.7035)

    @State private var coordinate = start
    @State private var chosen: CLLocationCoordinate2D?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let stack = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(spacing: 24))

        VStack(spacing: 0) {
            MapPinLocationPicker(coordinate: $coordinate)
                .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: 12) {
                Text("Move the map to place the pin")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                stack {
                    value("Latitude", coordinate.latitude)
                    value("Longitude", coordinate.longitude)
                }

                stack {
                    Button("Reset") {
                        coordinate = Self.start
                        chosen = nil
                    }
                    .buttonStyle(.bordered)

                    if !dynamicTypeSize.isAccessibilitySize {
                        Spacer()
                    }

                    Button {
                        chosen = coordinate
                    } label: {
                        if chosen == nil {
                            Label("Choose this spot", systemImage: "mappin.and.ellipse")
                        } else {
                            Label("Chosen", systemImage: "checkmark")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .background(.background)
            .onChange(of: [coordinate.latitude, coordinate.longitude]) {
                chosen = nil
            }
        }
    }

    private func value(_ title: LocalizedStringResource, _ degrees: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(degrees, format: .number.precision(.fractionLength(5)))
                .font(.headline.monospacedDigit())
                .contentTransition(.numericText(value: degrees))
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    MapPinLocationPickerDemo()
}
