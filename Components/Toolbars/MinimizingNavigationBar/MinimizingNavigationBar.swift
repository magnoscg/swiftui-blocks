// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A navigation stack whose navigation bar gets out of the way while the content scrolls.
///
/// The system minimizes and restores the bar, and honours Reduce Motion. The root screen
/// needs a scroll view for the bar to react. A screen pushed onto the stack keeps a full bar
/// unless it is given the same `toolbarMinimizationBehavior`.
@available(iOS 27, *)
struct MinimizingNavigationBar<Content: View>: View {
    /// When the bar minimizes: by default while the content scrolls down.
    var behavior: ToolbarMinimizationBehavior = .onScrollDown
    /// When the full bar returns: `.automatic` as soon as the content scrolls up, and
    /// `.atScrollEdge` only once it is back at the top.
    var restoration: ToolbarMinimizationRestoration = .automatic
    /// Whether the safe area of the content follows the minimized bar, which gives the
    /// content the room it leaves.
    var safeAreaAdjustment: ToolbarMinimizationSafeAreaAdjustment = .automatic
    /// The root screen: a scroll view with its navigation title and toolbar.
    @ViewBuilder var content: () -> Content

    var body: some View {
        NavigationStack {
            // On the NavigationStack itself these modifiers do nothing: they belong to its screen.
            content()
                .toolbarMinimizationBehavior(behavior, for: .navigationBar)
                .toolbarMinimizationRestoration(restoration, for: .navigationBar)
                .toolbarMinimizationSafeAreaAdjustment(safeAreaAdjustment, for: .navigationBar)
        }
    }
}

// MARK: - Demo

@available(iOS 27, *)
struct MinimizingNavigationBarDemo: View {
    private struct Article: Identifiable {
        let id: Int
        let title: String
        let source: String
        let minutes: Int
        let symbol: String
        let colors: [Color]
    }

    private let articles = [
        Article(id: 1, title: "The quiet return of night trains", source: "Slow Travel", minutes: 6, symbol: "tram.fill", colors: [.indigo, .purple]),
        Article(id: 2, title: "How bees decide where to live", source: "Field Notes", minutes: 4, symbol: "ladybug.fill", colors: [.orange, .yellow]),
        Article(id: 3, title: "Why sourdough needs patience", source: "Kitchen Lab", minutes: 8, symbol: "flame.fill", colors: [.red, .orange]),
        Article(id: 4, title: "Mapping the ocean floor", source: "Deep Blue", minutes: 11, symbol: "water.waves", colors: [.blue, .cyan]),
        Article(id: 5, title: "A field guide to city birds", source: "Field Notes", minutes: 5, symbol: "bird.fill", colors: [.teal, .green]),
        Article(id: 6, title: "Sketching in ten minutes a day", source: "Open Studio", minutes: 3, symbol: "pencil.and.scribble", colors: [.pink, .purple]),
        Article(id: 7, title: "The science of a perfect nap", source: "Kitchen Lab", minutes: 7, symbol: "moon.zzz.fill", colors: [.indigo, .blue]),
        Article(id: 8, title: "Inside a seed vault", source: "Field Notes", minutes: 9, symbol: "leaf.fill", colors: [.green, .mint]),
        Article(id: 9, title: "What makes a good walking route", source: "Slow Travel", minutes: 5, symbol: "figure.walk", colors: [.brown, .orange]),
        Article(id: 10, title: "Small gardens, big harvests", source: "Open Studio", minutes: 6, symbol: "carrot.fill", colors: [.orange, .red]),
        Article(id: 11, title: "The return of the paper map", source: "Slow Travel", minutes: 4, symbol: "map.fill", colors: [.cyan, .teal]),
        Article(id: 12, title: "Listening to glaciers", source: "Deep Blue", minutes: 10, symbol: "snowflake", colors: [.blue, .indigo]),
    ]

    @State private var returnsAtTop = false

    var body: some View {
        MinimizingNavigationBar(restoration: returnsAtTop ? .atScrollEdge : .automatic) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(articles, content: row)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .navigationTitle("Reader")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Bar returns", systemImage: "arrow.up.to.line") {
                        Picker("Bar returns", selection: $returnsAtTop) {
                            Text("On scrolling up").tag(false)
                            Text("At the top").tag(true)
                        }
                    }
                }
            }
        }
    }

    private func row(_ article: Article) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: article.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 150)
                .overlay {
                    Image(systemName: article.symbol)
                        .font(.system(size: 54))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

            Text(article.title)
                .font(.title3.bold())

            Text("\(article.source) · \(article.minutes) min read")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }
}

@available(iOS 27, *)
#Preview {
    MinimizingNavigationBarDemo()
}
