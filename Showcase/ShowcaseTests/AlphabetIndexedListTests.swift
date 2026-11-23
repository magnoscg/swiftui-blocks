// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Foundation
import Testing
@testable import Showcase

struct AlphabetIndexedListTests {
    private let english = Locale(identifier: "en_US")
    private let spanish = Locale(identifier: "es_ES")

    private func sections(_ names: [String], locale: Locale) -> [AlphabetIndexedListSection<String>] {
        AlphabetIndexedListSection.sections(of: names, name: { $0 }, locale: locale)
    }

    @Test func groupsNamesByTheirFirstLetterIgnoringCase() {
        let result = sections(["bob", "Alice", "Beatriz", "alan"], locale: english)

        #expect(result.map(\.letter) == ["A", "B"])
        #expect(result.map(\.items) == [["alan", "Alice"], ["Beatriz", "bob"]])
    }

    @Test func ignoresAccentsSoAlvaroGoesUnderA() {
        let result = sections(["Émile", "Ana", "Álvaro", "Eva"], locale: english)

        #expect(result.map(\.letter) == ["A", "E"])
        #expect(result.map(\.items) == [["Álvaro", "Ana"], ["Émile", "Eva"]])
    }

    @Test func putsNamesThatDoNotStartWithALetterUnderHashAtTheEnd() throws {
        let result = sections(["42 Club", "Zoe", "@home", "😀 Smile", "Adam", ""], locale: english)

        #expect(result.map(\.letter) == ["A", "Z", "#"])
        let others = try #require(result.last)
        #expect(Set(others.items) == ["42 Club", "@home", "😀 Smile", ""])
    }

    @Test func sortsInTheOrderOfTheLocale() {
        let result = sections(["Ñandú", "Oliver", "Nadia", "nora"], locale: spanish)

        #expect(result.map(\.letter) == ["N", "O"])
        #expect(result.first?.items == ["Nadia", "nora", "Ñandú"])
    }

    @Test func keepsTheFirstLetterOfOtherAlphabets() {
        let result = sections(["Дмитрий", "Anna"], locale: english)

        #expect(result.map(\.letter) == ["A", "Д"])
    }

    @Test func keepsTheSectionsInAlphabeticalOrderWhereAccentedLettersSortAfterZ() {
        let result = sections(["Zoe", "Åsa", "Örjan", "Bo"], locale: Locale(identifier: "sv_SE"))

        #expect(result.map(\.letter) == ["A", "B", "O", "Z"])
    }

    @Test func keepsTheSectionsInAlphabeticalOrderWhereDigraphsSortApart() {
        let result = sections(["Hana", "Chloé", "Igor"], locale: Locale(identifier: "cs_CZ"))

        #expect(result.map(\.letter) == ["C", "H", "I"])
    }

    @Test func letterSkipsLeadingSpacesAndIgnoresCase() {
        #expect(AlphabetIndexedListSection<String>.letter(of: "  zoe", locale: english) == "Z")
        #expect(AlphabetIndexedListSection<String>.letter(of: "émile", locale: english) == "E")
        #expect(AlphabetIndexedListSection<String>.letter(of: "7 Eleven", locale: english) == "#")
    }
}
