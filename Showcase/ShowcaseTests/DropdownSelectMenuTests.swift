// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct DropdownSelectMenuTests {
    @MainActor
    @Test func theDefaultPlaceholderIsALocalizableTextInsteadOfAString() {
        let menu = DropdownSelectMenu(title: "Size", options: ["Small"], selection: .constant(nil), label: { "\($0)" })

        #expect(menu.placeholder.key == "Choose")
    }
}
