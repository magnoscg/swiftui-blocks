// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A field for a promo code, with an Apply button that checks it.
///
/// While ``validate`` runs, the button shows a spinner and the field waits. An accepted code
/// replaces the field with a row that says it is applied, with a button that removes it. A
/// rejected code shakes the field, outlines it in red and shows the reason under it, which
/// VoiceOver also announces, and the field takes the focus back so typing again clears it.
/// With Reduce Motion the field does not shake. Codes are checked without surrounding spaces
/// and in uppercase.
struct PromoCodeField: View {
    /// The code that is applied, or `nil`. The field sets it when ``validate`` accepts a code
    /// and clears it when the code is removed.
    @Binding var appliedCode: String?
    /// Checks a code and returns `nil` when it is accepted, or the reason it is not.
    let validate: (String) async -> LocalizedStringResource?
    /// The text shown in the empty field.
    var prompt: LocalizedStringResource = "Promo code"

    @State private var text = ""
    @State private var phase = PromoCodeFieldPhase.editing
    @State private var rejections = 0
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cornerRadius: CGFloat = 12
    private let fieldInset: CGFloat = 6

    private var isRejected: Bool {
        if case .rejected = phase { true } else { false }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let appliedCode {
                applied(appliedCode)
            } else {
                field

                if case .rejected(let reason) = phase {
                    Text(reason)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: appliedCode)
        .animation(reduceMotion ? nil : .snappy, value: phase)
        .onChange(of: text) {
            phase = phase.afterEditing
        }
        .onChange(of: rejections) {
            isFocused = true
        }
    }

    private var field: some View {
        let shakes = !reduceMotion

        return HStack(spacing: 8) {
            TextField(text: $text, prompt: Text(prompt)) {
                Text(prompt)
            }
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .submitLabel(.go)
            .onSubmit(apply)
            .focused($isFocused)
            .disabled(phase == .checking)
            .accessibilityLabel(Text(prompt))

            Button(action: apply) {
                Text("Apply")
                    .opacity(phase == .checking ? 0 : 1)
                    .overlay {
                        if phase == .checking {
                            ProgressView()
                        }
                    }
            }
            .buttonStyle(.bordered)
            .disabled(!PromoCodeFieldLogic.canApply(text, phase: phase))
        }
        .padding(.leading, 14)
        .padding(.trailing, fieldInset)
        .padding(.vertical, fieldInset)
        .background(.fill.tertiary, in: .rect(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(.red, lineWidth: isRejected ? 1.5 : 0)
        }
        .keyframeAnimator(initialValue: 0.0, trigger: rejections) { content, offset in
            content.offset(x: shakes ? offset : 0)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-10, duration: 0.06)
                CubicKeyframe(9, duration: 0.08)
                CubicKeyframe(-6, duration: 0.08)
                CubicKeyframe(3, duration: 0.07)
                CubicKeyframe(0, duration: 0.06)
            }
        }
    }

    private func applied(_ code: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            Text("\(code) applied")
                .font(.subheadline.weight(.semibold))

            Spacer(minLength: 0)

            Button("Remove") {
                appliedCode = nil
            }
            .font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.green.opacity(0.12), in: .rect(cornerRadius: cornerRadius))
        .transition(.scale(scale: 0.95).combined(with: .opacity))
    }

    private func apply() {
        let code = PromoCodeFieldLogic.normalized(text)
        guard PromoCodeFieldLogic.canApply(code, phase: phase) else { return }
        phase = .checking
        Task {
            if let reason = await validate(code) {
                phase = .rejected(reason)
                rejections += 1
                AccessibilityNotification.Announcement(String(localized: reason)).post()
            } else {
                text = ""
                phase = .editing
                appliedCode = code
                AccessibilityNotification.Announcement(String(localized: "\(code) applied")).post()
            }
        }
    }
}

/// Where a ``PromoCodeField`` stands while a code is typed and checked.
nonisolated enum PromoCodeFieldPhase: Equatable {
    /// The field is waiting for a code.
    case editing
    /// The last code is being checked.
    case checking
    /// The last code was turned down, for the reason given.
    case rejected(LocalizedStringResource)

    /// The phase once the text changes: a rejection goes away, a check goes on.
    var afterEditing: Self {
        if case .rejected = self { .editing } else { self }
    }
}

/// The rules of a ``PromoCodeField`` that do not need a view.
nonisolated enum PromoCodeFieldLogic {
    /// The code as it is checked: without surrounding spaces and in uppercase.
    static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    /// Whether the code in the field can be applied in a phase.
    static func canApply(_ text: String, phase: PromoCodeFieldPhase) -> Bool {
        phase != .checking && !normalized(text).isEmpty
    }
}

// MARK: - Demo

struct PromoCodeFieldDemo: View {
    private let subtotal = 48.0

    @State private var appliedCode: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var discount: Double {
        appliedCode == nil ? 0 : subtotal * 0.2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Order summary")
                .font(.title2.bold())

            VStack(spacing: 10) {
                row("Subtotal", amount: subtotal)

                if appliedCode != nil {
                    row("Discount", amount: -discount)
                        .foregroundStyle(.green)
                        .transition(.opacity)
                }

                Divider()

                row("Total", amount: subtotal - discount)
                    .font(.headline)
            }

            PromoCodeField(appliedCode: $appliedCode) { code in
                try? await Task.sleep(for: .seconds(0.9))
                switch code {
                case "SPRING20":
                    return nil
                case "EXPIRED":
                    return "This code has expired."
                default:
                    return "That code does not exist."
                }
            }

            Text("Try SPRING20, or EXPIRED to see a code turned down.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .animation(reduceMotion ? nil : .snappy, value: appliedCode)
    }

    private func row(_ title: LocalizedStringResource, amount: Double) -> some View {
        HStack {
            Text(title)

            Spacer()

            Text(amount, format: .currency(code: "USD"))
                .monospacedDigit()
                .contentTransition(.numericText(value: amount))
        }
    }
}

#Preview {
    PromoCodeFieldDemo()
}
