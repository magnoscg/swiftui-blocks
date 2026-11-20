// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct OnDeviceStreamingAnswerTests {
    @available(iOS 26, *)
    @MainActor
    @Test func theDefaultPlaceholderIsALocalizableTextInsteadOfAString() {
        let answer = OnDeviceStreamingAnswer(prompt: "")

        #expect(answer.placeholder.key == "Ask something to see the answer here.")
    }

    @available(iOS 26, *)
    @MainActor
    @Test func theDefaultFailureMessageIsALocalizableTextInsteadOfAString() {
        let answer = OnDeviceStreamingAnswer(prompt: "")

        #expect(answer.failureMessage.key == "The on-device model couldn't answer right now. Please try again later.")
    }
}
