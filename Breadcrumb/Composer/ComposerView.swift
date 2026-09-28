import SwiftUI

struct ComposerView: View {
    @State private var text = ""
    @FocusState private var isFocused: Bool

    let contextAvailable: Bool
    let contextLabel: String?
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: "circle.dotted")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(contextAvailable ? "New breadcrumb" : "Window awareness unavailable")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("esc")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.quaternary.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }

            if contextAvailable {
                TextField("What do you want to remember here?", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .lineLimit(1...4)
                    .focused($isFocused)
                    .onSubmit(submit)
                    .onExitCommand(perform: onCancel)

                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 8))
                    Text(contextLabel ?? "Current window")
                        .lineLimit(1)
                    Spacer()
                    Text("↩ Save")
                        .fontWeight(.medium)
                }
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)
            } else {
                Text("Breadcrumb can’t read the focused window right now.")
                    .font(.system(size: 14, weight: .medium))

                Text("Check Accessibility permission, then try again.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 420)
        .frame(minHeight: contextAvailable ? 108 : 112)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(.primary.opacity(0.10), lineWidth: 0.7)
        }
        .shadow(radius: 24, y: 10)
        .onAppear {
            if contextAvailable {
                DispatchQueue.main.async { isFocused = true }
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
