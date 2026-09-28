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
        .frame(width: 520, height: 420)
    }

    private var general: some View {
        Form {
            Section("Capture") {
                LabeledContent("New breadcrumb") {
                    Text("⌥ Space")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Text("Opens the capture palette beside your pointer and attaches the thought to the current window or tab.")
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

            Section {
                Button("Open Breadcrumb Library…", action: onOpenLibrary)
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 8)
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

                Text("Breadcrumb uses Accessibility only to identify the active app, window, tab, and window position.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Section("Pick Up Where I Left Off") {
                Toggle("Show context summary automatically", isOn: $autoResumeEnabled)

                if autoResumeEnabled {
                    Picker("Show again after", selection: $autoResumeCooldownMinutes) {
                        Text("5 minutes").tag(5.0)
                        Text("15 minutes").tag(15.0)
                        Text("30 minutes").tag(30.0)
                        Text("1 hour").tag(60.0)
                    }
                }

                Text("When you return to a window or tab with two or more active breadcrumbs, Breadcrumb can briefly show them together.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 8)
    }

    private var data: some View {
        Form {
            Section("Storage") {
                LabeledContent("Breadcrumbs") {
                    Text("On this Mac")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Cloud sync") {
                    Text("Off")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Privacy") {
                Text("No account is required. Breadcrumb notes and window metadata remain local in the current version.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 8)
    }

    private var advanced: some View {
        Form {
            Section("Troubleshooting") {
                Button("Open Context Diagnostics…", action: onOpenDiagnostics)

                Text("Diagnostics help explain why a breadcrumb appeared, disappeared, or failed to match a window.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Show Welcome Screen Again", action: onShowOnboarding)
            }

            Section("About") {
                LabeledContent("Breadcrumb") {
                    Text("Version 1.3")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 8)
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
