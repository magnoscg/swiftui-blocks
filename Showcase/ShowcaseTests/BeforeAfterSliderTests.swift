// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI
import Testing
@testable import Showcase

struct BeforeAfterSliderTests {
    @MainActor
    @Test func theDefaultTitlesAreLocalizableTextsInsteadOfStrings() {
        let slider = BeforeAfterSlider(before: Image(systemName: "sun.max"), after: Image(systemName: "moon"), position: .constant(0.5))

        #expect(slider.beforeTitle.key == "Before")
        #expect(slider.afterTitle.key == "After")
    }
}
