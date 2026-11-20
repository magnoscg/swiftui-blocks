// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct AnimatedCheckmarkBadgeTests {
    @MainActor
    @Test func theDefaultLabelsAreLocalizableTextsInsteadOfStrings() {
        let badge = AnimatedCheckmarkBadge(isComplete: false)

        #expect(badge.completeLabel.key == "Complete")
        #expect(badge.pendingLabel.key == "Pending")
    }
}
