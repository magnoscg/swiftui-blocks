// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A memory game: cards that turn over in 3D when tapped, to find their pairs.
///
/// A missed pair turns back after ``mismatchDelay``, and the other cards ignore taps until it
/// does. A found pair stays face up and fades a little, and the phone taps for each one. With
/// Reduce Motion the cards change sides without turning. VoiceOver reads a face-down card as
/// such, and a found card as matched.
struct MemoryMatchGame<Face: Hashable & Sendable, CardFace: View>: View {
    /// The game: its cards, the moves made and whether every pair is found. Assign a new board
    /// to start again.
    @Binding var board: MemoryMatchGameBoard<Face>
    /// The narrowest a column of cards can be, in points.
    var minimumCardWidth: CGFloat = 72
    /// How long a missed pair stays face up before it turns back.
    var mismatchDelay: Duration = .seconds(0.8)
    /// The face of a card.
    @ViewBuilder let face: (Face) -> CardFace

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let spacing: CGFloat = 10
    private let cornerRadius: CGFloat = 12

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumCardWidth), spacing: spacing)], spacing: spacing) {
            ForEach(board.cards) { card in
                Button {
                    turn(card)
                } label: {
                    cardView(card)
                }
                .buttonStyle(.plain)
                .disabled(card.isMatched)
                .accessibilityValue(card.isMatched ? Text("Matched") : Text(verbatim: ""))
            }
        }
        .sensoryFeedback(.success, trigger: board.matchedPairs) { old, new in
            new > old
        }
        // Read from the board, so a view made again while a pair is missed still turns it back.
        .task(id: board.missedPair) {
            guard let pair = board.missedPair else { return }
            try? await Task.sleep(for: mismatchDelay)
            guard !Task.isCancelled, board.missedPair == pair else { return }
            withAnimation(.smooth(duration: 0.4)) { board.hide(pair) }
        }
    }

    private func cardView(_ card: MemoryMatchGameBoard<Face>.Card) -> some View {
        let showsFace = card.isFaceUp || card.isMatched

        return MemoryMatchGameCardFlip(angle: showsFace ? 0 : 180, turns: !reduceMotion) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.background.secondary)
                .overlay {
                    face(card.face)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.separator)
                }
                .opacity(card.isMatched ? 0.55 : 1)
        } back: {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Face-down card"))
        }
        .aspectRatio(3 / 4, contentMode: .fit)
    }

    private func turn(_ card: MemoryMatchGameBoard<Face>.Card) {
        withAnimation(.smooth(duration: 0.4)) { _ = board.flip(card.id) }
    }
}

/// A card that shows its front up to a quarter turn and its back beyond it.
private struct MemoryMatchGameCardFlip<Front: View, Back: View>: View, Animatable {
    /// 0 shows the front, 180 the back.
    var angle: Double
    let turns: Bool
    @ViewBuilder let front: () -> Front
    @ViewBuilder let back: () -> Back

    nonisolated var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        let showsFront = angle < 90

        ZStack {
            front()
                .opacity(showsFront ? 1 : 0)
                .accessibilityHidden(!showsFront)

            back()
                .rotation3DEffect(.degrees(turns ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(showsFront ? 0 : 1)
                .accessibilityHidden(showsFront)
        }
        .rotation3DEffect(.degrees(turns ? angle : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
    }
}

/// The cards of a memory game and its rules, without any view.
nonisolated struct MemoryMatchGameBoard<Face: Hashable & Sendable>: Equatable, Sendable {
    /// One card of the board.
    struct Card: Identifiable, Equatable, Sendable {
        let id: Int
        /// What the card shows when it is face up.
        let face: Face
        /// Whether the card shows its face.
        var isFaceUp = false
        /// Whether the card is part of a pair already found.
        var isMatched = false
    }

    /// What turning a card over did.
    enum Flip: Equatable, Sendable {
        /// Nothing: the card was face up or matched, or a missed pair is still face up.
        case ignored
        /// The first card of a pair is face up.
        case first
        /// The two cards match and stay face up.
        case match
        /// The two cards differ: pass their identifiers to ``hide(_:)`` to turn them back.
        case mismatch([Int])
    }

    /// The two cards of a missed pair while they are face up, or `nil`.
    var missedPair: [Int]? {
        let open = cards.filter { $0.isFaceUp && !$0.isMatched }.map(\.id)
        return open.count == 2 ? open : nil
    }
    /// The cards, in the order they are laid out.
    private(set) var cards: [Card] = []
    /// How many pairs have been turned over, found or not.
    private(set) var moves = 0

    /// Whether every pair has been found.
    var isFinished: Bool { !cards.isEmpty && cards.allSatisfy(\.isMatched) }
    /// How many pairs have been found.
    var matchedPairs: Int { cards.filter(\.isMatched).count / 2 }

    /// Creates a board with each face twice, shuffled with a generator.
    init<Generator: RandomNumberGenerator>(faces: [Face], using generator: inout Generator) {
        cards = (faces + faces).shuffled(using: &generator).enumerated().map { Card(id: $0.offset, face: $0.element) }
    }

    /// Creates a board with each face twice, shuffled.
    init(faces: [Face]) {
        var generator = SystemRandomNumberGenerator()
        self.init(faces: faces, using: &generator)
    }

    /// Turns a card face up and, when it is the second of a pair, compares the two.
    mutating func flip(_ id: Int) -> Flip {
        let open = cards.indices.filter { cards[$0].isFaceUp && !cards[$0].isMatched }
        guard open.count < 2,
              let index = cards.firstIndex(where: { $0.id == id }),
              !cards[index].isFaceUp, !cards[index].isMatched
        else { return .ignored }

        cards[index].isFaceUp = true
        guard let other = open.first else { return .first }

        moves += 1
        guard cards[other].face == cards[index].face else {
            return .mismatch([cards[other].id, cards[index].id])
        }
        cards[other].isMatched = true
        cards[index].isMatched = true
        return .match
    }

    /// Turns face down the cards of a missed pair. Found pairs stay face up.
    mutating func hide(_ ids: [Int]) {
        for index in cards.indices where ids.contains(cards[index].id) && !cards[index].isMatched {
            cards[index].isFaceUp = false
        }
    }
}

// MARK: - Demo

struct MemoryMatchGameDemo: View {
    private static let faces = ["leaf.fill", "flame.fill", "drop.fill", "bolt.fill", "moon.fill", "star.fill"]

    /// Only for this demo: it plays by itself until someone touches it.
    @State private var isAutoPlaying = true
    @State private var board = MemoryMatchGameBoard(faces: faces)
    @State private var missesNext = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                Text("Memory")
                    .font(.largeTitle.bold())

                Spacer()

                Text("^[\(board.moves) move](inflect: true)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double(board.moves)))
            }

            MemoryMatchGame(board: $board, minimumCardWidth: 80) { face in
                Image(systemName: face)
                    .font(.largeTitle)
                    .foregroundStyle(color(of: face))
            }

            if board.isFinished {
                HStack {
                    Label("Every pair found", systemImage: "trophy.fill")
                        .font(.headline)

                    Spacer()

                    Button("Play again") {
                        board = MemoryMatchGameBoard(faces: Self.faces)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .transition(.opacity)
            }
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .animation(reduceMotion ? nil : .smooth, value: board.isFinished)
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false })
        .onChange(of: isAutoPlaying) {
            board.hide(board.cards.filter { $0.isFaceUp && !$0.isMatched }.map(\.id))
        }
        .task {
            while isAutoPlaying {
                try? await Task.sleep(for: .seconds(0.6))
                guard !Task.isCancelled, isAutoPlaying else { return }
                if board.isFinished {
                    board = MemoryMatchGameBoard(faces: Self.faces)
                    continue
                }
                let hidden = board.cards.filter { !$0.isMatched }
                guard let first = hidden.first,
                      let twin = hidden.first(where: { $0.id != first.id && $0.face == first.face })
                else { continue }
                let second = missesNext ? hidden.first { $0.face != first.face } ?? twin : twin
                missesNext.toggle()

                withAnimation(.smooth(duration: 0.4)) { _ = board.flip(first.id) }
                try? await Task.sleep(for: .seconds(0.5))
                guard !Task.isCancelled, isAutoPlaying else { return }
                let flip = withAnimation(.smooth(duration: 0.4)) { board.flip(second.id) }
                guard case .mismatch(let ids) = flip else { continue }
                try? await Task.sleep(for: .seconds(0.8))
                guard !Task.isCancelled, isAutoPlaying else { return }
                withAnimation(.smooth(duration: 0.4)) { board.hide(ids) }
            }
        }
    }

    private func color(of face: String) -> Color {
        switch face {
        case "leaf.fill": .green
        case "flame.fill": .orange
        case "drop.fill": .blue
        case "bolt.fill": .red
        case "moon.fill": .indigo
        default: .pink
        }
    }
}

#Preview {
    MemoryMatchGameDemo()
}
