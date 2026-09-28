import SwiftUI

struct ComposerView: View {
    @State private var text = ""
    @FocusState private var isFocused: Bool

    let contextAvailable: Bool
    let contextLabel: String?
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "circle.dotted")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField(
                    contextAvailable ? "Leave a thought…" : "Window context unavailable",
                    text: $text
                )
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($isFocused)
                .disabled(!contextAvailable)
                .onSubmit(submit)
                .onExitCommand(perform: onCancel)

                if contextAvailable {
                    Image(systemName: "return")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                } else {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                }
            }

            if contextAvailable {
                if let contextLabel, !contextLabel.isEmpty {
                    Text(contextLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .padding(.leading, 24)
                }
            } else {
                Text("Breadcrumb opened, but macOS did not provide a precise focused-window context. Check Accessibility permission and Context Diagnostics.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.leading, 24)
            }
        }
        .padding(.horizontal, 14)
        .frame(width: 380, height: contextAvailable ? 58 : 76)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.primary.opacity(0.10), lineWidth: 0.5)
        }
        .shadow(radius: 18, y: 8)
        .onAppear {
            if contextAvailable {
                DispatchQueue.main.async {
                    isFocused = true
                }
            }
        }
    }

    private func submit() {
        guard contextAvailable else { return }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
    }
}
