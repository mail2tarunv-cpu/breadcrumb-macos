import SwiftUI

struct OnboardingView: View {
    @AppStorage("breadcrumb.capture.shortcut") private var captureShortcutRaw = CaptureShortcut.optionSpace.rawValue

    let hasAccessibilityAccess: Bool
    let onEnableAccessibility: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            Image(systemName: "circle.dotted")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.primary)

            VStack(spacing: 7) {
                Text("Leave thoughts where they happen.")
                    .font(.system(size: 25, weight: .semibold))

                Text("Press \((CaptureShortcut(rawValue: captureShortcutRaw) ?? .optionSpace).title) from any app. Breadcrumb remembers the window or tab and brings your thought back when you return.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 390)
            }

            HStack(spacing: 28) {
                step("1", "Capture", (CaptureShortcut(rawValue: captureShortcutRaw) ?? .optionSpace).title)
                step("2", "Leave", "Keep working")
                step("3", "Return", "Pick up again")
            }

            Divider()
                .frame(maxWidth: 410)

            if hasAccessibilityAccess {
                VStack(spacing: 12) {
                    Label("Window awareness is enabled", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Button("Start Using Breadcrumb", action: onFinish)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .keyboardShortcut(.defaultAction)
                }
            } else {
                VStack(spacing: 10) {
                    Text("Breadcrumb needs Accessibility permission to know which window a thought belongs to.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)

                    Button("Enable Window Awareness…", action: onEnableAccessibility)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }

            Spacer(minLength: 20)
        }
        .padding(.horizontal, 34)
        .frame(width: 520, height: 430)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func step(_ number: String, _ title: String, _ detail: String) -> some View {
        VStack(spacing: 5) {
            Text(number)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(.quaternary)
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 11.5, weight: .semibold))

            Text(detail)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(width: 100)
    }
}
