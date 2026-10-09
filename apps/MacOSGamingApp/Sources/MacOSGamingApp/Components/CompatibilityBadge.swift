import SwiftUI
import MacOSGamingCore

public struct CompatibilityBadge: View {
    public let status: CompatibilityStatus

    public init(status: CompatibilityStatus) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 10, weight: .bold))
            Text(title)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(backgroundColor.opacity(0.18))
        .foregroundColor(foregroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(backgroundColor.opacity(0.35), lineWidth: 1)
        )
        .cornerRadius(6)
    }

    private var title: String {
        switch status {
        case .nativeMacOS:
            return "Native macOS"
        case .likelyCompatible:
            return "Compatible (Wine/DXMT)"
        case .requiresWindows:
            return "Requires Windows"
        case .notSupported:
            return "Blocked (Anti-Cheat)"
        }
    }

    private var iconName: String {
        switch status {
        case .nativeMacOS:
            return "apple.logo"
        case .likelyCompatible:
            return "checkmark.seal.fill"
        case .requiresWindows:
            return "exclamationmark.triangle.fill"
        case .notSupported:
            return "nosign"
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .nativeMacOS:
            return .green
        case .likelyCompatible:
            return .blue
        case .requiresWindows:
            return .orange
        case .notSupported:
            return .red
        }
    }

    private var foregroundColor: Color {
        backgroundColor
    }
}

public struct ProfileStateBadge: View {
    public let state: ProfileState

    public init(state: ProfileState) {
        self.state = state
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: state == .optimized ? "sparkles" : "tag.fill")
                .font(.system(size: 9, weight: .bold))
            Text(state == .optimized ? "Optimized" : "Generic/Unprofiled")
                .font(.system(size: 10, weight: .bold))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(badgeColor.opacity(0.18))
        .foregroundColor(badgeColor)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(badgeColor.opacity(0.35), lineWidth: 1)
        )
        .cornerRadius(6)
    }

    private var badgeColor: Color {
        switch state {
        case .optimized:
            return .purple
        case .generic:
            return .secondary
        }
    }
}
