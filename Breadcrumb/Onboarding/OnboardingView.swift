import SwiftUI

struct OnboardingView: View {
    let hasAccessibilityAccess: Bool
    let onEnableAccessibility: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.quaternary)
                    .frame(width: 72, height: 72)

                Image(systemName: "circle.dotted")
                    .font(.system(size: 34, weight: .medium))
            }

            VStack(spacing: 8) {
                Text("Leave thoughts where they happen.")
                    .font(.system(size: 25, weight: .semibold))

                Text("Press ⌥ Space from any app. Breadcrumb remembers the window and brings your thought back when you return.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 390)
            }

            HStack(spacing: 8) {
                Text("⌥")
                Text("Space")
            }
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(spacing: 9) {
                if hasAccessibilityAccess {
                    Label("Window awareness enabled", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)

                    Button("Start Using Breadcrumb", action: onFinish)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                } else {
                    Text("Breadcrumb needs Accessibility access only to identify the app and window a thought belongs to.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)

                    Button("Enable Window Awareness", action: onEnableAccessibility)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                    Button("Continue with app-level context", action: onFinish)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(32)
        .frame(width: 520, height: 480)
    }
}
