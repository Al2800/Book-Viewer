import SwiftUI

// MARK: - Conditional View Modifier

extension View {
    /// Conditionally apply a view modifier.
    /// - Parameters:
    ///   - condition: Boolean condition to check
    ///   - transform: Transform to apply when condition is true
    /// - Returns: Modified view when condition is true, original view otherwise
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Conditionally apply one of two view modifiers.
    /// - Parameters:
    ///   - condition: Boolean condition to check
    ///   - ifTransform: Transform to apply when condition is true
    ///   - elseTransform: Transform to apply when condition is false
    /// - Returns: Modified view based on condition
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

// MARK: - Swipe Action Helpers

/// Common swipe action button configurations with haptic feedback.
/// Use these in `.swipeActions` for consistent UX.
enum SwipeActionStyle {
    /// Creates a delete swipe action button with haptic feedback
    static func deleteButton(action: @escaping () -> Void) -> some View {
        Button(role: .destructive) {
            HapticManager.warning()
            action()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    /// Creates a remove swipe action button with haptic feedback
    static func removeButton(action: @escaping () -> Void) -> some View {
        Button(role: .destructive) {
            HapticManager.warning()
            action()
        } label: {
            Label("Remove", systemImage: "minus.circle")
        }
    }

    /// Creates a favorite swipe action button with haptic feedback
    static func favoriteButton(isFavorite: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.favoriteToggled()
            action()
        } label: {
            Label(
                isFavorite ? "Unfavorite" : "Favorite",
                systemImage: isFavorite ? "heart.slash.fill" : "heart.fill"
            )
        }
        .tint(isFavorite ? .secondary : .pink)
    }

    /// Creates an edit swipe action button with haptic feedback
    static func editButton(action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(.brand)
    }

    /// Creates a share swipe action button with haptic feedback
    static func shareButton(action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .tint(.indigo)
    }

    /// Creates an archive swipe action button with haptic feedback
    static func archiveButton(action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Label("Archive", systemImage: "archivebox")
        }
        .tint(.warning)
    }

    /// Creates a copy swipe action button with haptic feedback
    static func copyButton(action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
        .tint(.teal)
    }

    /// Creates a flag swipe action button with haptic feedback
    static func flagButton(isFlagged: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Label(
                isFlagged ? "Unflag" : "Flag",
                systemImage: isFlagged ? "flag.slash.fill" : "flag.fill"
            )
        }
        .tint(isFlagged ? .secondary : .orange)
    }
}

// MARK: - Keyboard Toolbar

extension View {
    /// Adds a "Done" button toolbar for numeric keyboards to dismiss the keyboard.
    /// Use this on TextFields with `.numberPad` or `.decimalPad` keyboard types.
    ///
    /// Example:
    /// ```swift
    /// TextField("Page", text: $pageNumber)
    ///     .keyboardType(.numberPad)
    ///     .numericKeyboardDoneButton()
    /// ```
    func numericKeyboardDoneButton() -> some View {
        modifier(NumericKeyboardToolbarModifier())
    }
}

/// View modifier that adds a Done button toolbar for numeric keyboards.
private struct NumericKeyboardToolbarModifier: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        HapticManager.light()
                        isFocused = false
                    }
                    .fontWeight(.semibold)
                }
            }
    }
}
