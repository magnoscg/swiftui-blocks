// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Foundation
import Testing
@testable import Showcase

struct SignaturePadTests {
    @Test func anEmptyPadIsNotSigned() {
        #expect(SignaturePadStrokes.length(of: []) == 0)
        #expect(!SignaturePadStrokes.isSigned([]))
    }

    @Test func aTapIsNotASignature() {
        #expect(!SignaturePadStrokes.isSigned([[CGPoint(x: 40, y: 40)]]))
    }

    @Test func strokesAddUpTheirLength() {
        let strokes = [[CGPoint(x: 0, y: 0), CGPoint(x: 3, y: 4)], [CGPoint(x: 10, y: 10), CGPoint(x: 10, y: 20)]]

        #expect(SignaturePadStrokes.length(of: strokes) == 15)
    }

    @Test func signedOnceTheInkReachesTheMinimumLength() {
        let short = [[CGPoint(x: 0, y: 0), CGPoint(x: 14, y: 0)]]
        let long = [[CGPoint(x: 0, y: 0), CGPoint(x: 15, y: 0)]]

        #expect(!SignaturePadStrokes.isSigned(short, minimumLength: 15))
        #expect(SignaturePadStrokes.isSigned(long, minimumLength: 15))
    }

    @Test func boundsWrapEveryPoint() throws {
        let strokes = [[CGPoint(x: 10, y: 5), CGPoint(x: 30, y: 40)], [CGPoint(x: -5, y: 20)]]

        let bounds = try #require(SignaturePadStrokes.bounds(of: strokes))

        #expect(bounds == CGRect(x: -5, y: 5, width: 35, height: 35))
        #expect(SignaturePadStrokes.bounds(of: []) == nil)
    }

    @Test func aSinglePointDrawsADot() {
        #expect(!SignaturePadStrokes.path(for: [[CGPoint(x: 20, y: 20)]]).isEmpty)
        #expect(SignaturePadStrokes.path(for: []).isEmpty)
    }
}
