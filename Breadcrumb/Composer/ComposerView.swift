import SwiftUI

struct ComposerView: View {
    @State private var text = ""
    @FocusState private var isFocused: Bool

    let contextAvailable: Bool
    let contextLabel: String?
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "circle.dotted")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 5) {
                    if contextAvailable {
                        TextField("Leave a thought here…", text: $text, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .lineLimit(1...4)
                            .focused($isFocused)
                            .onSubmit(submit)
                            .onExitCommand(perform: onCancel)

                        if let contextLabel, !contextLabel.isEmpty {
                            Text(contextLabel)
                                .font(.system(size: 10.5))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Window awareness unavailable")
                            .font(.system(size: 13, weight: .semibold))

                        Text("Check Accessibility permission, then try again.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                if contextAvailable {
                    Text("↩")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.tertiary)
                } else {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            HStack {
                Text("⌥ Space")
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)

                Spacer()

                Text("Esc to close")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 9)
        }
        .frame(width: 390)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 0.5)
        }
        .shadow(radius: 18, y: 8)
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
