// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A list in sections by the first letter of each name, with the system's index of letters along
/// the trailing edge.
///
/// Tapping a letter of the index, or sliding a finger along it, jumps to its section. The list
/// sorts and groups the names in the order of the environment's locale, ignoring case and
/// accents, so Álvaro goes under A. A name that does not start with a letter, like a number or an
/// emoji, goes under # at the end.
@available(iOS 26, *)
struct AlphabetIndexedList<Item: Identifiable, Row: View>: View {
    /// The items, in any order.
    let items: [Item]
    /// The text an item is sorted and grouped by, like the name of a person.
    let name: (Item) -> String
    /// The row of one item.
    @ViewBuilder let row: (Item) -> Row

    @Environment(\.locale) private var locale

    var body: some View {
        List {
            ForEach(AlphabetIndexedListSection.sections(of: items, name: name, locale: locale)) { section in
                Section(section.letter) {
                    ForEach(section.items) { item in
                        row(item)
                    }
                }
                .sectionIndexLabel(section.letter)
            }
        }
        .listSectionIndexVisibility(.visible)
    }
}

/// The items of one letter of an ``AlphabetIndexedList``.
nonisolated struct AlphabetIndexedListSection<Item>: Identifiable {
    /// The letter the names start with, or # for the names that do not start with a letter.
    let letter: String
    /// The items of the letter, sorted by name.
    let items: [Item]

    var id: String { letter }

    /// The letter of the section of names that do not start with a letter.
    static var otherLetter: String { "#" }

    /// Sorts items by name in the order of a locale and groups them by their first letter.
    ///
    /// - Returns: A section for every first letter, in alphabetical order, and the names that
    ///   do not start with a letter in a last section under ``otherLetter``.
    static func sections(of items: [Item], name: (Item) -> String, locale: Locale) -> [Self] {
        let sorted = items.sorted {
            name($0).compare(name($1), options: .caseInsensitive, locale: locale) == .orderedAscending
        }
        var itemsByLetter: [String: [Item]] = [:]
        for item in sorted {
            itemsByLetter[letter(of: name(item), locale: locale), default: []].append(item)
        }
        // Sorted apart from the names: a locale can put Å after Z while the letter groups it under A.
        var letters = itemsByLetter.keys.filter { $0 != otherLetter }.sorted {
            $0.compare($1, locale: locale) == .orderedAscending
        }
        if itemsByLetter[otherLetter] != nil {
            letters.append(otherLetter)
        }
        return letters.map { Self(letter: $0, items: itemsByLetter[$0] ?? []) }
    }

    /// The letter a name goes under: its first letter, without accents and in uppercase, or
    /// ``otherLetter`` when the name does not start with a letter.
    static func letter(of name: String, locale: Locale) -> String {
        guard let first = name.trimmingCharacters(in: .whitespaces).first, first.isLetter else {
            return otherLetter
        }
        let folded = String(first).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: locale)
        return folded.uppercased(with: locale).first.map(String.init) ?? otherLetter
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct AlphabetIndexedListDemo: View {
    private struct Contact: Identifiable {
        let name: String
        let detail: LocalizedStringResource

        var id: String { name }
    }

    private let contacts = [
        Contact(name: "Álvaro Ruiz", detail: "Mobile"), Contact(name: "Amelia Clarke", detail: "Work"),
        Contact(name: "Ana Torres", detail: "Mobile"), Contact(name: "Ángela Vidal", detail: "Home"),
        Contact(name: "Ben Carter", detail: "Mobile"), Contact(name: "Bianca Rossi", detail: "Work"),
        Contact(name: "Camille Dubois", detail: "Mobile"), Contact(name: "Carlos Méndez", detail: "Mobile"),
        Contact(name: "Chloé Martin", detail: "Home"), Contact(name: "Daniel Kim", detail: "Work"),
        Contact(name: "Diego Herrera", detail: "Mobile"), Contact(name: "Elena Petrova", detail: "Mobile"),
        Contact(name: "Émile Laurent", detail: "Work"), Contact(name: "Ethan Brooks", detail: "Mobile"),
        Contact(name: "Fatima Zahra", detail: "Mobile"), Contact(name: "Gabriel Silva", detail: "Home"),
        Contact(name: "Hana Sato", detail: "Mobile"), Contact(name: "Hugo Lefèvre", detail: "Work"),
        Contact(name: "Íñigo Etxeberria", detail: "Mobile"), Contact(name: "Isla Murphy", detail: "Mobile"),
        Contact(name: "Jonas Weber", detail: "Work"), Contact(name: "Julia Nowak", detail: "Mobile"),
        Contact(name: "Kai Nakamura", detail: "Mobile"), Contact(name: "Laila Haddad", detail: "Home"),
        Contact(name: "Lucas Moreau", detail: "Mobile"), Contact(name: "Maya Patel", detail: "Work"),
        Contact(name: "Mateo García", detail: "Mobile"), Contact(name: "Noah Fischer", detail: "Mobile"),
        Contact(name: "Nuria Soler", detail: "Home"), Contact(name: "Olivia Jensen", detail: "Mobile"),
        Contact(name: "Pablo Ortega", detail: "Work"), Contact(name: "Quentin Roux", detail: "Mobile"),
        Contact(name: "Rosa Delgado", detail: "Mobile"), Contact(name: "Sofia Bianchi", detail: "Home"),
        Contact(name: "Tomás Navarro", detail: "Mobile"), Contact(name: "Uma Reddy", detail: "Work"),
        Contact(name: "Valentina Cruz", detail: "Mobile"), Contact(name: "Wei Chen", detail: "Mobile"),
        Contact(name: "Yara Costa", detail: "Home"), Contact(name: "Zoe Walsh", detail: "Mobile"),
        Contact(name: "24h Pharmacy", detail: "Work"), Contact(name: "@studio", detail: "Work"),
    ]

    @ScaledMetric(relativeTo: .subheadline) private var avatarSize = 40.0

    var body: some View {
        NavigationStack {
            AlphabetIndexedList(items: contacts, name: \.name) { contact in
                HStack(spacing: 12) {
                    Text(initials(of: contact.name))
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(.white)
                        .frame(width: avatarSize, height: avatarSize)
                        .background(color(for: contact.name).gradient, in: .circle)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name)
                            .font(.body)

                        Text(contact.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            .navigationTitle("Contacts")
        }
    }

    private func initials(of name: String) -> String {
        let letters = name.split(separator: " ").prefix(2).compactMap(\.first).filter(\.isLetter)
        return letters.isEmpty ? "#" : String(letters).uppercased()
    }

    private func color(for name: String) -> Color {
        let palette: [Color] = [.indigo, .teal, .orange, .pink, .blue, .purple, .green, .red]
        let index = name.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % palette.count }
        return palette[index]
    }
}

@available(iOS 26, *)
#Preview {
    AlphabetIndexedListDemo()
}
