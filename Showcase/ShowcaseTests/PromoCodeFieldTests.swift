// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct PromoCodeFieldTests {
    @Test func normalizesCodesToTrimmedUppercase() {
        #expect(PromoCodeFieldLogic.normalized("  spring20 \n") == "SPRING20")
    }

    @Test func cannotApplyABlankCode() {
        #expect(!PromoCodeFieldLogic.canApply("", phase: .editing))
        #expect(!PromoCodeFieldLogic.canApply("   ", phase: .editing))
        #expect(PromoCodeFieldLogic.canApply("spring20", phase: .editing))
    }

    @Test func cannotApplyWhileACodeIsBeingChecked() {
        #expect(!PromoCodeFieldLogic.canApply("SPRING20", phase: .checking))
    }

    @Test func canApplyAgainAfterARejection() {
        #expect(PromoCodeFieldLogic.canApply("SPRING20", phase: .rejected("This code has expired")))
    }

    @Test func editingClearsARejectionButNotACheck() {
        #expect(PromoCodeFieldPhase.rejected("This code has expired").afterEditing == .editing)
        #expect(PromoCodeFieldPhase.checking.afterEditing == .checking)
        #expect(PromoCodeFieldPhase.editing.afterEditing == .editing)
    }
}
