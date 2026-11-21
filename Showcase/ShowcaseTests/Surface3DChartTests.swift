// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct Surface3DChartTests {
    @available(iOS 26, *)
    @Test func everyPresetHasALocalizableTitleInsteadOfItsRawValue() {
        #expect(Surface3DChartPreset.allCases.map(\.title.key) == ["Angled", "Front", "Top", "Side"])
    }
}
