import SwiftUI
import UIKit

// MARK: - Quote Editor Sheet

struct QuoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    @Binding var marginNote: String
    @Binding var markingType: String
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                QuoteEditorTextView(text: $text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .fieldChrome()
                    .accessibilityIdentifier(AccessibilityIdentifiers.Capture.extractionQuoteTextEditor)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Marking type")
                        .font(.uiCaption)
                        .foregroundStyle(Color.textSecondary)

                    Picker("Marking type", selection: $markingType) {
                        ForEach(MarkingType.configurableCases) { type in
                            Text(type.displayName).tag(type.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Capture.extractionQuoteMarkingPicker)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Margin note (optional)")
                        .font(.uiCaption)
                        .foregroundStyle(Color.textSecondary)
                    TextField("Add a note…", text: $marginNote, axis: .vertical)
                        .textFieldStyle(.plain)
                        .fieldChrome(minHeight: 56)
                        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.extractionQuoteMarginNoteField)
                }
            }
            .padding(Spacing.md)
            .background(Color.backgroundPrimary)
            .navigationTitle("Edit Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Quote Editor Text View

private struct QuoteEditorTextView: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> AutofocusingTextView {
        let textView = AutofocusingTextView()
        textView.delegate = context.coordinator
        textView.text = text
        textView.backgroundColor = .clear
        textView.font = preferredQuoteFont
        textView.textColor = .label
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.accessibilityIdentifier = AccessibilityIdentifiers.Capture.extractionQuoteTextEditor
        textView.accessibilityLabel = "Quote text"
        textView.focusWhenAttached = { [weak coordinator = context.coordinator] textView in
            coordinator?.requestInitialFocus(for: textView)
        }
        return textView
    }

    func updateUIView(_ textView: AutofocusingTextView, context: Context) {
        context.coordinator.parent = self
    }

    private var preferredQuoteFont: UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        return UIFont(descriptor: descriptor.withDesign(.serif) ?? descriptor, size: 0)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: QuoteEditorTextView
        private var requestedInitialFocus = false
        private let initialFocusAttemptCount = 5

        init(_ parent: QuoteEditorTextView) {
            self.parent = parent
        }

        func requestInitialFocus(for textView: UITextView) {
            guard !requestedInitialFocus else { return }
            requestedInitialFocus = true
            focusWhenReady(textView, attemptsRemaining: initialFocusAttemptCount)
        }

        private func focusWhenReady(_ textView: UITextView, attemptsRemaining: Int) {
            guard attemptsRemaining > 0 else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(120)) { [weak self, weak textView] in
                guard let self, let textView, !textView.isFirstResponder else { return }

                if textView.window != nil, textView.becomeFirstResponder() {
                    return
                }

                self.focusWhenReady(textView, attemptsRemaining: attemptsRemaining - 1)
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }

    final class AutofocusingTextView: UITextView {
        var focusWhenAttached: ((UITextView) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            focusWhenAttached?(self)
        }
    }
}
