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
                        "Captured pages and downloaded catalogue cover images are stored locally on your device while you review, retry, or save them. When you save a quote, a compressed source-image copy may be kept with that quote for reference until you delete the quote. Draft and queued images remain on-device until they are processed or deleted.",
                        "If you enable Remote AI Processing, the marked-page image, extraction instructions, and resulting text are sent through the BookQuotes service and the Hugging Face Inference Providers router to the pinned Featherless AI inference provider. The BookQuotes service does not write those image or prompt payloads to its application database; these providers handle request data under their own terms.",
                        "When you scan a book, BookQuotes sends its ISBN directly to Google Books to find metadata and a canonical cover image. If the ISBN is not found there, it is sent to Open Library as a fallback. These catalogue requests do not include your BookQuotes account identifier or library.",
                        "The BookQuotes service stores account-linked subscription access records and extraction counts with last-updated timestamps. Short-lived rate-limit counters may use your account and network information to protect the service. After account deletion, a session-revocation record may remain for up to eight days solely to prevent use of already-issued session tokens. Your books, quotes, tags, collections, and locally retained images are otherwise stored on-device. Cloud sync is not enabled in this v1 release."
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
                        "Hugging Face Inference for model-assisted quote extraction from marked quote pages when you enable Remote AI Processing",
                        "Featherless AI as the pinned inference provider for those consented requests",
                        "Apple Vision for on-device OCR when Remote AI Processing is off or you explicitly choose the on-device option",
                        "Google Books for requested ISBN metadata lookups and cover images",
                        "Open Library as an ISBN metadata fallback when Google Books has no match",
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
                    title: "Account Deletion",
                    paragraphs: [
                        "You can delete your BookQuotes account from Settings → Account → Delete Account. This removes your subscription access records and usage data from BookQuotes servers; a session-revocation record remains for up to eight days to block existing tokens. Your on-device library remains unless you delete it yourself. App Store subscriptions are billed by Apple and must be cancelled in Apple subscription management."
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
                        "BookQuotes helps you capture and organize quotes from physical books using image capture, on-device OCR, and AI-assisted text extraction where enabled."
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
                        "On-device quote extraction does not require an internet connection. Cloud-assisted extraction, where enabled, requires network availability and may occasionally be unavailable. Features may change over time as the app evolves."
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
                            .font(.serifHeadline)
                            .foregroundStyle(Color.textPrimary)

                        Text("Last updated: \(AppReleaseConfiguration.legalLastUpdated)")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    ForEach(document.sections) { section in
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(section.title)
                                .font(.uiLabel)
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
