// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct MemoryMatchGameTests {
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var value = state
            value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
            value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
            return value ^ (value >> 31)
        }
    }

    private static let faces = ["leaf", "flame", "drop", "bolt", "moon", "star", "cloud", "snow"]

    private func board(seed: UInt64 = 7) -> MemoryMatchGameBoard<String> {
        var generator = SeededGenerator(state: seed)
        return MemoryMatchGameBoard(faces: Self.faces, using: &generator)
    }

    private func ids(of face: String, in board: MemoryMatchGameBoard<String>) -> [Int] {
        board.cards.filter { $0.face == face }.map(\.id)
    }

    @Test func holdsEachFaceTwiceFaceDown() {
        let board = board()

        #expect(board.cards.count == 16)
        #expect(Self.faces.allSatisfy { face in board.cards.filter { $0.face == face }.count == 2 })
        #expect(board.cards.allSatisfy { !$0.isFaceUp && !$0.isMatched })
        #expect(board.moves == 0)
    }

    @Test func shufflesTheSameWayWithTheSameGenerator() {
        #expect(board(seed: 1).cards.map(\.face) == board(seed: 1).cards.map(\.face))
        #expect(board(seed: 1).cards.map(\.face) != board(seed: 2).cards.map(\.face))
    }

    @Test func aMatchingPairStaysFaceUp() {
        var board = board()
        let pair = ids(of: "moon", in: board)

        #expect(board.flip(pair[0]) == .first)
        #expect(board.flip(pair[1]) == .match)
        #expect(board.cards.filter(\.isMatched).map(\.id).sorted() == pair.sorted())
        #expect(board.moves == 1)
        #expect(board.matchedPairs == 1)
    }

    @Test func aMissedPairBlocksTapsUntilItTurnsBack() {
        var board = board()
        let moon = ids(of: "moon", in: board)[0]
        let star = ids(of: "star", in: board)[0]
        let leaf = ids(of: "leaf", in: board)[0]

        #expect(board.flip(moon) == .first)
        #expect(board.flip(star) == .mismatch([moon, star]))
        #expect(board.flip(leaf) == .ignored)
        board.hide([moon, star])

        #expect(board.cards.allSatisfy { !$0.isFaceUp })
        #expect(board.moves == 1)
        #expect(board.flip(leaf) == .first)
    }

    @Test func faceUpAndMatchedCardsIgnoreTaps() {
        var board = board()
        let pair = ids(of: "bolt", in: board)

        _ = board.flip(pair[0])
        #expect(board.flip(pair[0]) == .ignored)
        _ = board.flip(pair[1])

        #expect(board.flip(pair[1]) == .ignored)
        board.hide(pair)
        #expect(board.cards.filter(\.isFaceUp).count == 2)
    }

    @Test func everyNewBoardHasItsOwnIdentity() {
        #expect(board(seed: 1).id != board(seed: 1).id)
    }

    @Test func finishesWhenEveryPairIsFound() {
        var board = board()

        for face in Self.faces {
            let pair = ids(of: face, in: board)
            _ = board.flip(pair[0])
            _ = board.flip(pair[1])
        }

        #expect(board.isFinished)
        #expect(board.moves == Self.faces.count)
    }
}
