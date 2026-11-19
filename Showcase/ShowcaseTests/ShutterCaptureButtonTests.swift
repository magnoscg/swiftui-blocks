// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct ShutterCaptureButtonTests {
    @Test func everyModeHasALocalizableTitleInsteadOfItsRawValue() {
        #expect(ShutterCaptureButtonMode.allCases.map(\.title.key) == ["Photo", "Video"])
    }
}
