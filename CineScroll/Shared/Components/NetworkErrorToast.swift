import SwiftUI

/// Non-blocking snackbar that appears at the bottom of a screen for connectivity state changes.
///
/// Two states:
/// - `.offline(NetworkError)`. red/orange error with optional Retry / Dismiss buttons.
///   Content behind it stays fully interactive.
/// - `.backOnline`. green success banner that auto-dismisses after 2 seconds.
///   `onDismiss` is called when the timer fires so the parent can clear its local flag.
struct NetworkErrorToast: View {
    enum State: Equatable {
        case offline(NetworkError)
        case backOnline
    }

    let state: State
    var onRetry: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: CineSpacing.sm) {
            Image(systemName: iconName)
                .imageScale(.small)
            Text(message)
                .font(.subheadline)
                .lineLimit(2)
            Spacer(minLength: 0)
            if let onRetry, case .offline = state {
                Button("Retry", action: onRetry)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            if let onDismiss, case .offline = state {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .imageScale(.small)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, CineSpacing.md)
        .padding(.vertical, CineSpacing.sm + 2)
        .background(toastColor.gradient, in: RoundedRectangle(cornerRadius: CineRadius.md))
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        .padding(.horizontal, CineSpacing.md)
        .task(id: state) {
            // Auto-dismiss the "back online" banner after 2 seconds.
            guard case .backOnline = state else { return }
            try? await Task.sleep(for: .seconds(2))
            onDismiss?()
        }
    }

    private var iconName: String {
        switch state {
        case .backOnline: return "wifi"
        case .offline(let error):
            switch error {
            case .offline: return "wifi.slash"
            case .rateLimited: return "clock.badge.exclamationmark"
            default: return "exclamationmark.triangle"
            }
        }
    }

    private var message: String {
        switch state {
        case .backOnline: return "You're back online!"
        case .offline(let error): return error.userFacingMessage
        }
    }

    private var toastColor: Color {
        switch state {
        case .backOnline: return Color(red: 0.12, green: 0.52, blue: 0.30)
        case .offline(let error):
            return error.isConnectivityError
                ? Color(red: 0.7, green: 0.15, blue: 0.15)
                : Color(red: 0.75, green: 0.45, blue: 0.0)
        }
    }
}

#Preview("Offline") {
    ZStack(alignment: .bottom) {
        Color.gray.opacity(0.1).ignoresSafeArea()
        NetworkErrorToast(state: .offline(.offline), onRetry: {}, onDismiss: {})
            .padding(.bottom, CineSpacing.lg)
    }
}

#Preview("Back online") {
    ZStack(alignment: .bottom) {
        Color.gray.opacity(0.1).ignoresSafeArea()
        NetworkErrorToast(state: .backOnline, onDismiss: {})
            .padding(.bottom, CineSpacing.lg)
    }
}

#Preview("Server error") {
    ZStack(alignment: .bottom) {
        Color.gray.opacity(0.1).ignoresSafeArea()
        NetworkErrorToast(state: .offline(.invalidResponse(statusCode: 503)), onRetry: {})
            .padding(.bottom, CineSpacing.lg)
    }
}
