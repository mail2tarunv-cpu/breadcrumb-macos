import SwiftUI

struct OnboardingView: View {
    let hasAccessibilityAccess: Bool
    let onEnableAccessibility: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 34)

            ZStack {
                Circle()
                    .fill(.primary.opacity(0.045))
                    .frame(width: 92, height: 92)

                Circle()
                    .fill(.primary.opacity(0.08))
                    .frame(width: 58, height: 58)

                Image(systemName: "circle.dotted")
                    .font(.system(size: 28, weight: .medium))
            }

            VStack(spacing: 9) {
                Text("Leave thoughts where they happen.")
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-0.4)

                Text("Breadcrumb remembers the window, tab, and place where a thought happened — then brings it back when you return.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 420)
            }
            .padding(.top, 22)

            HStack(spacing: 22) {
                feature("keyboard", "Capture", "Press ⌥ Space")
                feature("location", "Leave", "Keep working")
                feature("arrow.uturn.backward", "Return", "Pick up instantly")
            }
            .padding(.top, 30)

            Spacer()

            VStack(spacing: 10) {
                if hasAccessibilityAccess {
                    Label("Window awareness is ready", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    Button("Start Using Breadcrumb", action: onFinish)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .keyboardShortcut(.defaultAction)
                } else {
                    Text("Breadcrumb needs Accessibility permission to know which window a thought belongs to.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Enable Window Awareness", action: onEnableAccessibility)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }

            Spacer(minLength: 28)
        }
        .padding(.horizontal, 34)
        .frame(width: 560, height: 520)
        .background(.ultraThinMaterial)
    }

    private func feature(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 32, height: 32)
                .background(.primary.opacity(0.055))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text(title)
                .font(.system(size: 11.5, weight: .semibold))

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(width: 110)
    }
}
