import AppKit
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchError: String?

    @AppStorage("breadcrumb.resume.autoEnabled") private var autoResumeEnabled = true
    @AppStorage("breadcrumb.resume.cooldownMinutes") private var autoResumeCooldownMinutes = 15.0
    @AppStorage("breadcrumb.capture.shortcut") private var captureShortcutRaw = CaptureShortcut.optionSpace.rawValue

    @AppStorage(BreadcrumbPreferences.defaultAccentHexKey) private var defaultAccentHex = BreadcrumbPreferences.defaultAccentHex
    @AppStorage(BreadcrumbPreferences.markerStyleKey) private var markerStyleRaw = BreadcrumbMarkerStyle.microTab.rawValue
    @AppStorage(BreadcrumbPreferences.markerSizeKey) private var markerSizeRaw = BreadcrumbMarkerSize.medium.rawValue
    @AppStorage(BreadcrumbPreferences.appearanceModeKey) private var appearanceModeRaw = BreadcrumbAppearanceMode.system.rawValue
    @AppStorage(BreadcrumbPreferences.reducedMotionKey) private var reducedMotion = false
    @AppStorage(BreadcrumbPreferences.shadowStrengthKey) private var shadowStrengthRaw = BreadcrumbShadowStrength.standard.rawValue

    let onOpenLibrary: () -> Void
    let onOpenDiagnostics: () -> Void
    let onShowOnboarding: () -> Void

    var body: some View {
        TabView {
            general
                .tabItem { Label("General", systemImage: "gearshape") }

            appearance
                .tabItem { Label("Appearance", systemImage: "paintpalette") }

            context
                .tabItem { Label("Context", systemImage: "scope") }

            data
                .tabItem { Label("Data", systemImage: "externaldrive") }

            advanced
                .tabItem { Label("Advanced", systemImage: "wrench.and.screwdriver") }
        }
        .frame(width: 620, height: 500)
    }

    private var general: some View {
        Form {
            Section("Capture") {
                Picker("New breadcrumb", selection: Binding(
                    get: {
                        CaptureShortcut(rawValue: captureShortcutRaw) ?? .optionSpace
                    },
                    set: { shortcut in
                        captureShortcutRaw = shortcut.rawValue
                        NotificationCenter.default.post(
                            name: HotKeyManager.shortcutDidChange,
                            object: nil
                        )
                    }
                )) {
                    ForEach(CaptureShortcut.allCases) { shortcut in
                        Text(shortcut.title).tag(shortcut)
                    }
                }

                Text("The shortcut works globally and opens the capture palette beside your pointer.")
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
        .padding(.horizontal, 8)
    }

    private var appearance: some View {
        Form {
            Section("Breadcrumbs") {
                ColorPicker(
                    "Default accent color",
                    selection: Binding(
                        get: {
                            BreadcrumbColor.color(fromHex: defaultAccentHex)
                                ?? BreadcrumbColor.lavender.color
                        },
                        set: { color in
                            if let hex = BreadcrumbColor.hex(from: color) {
                                defaultAccentHex = hex
                                BreadcrumbPreferences.notifyAppearanceChanged()
                            }
                        }
                    ),
                    supportsOpacity: false
                )

                Picker("Marker style", selection: Binding(
                    get: {
                        BreadcrumbMarkerStyle(rawValue: markerStyleRaw) ?? .microTab
                    },
                    set: { value in
                        markerStyleRaw = value.rawValue
                        BreadcrumbPreferences.notifyAppearanceChanged()
                    }
                )) {
                    ForEach(BreadcrumbMarkerStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }

                Picker("Micro-tab size", selection: Binding(
                    get: {
                        BreadcrumbMarkerSize(rawValue: markerSizeRaw) ?? .medium
                    },
                    set: { value in
                        markerSizeRaw = value.rawValue
                        BreadcrumbPreferences.notifyAppearanceChanged()
                    }
                )) {
                    ForEach(BreadcrumbMarkerSize.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
            }

            Section("Interface") {
                Picker("Appearance", selection: Binding(
                    get: {
                        BreadcrumbAppearanceMode(rawValue: appearanceModeRaw) ?? .system
                    },
                    set: { value in
                        appearanceModeRaw = value.rawValue
                        BreadcrumbPreferences.notifyAppearanceChanged()
                    }
                )) {
                    ForEach(BreadcrumbAppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }

                Toggle("Reduce motion", isOn: Binding(
                    get: { reducedMotion },
                    set: { value in
                        reducedMotion = value
                        BreadcrumbPreferences.notifyAppearanceChanged()
                    }
                ))

                Picker("Shadow strength", selection: Binding(
                    get: {
                        BreadcrumbShadowStrength(rawValue: shadowStrengthRaw) ?? .standard
                    },
                    set: { value in
                        shadowStrengthRaw = value.rawValue
                        BreadcrumbPreferences.notifyAppearanceChanged()
                    }
                )) {
                    ForEach(BreadcrumbShadowStrength.allCases) { strength in
                        Text(strength.title).tag(strength)
                    }
                }
            }

            Section {
                Text("Appearance changes apply immediately. The default accent color is used for new breadcrumbs; existing breadcrumbs keep their own selected color.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
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
                    Picker("Resurface after being away", selection: $autoResumeCooldownMinutes) {
                        Text("5 minutes").tag(5.0)
                        Text("15 minutes").tag(15.0)
                        Text("30 minutes").tag(30.0)
                        Text("1 hour").tag(60.0)
                    }
                }

                Text("Breadcrumb resurfaces a context summary only after you leave it for the selected amount of time and return.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Text("Contexts with 5 or more active breadcrumbs collapse into one compact stack instead of covering the window.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 8)
    }

    private var data: some View {
        Form {
            Section("Storage") {
                LabeledContent("Breadcrumbs") {
                    Text("Stored on this Mac")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Recovery") {
                    Text("Automatic local backup")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Privacy") {
                Text("No account is required. Breadcrumb notes and window metadata stay on this Mac. No analytics or automatic diagnostic uploads are used.")
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

                Button("Copy Support Summary") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(
                        DiagnosticLog.shared.supportSummary(),
                        forType: .string
                    )
                }

                Text("The support summary includes app version, macOS version, permission state, and diagnostic event summaries. It omits breadcrumb note text and detailed diagnostic payloads.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Section("Onboarding") {
                Button("Show Welcome Screen Again", action: onShowOnboarding)
            }

            Section("About") {
                LabeledContent("Breadcrumb") {
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Build") {
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—")
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
