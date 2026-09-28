import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchError: String?
    @AppStorage("breadcrumb.resume.autoEnabled") private var autoResumeEnabled = true
    @AppStorage("breadcrumb.resume.cooldownMinutes") private var autoResumeCooldownMinutes = 15.0

    let onOpenLibrary: () -> Void
    let onOpenDiagnostics: () -> Void
    let onShowOnboarding: () -> Void

    var body: some View {
        TabView {
            general
                .tabItem { Label("General", systemImage: "gearshape") }

            context
                .tabItem { Label("Context", systemImage: "scope") }

            data
                .tabItem { Label("Data", systemImage: "externaldrive") }

            advanced
                .tabItem { Label("Advanced", systemImage: "wrench.and.screwdriver") }
        }
        .padding(20)
        .frame(width: 560, height: 480)
    }

    private var general: some View {
        Form {
            Section("Capture") {
                LabeledContent("New breadcrumb") {
                    Text("⌥ Space")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.quaternary.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                }

                Text("Opens the capture box beside your pointer and saves the thought to the current window or tab.")
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

            Section("Library") {
                Button("Open Breadcrumb Library…", action: onOpenLibrary)
            }
        }
        .formStyle(.grouped)
    }

    private var context: some View {
        Form {
            Section("Window Awareness") {
                LabeledContent("Accessibility") {
                    if PermissionManager.hasAccessibilityAccess {
                        Label("Enabled", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.secondary)
                    } else {
                        Button("Enable…") {
                            PermissionManager.requestAccessibilityAccess()
                        }
                    }
                }

                Text("Breadcrumb uses Accessibility to identify the active app, window, tab, and window position. Note content remains local.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Section("Pick Up Where I Left Off") {
                Toggle("Automatically show context summary", isOn: $autoResumeEnabled)

                if autoResumeEnabled {
                    Picker("Show again after", selection: $autoResumeCooldownMinutes) {
                        Text("5 minutes").tag(5.0)
                        Text("15 minutes").tag(15.0)
                        Text("30 minutes").tag(30.0)
                        Text("1 hour").tag(60.0)
                    }

                    LabeledContent("Minimum breadcrumbs") {
                        Text("2")
                            .foregroundStyle(.secondary)
                    }
                }

                Text("When you return to a window or tab with two or more active breadcrumbs, Breadcrumb can briefly surface them together so you can pick up where you left off.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Text("The summary waits until you stay in the context briefly and respects the cooldown above.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
    }

    private var data: some View {
        Form {
            Section("Storage") {
                LabeledContent("Breadcrumbs") {
                    Text("Stored locally on this Mac")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Account") {
                    Text("None")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Cloud sync") {
                    Text("Off")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Privacy") {
                Text("Breadcrumb does not need a server account for the current version. Window metadata and notes remain on this Mac.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var advanced: some View {
        Form {
            Section("Troubleshooting") {
                Button("Open Context Diagnostics…", action: onOpenDiagnostics)

                Text("Use diagnostics if a breadcrumb appears in the wrong window, fails to reappear, or window awareness stops working.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Section("Onboarding") {
                Button("Show Welcome Screen Again", action: onShowOnboarding)
            }

            Section("About") {
                LabeledContent("Version") {
                    Text("1.3")
                        .foregroundStyle(.secondary)
                }
                Text("Leave thoughts where they happen.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
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
