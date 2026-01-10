import SwiftUI

// MARK: - Issue Advice View

/// View showing a quality issue with actionable advice
struct IssueAdviceView: View {
    let issue: ImageQualityAnalyzer.QualityIssue

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Issue icon
            Image(systemName: issue.icon)
                .font(.title3)
                .foregroundStyle(severityColor)
                .frame(width: 28)

            // Issue text and advice
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(issueTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Text(issueAdvice)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(severityColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(severityColor.opacity(0.3), lineWidth: 1)
        }
    }

    private var issueTitle: String {
        switch issue {
        case .tooBlurry:
            return "Image is Blurry"
        case .tooDark:
            return "Image Too Dark"
        case .tooBright:
            return "Image Too Bright"
        case .noTextDetected:
            return "No Text Detected"
        case .lowTextConfidence:
            return "Text Hard to Read"
        }
    }

    private var issueAdvice: String {
        switch issue {
        case .tooBlurry(let advice),
             .tooDark(let advice),
             .tooBright(let advice),
             .noTextDetected(let advice),
             .lowTextConfidence(let advice):
            return advice
        }
    }

    private var severityColor: Color {
        switch issue {
        case .tooBlurry, .noTextDetected:
            return .error
        case .tooDark, .tooBright, .lowTextConfidence:
            return .warning
        }
    }
}

// MARK: - Compact Issue Badge

/// Compact badge for showing issue in overlay
struct IssueCompactBadge: View {
    let issue: ImageQualityAnalyzer.QualityIssue

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: issue.icon)
                .font(.caption)

            Text(shortTitle)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(severityColor)
        .clipShape(Capsule())
    }

    private var shortTitle: String {
        switch issue {
        case .tooBlurry:
            return "Blurry"
        case .tooDark:
            return "Too Dark"
        case .tooBright:
            return "Too Bright"
        case .noTextDetected:
            return "No Text"
        case .lowTextConfidence:
            return "Unclear"
        }
    }

    private var severityColor: Color {
        switch issue {
        case .tooBlurry, .noTextDetected:
            return .error
        case .tooDark, .tooBright, .lowTextConfidence:
            return .warning
        }
    }
}

// MARK: - Issue List

/// Vertically stacked list of issues
struct IssueAdviceList: View {
    let issues: [ImageQualityAnalyzer.QualityIssue]

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
                IssueAdviceView(issue: issue)
            }
        }
    }
}

// MARK: - Compact Issue Row

/// Horizontal row of compact issue badges
struct IssueCompactRow: View {
    let issues: [ImageQualityAnalyzer.QualityIssue]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
                    IssueCompactBadge(issue: issue)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Issue Advice View") {
    VStack(spacing: Spacing.md) {
        IssueAdviceView(issue: .tooBlurry(advice: "Hold the camera steady and ensure good focus"))
        IssueAdviceView(issue: .tooDark(advice: "Move to a brighter area or turn on a light"))
        IssueAdviceView(issue: .tooBright(advice: "Avoid direct light on the page or reduce flash"))
        IssueAdviceView(issue: .noTextDetected(advice: "Ensure the book page is visible in frame"))
        IssueAdviceView(issue: .lowTextConfidence(advice: "Hold camera parallel to page and ensure good lighting"))
    }
    .padding()
}

#Preview("Compact Issue Badges") {
    IssueCompactRow(issues: [
        .tooBlurry(advice: ""),
        .tooDark(advice: ""),
        .lowTextConfidence(advice: "")
    ])
    .padding()
}
