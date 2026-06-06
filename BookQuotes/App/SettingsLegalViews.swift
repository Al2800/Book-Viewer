import SwiftUI

enum LegalDocument: String, Identifiable {
    case privacyPolicy
    case termsOfService

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacyPolicy:
            return "Privacy Policy"
        case .termsOfService:
            return "Terms of Service"
        }
    }

    var sections: [LegalDocumentSection] {
        switch self {
        case .privacyPolicy:
            return [
                LegalDocumentSection(
                    title: "Our Commitment",
                    paragraphs: [
                        "BookQuotes is designed to keep your reading notes personal. Your library is stored locally on your device in this release."
                    ]
                ),
                LegalDocumentSection(
                    title: "What We Collect",
                    paragraphs: [
                        "When you sign in with Apple, we receive your Apple-provided identifier and, if Apple shares it, your email address. We use that information to authenticate requests to the BookQuotes service and maintain your subscription access state.",
                        "When you capture a page or cover for extraction, the image is sent to the BookQuotes proxy and then to Google Gemini for processing. Images are processed in-flight and are not retained after extraction completes.",
                        "Your books, quotes, tags, and collections are stored on-device. Cloud sync is not enabled in this v1 release."
                    ]
                ),
                LegalDocumentSection(
                    title: "What We Do Not Collect",
                    bullets: [
                        "Analytics or tracking data",
                        "Advertising identifiers",
                        "Location information",
                        "Contacts or unrelated personal files",
                        "Telemetry for ad targeting"
                    ]
                ),
                LegalDocumentSection(
                    title: "Third-Party Services",
                    bullets: [
                        "Google Gemini for AI-powered extraction from images",
                        "Sign in with Apple for secure authentication",
                        "Apple StoreKit for subscription billing, trial eligibility, and purchase management"
                    ]
                ),
                LegalDocumentSection(
                    title: "Security",
                    paragraphs: [
                        "Network requests use TLS. Your local library is protected by the security of your Apple device and iOS data protection."
                    ]
                ),
                LegalDocumentSection(
                    title: "Contact",
                    paragraphs: [
                        "Questions about privacy can be sent to \(AppReleaseConfiguration.supportEmail)."
                    ]
                )
            ]
        case .termsOfService:
            return [
                LegalDocumentSection(
                    title: "Agreement",
                    paragraphs: [
                        "By downloading or using BookQuotes, you agree to these terms. If you do not agree, do not use the app."
                    ]
                ),
                LegalDocumentSection(
                    title: "Service Description",
                    paragraphs: [
                        "BookQuotes helps you capture and organize quotes from physical books using image capture and AI-assisted text extraction."
                    ],
                    bullets: [
                        "Image capture and review",
                        "AI-powered quote extraction",
                        "Organization with books, tags, and collections",
                        "Export and backup tools"
                    ]
                ),
                LegalDocumentSection(
                    title: "Your Responsibilities",
                    bullets: [
                        "Use the app only for lawful purposes",
                        "Capture and store content only where you have the right to do so",
                        "Do not attempt to reverse engineer or misuse the service",
                        "Keep your device and sign-in credentials secure"
                    ]
                ),
                LegalDocumentSection(
                    title: "Copyright and Fair Use",
                    paragraphs: [
                        "BookQuotes is intended for personal use with books you own or are otherwise permitted to annotate. You are responsible for complying with copyright and fair use rules in your jurisdiction."
                    ]
                ),
                LegalDocumentSection(
                    title: "Availability",
                    paragraphs: [
                        "AI extraction requires an internet connection and may occasionally be unavailable. Features may change over time as the app evolves."
                    ]
                ),
                LegalDocumentSection(
                    title: "Subscriptions and Billing",
                    paragraphs: [
                        "BookQuotes offers monthly and yearly auto-renewable subscriptions through the Apple App Store.",
                        "Eligible new subscribers can start with a 7-day free trial. After the trial, the subscription renews automatically unless it is cancelled at least 24 hours before the current period ends.",
                        "Billing, renewal, cancellation, and refunds are managed by Apple through your App Store account settings."
                    ]
                ),
                LegalDocumentSection(
                    title: "Liability",
                    paragraphs: [
                        "BookQuotes is provided as-is without warranties. We are not liable for losses resulting from extraction errors, service interruptions, or data loss outside the protections provided by the platform."
                    ]
                ),
                LegalDocumentSection(
                    title: "Contact",
                    paragraphs: [
                        "Questions about these terms can be sent to \(AppReleaseConfiguration.supportEmail)."
                    ]
                )
            ]
        }
    }
}

struct LegalDocumentSection: Identifiable {
    let title: String
    var paragraphs: [String] = []
    var bullets: [String] = []

    var id: String { title }
}

struct LegalLinksRow: View {
    @Binding var presentedDocument: LegalDocument?
    var compactLabels = false

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Button(compactLabels ? "Terms" : "Terms of Service") {
                presentedDocument = .termsOfService
            }
            .buttonStyle(.plain)

            Text("and")
                .foregroundStyle(.secondary)

            Button("Privacy Policy") {
                presentedDocument = .privacyPolicy
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.brand)
    }
}

struct LegalDocumentView: View {
    @Environment(\.dismiss) private var dismiss

    let document: LegalDocument

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(document.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.textPrimary)

                        Text("Last updated: \(AppReleaseConfiguration.legalLastUpdated)")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    ForEach(document.sections) { section in
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(section.title)
                                .font(.headline)
                                .foregroundStyle(Color.textPrimary)

                            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                                Text(paragraph)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                            }

                            ForEach(Array(section.bullets.enumerated()), id: \.offset) { _, bullet in
                                HStack(alignment: .top, spacing: Spacing.sm) {
                                    Text("•")
                                    Text(bullet)
                                }
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.lg)
                        .paperCard()
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.lg)
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.backgroundPrimary)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
