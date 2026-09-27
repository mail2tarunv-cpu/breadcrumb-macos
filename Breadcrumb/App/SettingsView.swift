import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Capture") {
                LabeledContent("New Breadcrumb") {
                    Text("⌥ Space")
                        .foregroundStyle(.secondary)
                }
            }

            Section("About") {
                Text("Breadcrumb keeps thoughts attached to the context where they happened.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 240)
        .padding()
    }
}
