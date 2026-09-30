import SwiftUI

struct OnboardingView: View {
    @AppStorage("breadcrumb.capture.shortcut") private var captureShortcutRaw = CaptureShortcut.optionSpace.rawValue
    @AppStorage(BreadcrumbPreferences.defaultAccentColorKey) private var defaultAccentColorRaw = BreadcrumbColor.blue.rawValue
    @AppStorage(BreadcrumbPreferences.markerStyleKey) private var markerStyleRaw = BreadcrumbMarkerStyle.microTab.rawValue
    @AppStorage(BreadcrumbPreferences.markerSizeKey) private var markerSizeRaw = BreadcrumbMarkerSize.medium.rawValue
    @AppStorage(BreadcrumbPreferences.appearanceModeKey) private var appearanceModeRaw = BreadcrumbAppearanceMode.system.rawValue
    @AppStorage(BreadcrumbPreferences.reducedMotionKey) private var reducedMotion = false
    @AppStorage(BreadcrumbPreferences.shadowStrengthKey) private var shadowStrengthRaw = BreadcrumbShadowStrength.standard.rawValue

    let hasAccessibilityAccess: Bool
    let onEnableAccessibility: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 10)

            Image(systemName: "circle.dotted")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.primary)

            VStack(spacing: 6) {
                Text("Leave thoughts where they happen.")
                    .font(.system(size: 24, weight: .semibold))

                Text("Press \((CaptureShortcut(rawValue: captureShortcutRaw) ?? .optionSpace).title) from any app. Breadcrumb remembers the window or tab and brings your thought back when you return.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 430)
            }

            HStack(spacing: 24) {
                step("1", "Capture", (CaptureShortcut(rawValue: captureShortcutRaw) ?? .optionSpace).title)
                step("2", "Leave", "Keep working")
                step("3", "Return", "Pick up again")
            }

            GroupBox("Make Breadcrumb yours") {
                VStack(spacing: 10) {
                    HStack {
                        Text("Default accent")
                            .font(.system(size: 11.5))
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(BreadcrumbColor.allCases) { color in
                                Button {
                                    defaultAccentColorRaw = color.rawValue
                                    BreadcrumbPreferences.notifyAppearanceChanged()
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: 17, height: 17)

                                        if BreadcrumbColor.migrated(from: defaultAccentColorRaw) == color {
                                            Circle()
                                                .stroke(.primary.opacity(0.8), lineWidth: 1.5)
                                                .frame(width: 22, height: 22)
                                        }
                                    }
                                    .frame(width: 24, height: 24)
                                    .contentShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .help(color.name)
                            }
                        }
                    }

                    HStack {
                        Text("Marker style")
                            .font(.system(size: 11.5))
                        Spacer()
                        Picker("", selection: Binding(
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
                        .labelsHidden()
                        .frame(width: 145)
                    }

                    HStack {
                        Text("Micro-tab size")
                            .font(.system(size: 11.5))
                        Spacer()
                        Picker("", selection: Binding(
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
                        .labelsHidden()
                        .frame(width: 145)
                    }

                    HStack {
                        Text("Appearance")
                            .font(.system(size: 11.5))
                        Spacer()
                        Picker("", selection: Binding(
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
                        .labelsHidden()
                        .frame(width: 145)
                    }

                    Toggle("Reduce motion", isOn: Binding(
                        get: { reducedMotion },
                        set: { value in
                            reducedMotion = value
                            BreadcrumbPreferences.notifyAppearanceChanged()
                        }
                    ))
                    .font(.system(size: 11.5))

                    HStack {
                        Text("Shadow strength")
                            .font(.system(size: 11.5))
                        Spacer()
                        Picker("", selection: Binding(
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
                        .labelsHidden()
                        .frame(width: 145)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxWidth: 450)

            Divider()
                .frame(maxWidth: 450)

            if hasAccessibilityAccess {
                VStack(spacing: 10) {
                    Label("Window awareness is enabled", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Button("Start Using Breadcrumb", action: onFinish)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .keyboardShortcut(.defaultAction)
                }
            } else {
                VStack(spacing: 9) {
                    Text("Breadcrumb needs Accessibility permission to know which window a thought belongs to.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)

                    Button("Enable Window Awareness…", action: onEnableAccessibility)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }

            Spacer(minLength: 10)
        }
        .padding(.horizontal, 34)
        .frame(width: 560, height: 620)
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
        .frame(width: 108)
    }
}
