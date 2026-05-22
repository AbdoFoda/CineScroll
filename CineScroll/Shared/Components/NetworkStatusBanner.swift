import SwiftUI

/// A thin banner that slides in from the top when the device loses connectivity.
///
/// Place it as a `.safeAreaInset(edge: .top)` on the root view so it pushes
/// content down rather than overlapping it. Animate with
/// `.animation(.spring(duration: 0.3), value: isConnected)`.
struct NetworkStatusBanner: View {
    let isConnected: Bool
    /// Called when the user taps "Reload" while offline.
    var onReload: (() -> Void)?

    var body: some View {
        if !isConnected {
            HStack(spacing: CineSpacing.sm) {
                Image(systemName: "wifi.slash")
                    .imageScale(.small)
                Text("No internet connection")
                    .font(.subheadline.weight(.medium))
                Spacer()
                if let onReload {
                    Button("Reload", action: onReload)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, CineSpacing.md)
            .padding(.vertical, CineSpacing.sm)
            .background(Color(red: 0.8, green: 0.1, blue: 0.1).gradient)
            .transition(.move(edge: .top).combined(with: .opacity))
            .cineAccessibility(AccessibilityID.networkBanner)
        }
    }
}

#Preview("Offline") {
    VStack(spacing: 0) {
        NetworkStatusBanner(isConnected: false, onReload: {})
        Spacer()
    }
}

#Preview("Online") {
    NetworkStatusBanner(isConnected: true, onReload: {})
}
