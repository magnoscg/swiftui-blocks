// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Foundation
import Testing
@testable import Showcase

struct SwipeToReplyBubbleTests {
    @Test func ignoresDragsTowardTheLeadingEdge() {
        #expect(SwipeToReplyBubblePhysics.offset(for: -40, threshold: 64) == 0)
    }

    @Test func followsTheFingerUpToTheThreshold() {
        #expect(SwipeToReplyBubblePhysics.offset(for: 30, threshold: 64) == 30)
        #expect(SwipeToReplyBubblePhysics.offset(for: 64, threshold: 64) == 64)
    }

    @Test func resistsPastTheThresholdAndNeverDoublesIt() {
        let offset = SwipeToReplyBubblePhysics.offset(for: 164, threshold: 64)

        #expect(offset > 64)
        #expect(offset < 164)
        #expect(SwipeToReplyBubblePhysics.offset(for: 10_000, threshold: 64) < 128)
    }

    @Test func repliesOnlyOnceTheDragReachesTheThreshold() {
        #expect(!SwipeToReplyBubblePhysics.replies(after: 63, threshold: 64))
        #expect(SwipeToReplyBubblePhysics.replies(after: 64, threshold: 64))
        #expect(!SwipeToReplyBubblePhysics.replies(after: -100, threshold: 64))
    }

    @Test(arguments: [(-20, 0), (0, 0), (32, 0.5), (64, 1), (200, 1)] as [(CGFloat, CGFloat)])
    func progressGoesFromZeroToOne(translation: CGFloat, expected: CGFloat) {
        #expect(SwipeToReplyBubblePhysics.progress(for: translation, threshold: 64) == expected)
    }

    @Test func aThresholdOfZeroNeverReplies() {
        #expect(!SwipeToReplyBubblePhysics.replies(after: 50, threshold: 0))
        #expect(SwipeToReplyBubblePhysics.offset(for: 50, threshold: 0) == 0)
        #expect(SwipeToReplyBubblePhysics.progress(for: 50, threshold: 0) == 0)
    }
}
