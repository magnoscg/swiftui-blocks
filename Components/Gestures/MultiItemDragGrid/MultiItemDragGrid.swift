// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI
import UniformTypeIdentifiers

/// A grid where tapping selects items and dragging one of the selected items carries them all.
///
/// A drag that starts on an item that is not selected carries only that item. The system lifts
/// the items after a short hold and draws them as a stack under the finger. The receiving view
/// takes them with `dropDestination(for:)`, so `Item` needs a transfer representation it can
/// also import, such as `CodableRepresentation`.
@available(iOS 27, *)
struct MultiItemDragGrid<Item: Identifiable & Transferable, Cell: View>: View where Item.ID: Sendable {
    /// The items in the grid, in order.
    let items: [Item]
    /// The identifiers of the selected items, in the order they were picked.
    @Binding var selection: [Item.ID]
    /// The narrowest a column can be: the grid fits as many columns as its width allows.
    var minimumColumnWidth: CGFloat = 100
    /// The space between cells, in points.
    var spacing: CGFloat = 4
    /// The view of one item, given the item and whether it is selected.
    @ViewBuilder let cell: (Item, Bool) -> Cell

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumColumnWidth), spacing: spacing)], spacing: spacing) {
            ForEach(items) { item in
                let isSelected = selection.contains(item.id)

                Button {
                    toggle(item.id)
                } label: {
                    cell(item, isSelected)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .bottomTrailing) {
                    if isSelected {
                        checkmark
                    }
                }
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .draggable(containerItemID: item.id)
            }
        }
        .dragContainer(for: Item.self) { draggedIDs in
            draggedIDs.compactMap { id in items.first { $0.id == id } }
        }
        .dragContainerSelection(selection)
    }

    private var checkmark: some View {
        Image(systemName: "checkmark.circle.fill")
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, .blue)
            .font(.title3)
            .shadow(radius: 2)
            .padding(6)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func toggle(_ id: Item.ID) {
        if let index = selection.firstIndex(of: id) {
            selection.remove(at: index)
        } else {
            selection.append(id)
        }
    }
}

// MARK: - Demo

@available(iOS 27, *)
struct MultiItemDragGridDemo: View {
    nonisolated private struct Photo: Identifiable, Codable, Transferable {
        let id: Int
        let symbol: String
        let hue: Double

        static var transferRepresentation: some TransferRepresentation {
            CodableRepresentation(contentType: .json)
        }
    }

    private struct Album: Identifiable {
        let id: String
        let title: LocalizedStringResource
        let symbol: String
        var photoIDs: [Int] = []
    }

    private static let symbols = ["sun.max.fill", "leaf.fill", "mountain.2.fill", "cloud.rain.fill", "flame.fill", "snowflake", "moon.stars.fill", "bird.fill", "camera.macro", "drop.fill", "tree.fill", "wind"]

    private let photos = (0..<24).map { index in
        Photo(id: index, symbol: symbols[index % symbols.count], hue: Double(index) / 24)
    }

    @State private var selection: [Int] = []
    @State private var albums = [
        Album(id: "favorites", title: "Favorites", symbol: "heart.fill"),
        Album(id: "trip", title: "Trip", symbol: "airplane"),
        Album(id: "family", title: "Family", symbol: "person.2.fill"),
    ]
    @State private var targetedAlbum: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tap photos to select them, then hold one and drag them all to an album.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                let albumLayout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))

                albumLayout {
                    ForEach($albums) { $album in
                        albumTile(album)
                            .dropDestination(for: Photo.self) { dropped, _ in
                                let droppedIDs = dropped.map(\.id)
                                album.photoIDs.append(contentsOf: droppedIDs.filter { !album.photoIDs.contains($0) })
                                selection.removeAll { droppedIDs.contains($0) }
                            }
                            .onDropSessionUpdated { session in
                                switch session.phase {
                                case .entering, .active:
                                    targetedAlbum = album.id
                                default:
                                    if targetedAlbum == album.id {
                                        targetedAlbum = nil
                                    }
                                }
                            }
                    }
                }

                HStack {
                    Text("^[\(selection.count) photo](inflect: true) selected")
                        .font(.headline)
                        .contentTransition(.numericText())

                    Spacer()

                    Button("Clear") {
                        selection.removeAll()
                    }
                    .disabled(selection.isEmpty)
                }

                MultiItemDragGrid(items: photos, selection: $selection, minimumColumnWidth: 96) { photo, isSelected in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hue: photo.hue, saturation: 0.55, brightness: 0.9).gradient)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: photo.symbol)
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                        .opacity(isSelected ? 0.75 : 1)
                        .accessibilityLabel(Text("Photo \(photo.id + 1)"))
                }
            }
            .padding(16)
            .animation(reduceMotion ? nil : .snappy, value: selection)
            .animation(reduceMotion ? nil : .snappy, value: targetedAlbum)
        }
    }

    private func albumTile(_ album: Album) -> some View {
        let isTargeted = targetedAlbum == album.id

        return VStack(spacing: 6) {
            Image(systemName: album.symbol)
                .font(.title2)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(.fill.tertiary, in: .rect(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.blue, lineWidth: isTargeted ? 3 : 0)
                }
                .scaleEffect(isTargeted && !reduceMotion ? 1.06 : 1)
                .accessibilityHidden(true)

            Text(album.title)
                .font(.footnote.bold())

            Text("^[\(album.photoIDs.count) photo](inflect: true)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

@available(iOS 27, *)
#Preview {
    MultiItemDragGridDemo()
}
