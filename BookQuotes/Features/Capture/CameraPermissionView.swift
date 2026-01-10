import SwiftUI

// MARK: - Camera Permission View

/// Full-screen view shown when camera access is needed.
/// Handles all permission states with appropriate messaging and actions.
struct CameraPermissionView: View {
    @Environment(CameraPermissionService.self) private var permissionService

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Illustration
            illustrationSection

            // Title and explanation
            textSection

            // Action buttons based on status
            actionSection

            Spacer()

            // Privacy assurance footer
            privacyFooter
        }
        .padding(Spacing.xl)
        .background(Color.backgroundPrimary)
    }

    // MARK: - Illustration Section

    @ViewBuilder
    private var illustrationSection: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.brand.opacity(0.1))
                .frame(width: 140, height: 140)

            // Camera icon
            Image(systemName: "camera.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.brand)
        }
        .padding(.bottom, Spacing.lg)
    }

    // MARK: - Text Section

    @ViewBuilder
    private var textSection: some View {
        VStack(spacing: Spacing.md) {
            Text(titleText)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text(descriptionText)
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private var titleText: String {
        switch permissionService.status {
        case .notDetermined:
            return "Camera Access Needed"
        case .authorized:
            return "You're All Set!"
        case .denied:
            return "Camera Access Denied"
        case .restricted:
            return "Camera Restricted"
        }
    }

    private var descriptionText: String {
        switch permissionService.status {
        case .notDetermined:
            return "BookQuotes uses your camera to capture book covers and pages. Your photos are processed on-device and by AI to extract quotes—they're never stored on our servers."

        case .authorized:
            return "Camera access is enabled. You can now capture book covers and pages to extract your favorite quotes."

        case .denied:
            return "You previously denied camera access. To use BookQuotes, please enable camera access in your device Settings."

        case .restricted:
            return "Camera access is restricted on this device, possibly due to parental controls or device management. Please check your device settings or contact your administrator."
        }
    }

    // MARK: - Action Section

    @ViewBuilder
    private var actionSection: some View {
        VStack(spacing: Spacing.md) {
            switch permissionService.status {
            case .notDetermined:
                Button {
                    Task {
                        await permissionService.requestPermission()
                    }
                } label: {
                    Label("Enable Camera Access", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brand)
                .controlSize(.large)

            case .authorized:
                // Show nothing - view should dismiss
                EmptyView()

            case .denied:
                // Primary: Open Settings
                Button {
                    permissionService.openSettings()
                } label: {
                    Label("Open Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brand)
                .controlSize(.large)

                // Secondary: Instructions
                instructionsCard

            case .restricted:
                // Show informational card
                restrictedInfoCard
            }
        }
        .padding(.top, Spacing.lg)
    }

    // MARK: - Instructions Card (for denied state)

    @ViewBuilder
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("How to enable:")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                instructionRow(number: 1, text: "Tap \"Open Settings\" above")
                instructionRow(number: 2, text: "Find \"Camera\" in the list")
                instructionRow(number: 3, text: "Toggle it ON")
                instructionRow(number: 4, text: "Return to BookQuotes")
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    @ViewBuilder
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.brand)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Restricted Info Card

    @ViewBuilder
    private var restrictedInfoCard: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "lock.shield")
                .font(.title)
                .foregroundStyle(Color.warning)

            Text("This device has restrictions that prevent camera access. This is usually due to parental controls, school/work device policies, or Screen Time settings.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    // MARK: - Privacy Footer

    @ViewBuilder
    private var privacyFooter: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "lock.shield.fill")
                .font(.caption)
                .foregroundStyle(Color.success)

            Text("Your privacy is protected. Photos are processed locally or via secure AI and never stored on our servers.")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Compact Permission Banner

/// A compact banner for showing permission status inline
struct CameraPermissionBanner: View {
    @Environment(CameraPermissionService.self) private var permissionService

    var body: some View {
        if !permissionService.isAuthorized {
            HStack(spacing: Spacing.md) {
                Image(systemName: permissionService.status.icon)
                    .foregroundStyle(statusColor)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(bannerTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textPrimary)

                    Text(bannerSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                if permissionService.canRequest {
                    Button("Enable") {
                        Task { await permissionService.requestPermission() }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                } else if permissionService.needsSettingsRedirect {
                    Button("Settings") {
                        permissionService.openSettings()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
            .padding(Spacing.md)
            .background(statusColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
    }

    private var statusColor: Color {
        switch permissionService.status {
        case .notDetermined: return .brand
        case .authorized: return .success
        case .denied: return .warning
        case .restricted: return .error
        }
    }

    private var bannerTitle: String {
        switch permissionService.status {
        case .notDetermined: return "Camera access needed"
        case .authorized: return "Camera enabled"
        case .denied: return "Camera access denied"
        case .restricted: return "Camera restricted"
        }
    }

    private var bannerSubtitle: String {
        switch permissionService.status {
        case .notDetermined: return "Tap to enable camera capture"
        case .authorized: return "Ready to capture"
        case .denied: return "Enable in Settings to continue"
        case .restricted: return "Check device restrictions"
        }
    }
}

// MARK: - Preview

#Preview("Not Determined") {
    let service = CameraPermissionService()
    return CameraPermissionView()
        .environment(service)
}

#Preview("Permission Banner") {
    let service = CameraPermissionService()
    return VStack {
        CameraPermissionBanner()
            .padding()
        Spacer()
    }
    .environment(service)
}
