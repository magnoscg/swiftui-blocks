// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct StructuredOutputFormTests {
    @available(iOS 27, *)
    @Test func everyCategoryHasALocalizableTitleInsteadOfItsRawValue() {
        #expect(StructuredOutputFormCategory.allCases.map(\.title.key) == ["Food", "Travel", "Shopping", "Other"])
    }

    @available(iOS 27, *)
    @MainActor
    @Test func theDefaultFailureMessageIsALocalizableTextInsteadOfAString() {
        let form = StructuredOutputForm(note: .constant(""), draft: .constant(StructuredOutputFormDraft()))

        #expect(form.failureMessage.key == "The on-device model couldn't fill in the form right now. Please try again later.")
    }
}
