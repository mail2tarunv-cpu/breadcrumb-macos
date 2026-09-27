import SwiftUI

struct ComposerView: View {
    @State private var text = ""
    @FocusState private var isFocused: Bool

    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "circle.dotted")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Leave a thought…", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($isFocused)
                .onSubmit(submit)
                .onExitCommand(perform: onCancel)
        }
        .padding(.horizontal, 14)
        .frame(width: 340, height: 46)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 0.5)
        }
        .shadow(radius: 18, y: 8)
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
        }
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
    }
}
