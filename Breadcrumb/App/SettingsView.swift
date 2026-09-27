import SwiftUI

struct SettingsView: View {
    @State private var launchAtLogin = false

    var body: some View {
        Form {
            Section("Capture") {
                LabeledContent("New Breadcrumb") {
                    Text("⌥ Space")
                        .foregroundStyle(.secondary)
                }

                Text("The shortcut opens a compact composer beside your pointer without changing the app you are working in.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Section("Context") {
                LabeledContent("Window awareness") {
                    if PermissionManager.hasAccessibilityAccess {
                        Label("Enabled", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.secondary)
                    } else {
                        Button("Enable") {
                            PermissionManager.requestAccessibilityAccess()
                        }
                    }
                }

                Text("Breadcrumb uses Accessibility only to identify the active app, window title and window position. Your note content stays on this Mac.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Section("Storage") {
                LabeledContent("Data") {
                    Text("On this Mac")
                        .foregroundStyle(.secondary)
                }
            }

            Section("About") {
                LabeledContent("Breadcrumb") {
                    Text("Version 1.0")
                        .foregroundStyle(.secondary)
                }

                Text("Leave a thought where it happened. Breadcrumb brings it back when you return.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 430)
        .padding()
    }
}
