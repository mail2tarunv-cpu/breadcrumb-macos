import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchError: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.primary.opacity(0.06))
                        .frame(width: 44, height: 44)

                    Image(systemName: "circle.dotted")
                        .font(.system(size: 20, weight: .medium))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Breadcrumb")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Leave thoughts where they happen.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(22)

            Divider()

            Form {
                Section("Capture") {
                    LabeledContent("New breadcrumb") {
                        Text("⌥ Space")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }

                    Text("Capture from any app without leaving what you're doing.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Section("Startup") {
                    Toggle("Launch Breadcrumb at login", isOn: Binding(
                        get: { launchAtLogin },
                        set: updateLaunchAtLogin
                    ))

                    if let launchError {
                        Text(launchError)
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                    }
                }

                Section("Window Awareness") {
                    LabeledContent("Accessibility") {
                        if PermissionManager.hasAccessibilityAccess {
                            Label("Enabled", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.secondary)
                        } else {
                            Button("Enable") {
                                PermissionManager.requestAccessibilityAccess()
                            }
                        }
                    }

                    Text("Breadcrumb reads only enough window metadata to remember where a thought belongs. Notes stay on this Mac.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Section("Storage") {
                    LabeledContent("Notes") {
                        Text("Stored locally")
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Cloud account") {
                        Text("None")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    LabeledContent("Version") {
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }

                    Text("Your context is the interface.")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 520, height: 560)
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }

            launchAtLogin = SMAppService.mainApp.status == .enabled
            launchError = nil
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            launchError = error.localizedDescription
        }
    }
}
