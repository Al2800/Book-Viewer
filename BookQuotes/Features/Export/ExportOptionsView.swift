import SwiftUI

struct ExportOptionsView: View {
    @Binding var options: ExportOptions

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Toggle("Include metadata", isOn: $options.includeMetadata)
            Toggle("Group by book", isOn: $options.groupByBook)
            Toggle("Include page numbers", isOn: $options.includePageNumbers)
            Toggle("Include margin notes", isOn: $options.includeMarginNotes)
        }
    }
}
