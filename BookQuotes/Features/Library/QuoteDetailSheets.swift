import SwiftUI
import UIKit

struct QuoteSourceImageSheet: View {
    let imageData: Data?
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            if let imageData,
               let uiImage = UIImage(data: imageData) {
                ScrollView {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }
                .navigationTitle("Source Image")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done", action: onDone)
                    }
                }
            }
        }
    }
}

struct QuoteMarkingPickerSheet: View {
    @Binding var markingType: MarkingType
    let onCancel: () -> Void
    let onSelect: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(MarkingType.allCases, id: \.self) { type in
                    Button {
                        markingType = type
                        onSelect()
                    } label: {
                        HStack {
                            MarkingTypeBadge(markingType: type)
                            Spacer()
                            if markingType == type {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Marking Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

/// Simple share sheet for quotes using UIActivityViewController.
struct QuoteShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
