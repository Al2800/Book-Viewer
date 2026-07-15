import SwiftUI

struct ExportOptionsView: View {
    @Binding var options: ExportOptions

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Toggle("Include metadata", isOn: $options.includeMetadata)
                .accessibilityIdentifier(AccessibilityIdentifiers.Export.includeMetadataToggle)
            Toggle("Group by book", isOn: $options.groupByBook)
                .accessibilityIdentifier(AccessibilityIdentifiers.Export.groupByBookToggle)
            Toggle("Include page numbers", isOn: $options.includePageNumbers)
                .accessibilityIdentifier(AccessibilityIdentifiers.Export.includePageNumbersToggle)
            Toggle("Include margin notes", isOn: $options.includeMarginNotes)
                .accessibilityIdentifier(AccessibilityIdentifiers.Export.includeMarginNotesToggle)
        }
    }
}
