import SwiftUI

struct DiagnosticsView: View {
    @State private var events: [DiagnosticEvent]
    @State private var selectedCategory = "All"

    let onRefresh: () -> [DiagnosticEvent]
    let onClear: () -> Void

    init(
        events: [DiagnosticEvent],
        onRefresh: @escaping () -> [DiagnosticEvent],
        onClear: @escaping () -> Void
    ) {
        _events = State(initialValue: events)
        self.onRefresh = onRefresh
        self.onClear = onClear
    }

    private var categories: [String] {
        ["All"] + Array(Set(events.map(\.category))).sorted()
    }

    private var filteredEvents: [DiagnosticEvent] {
        let source = selectedCategory == "All"
            ? events
            : events.filter { $0.category == selectedCategory }

        return source.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Context Diagnostics")
                        .font(.system(size: 20, weight: .semibold))
                    Text("What Breadcrumb detected and why a marker showed or hid.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .frame(width: 160)

                Button {
                    events = onRefresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")

                Button("Clear") {
                    onClear()
                    events = []
                }
            }
            .padding(18)

            Divider()

            if filteredEvents.isEmpty {
                ContentUnavailableView(
                    "No Diagnostic Events",
                    systemImage: "waveform.path.ecg",
                    description: Text("Create a breadcrumb or switch between windows to generate context events.")
                )
            } else {
                List(filteredEvents) { event in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(event.category.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)

                            Text("·")
                                .foregroundStyle(.tertiary)

                            Text(event.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)

                            Spacer()
                        }

                        Text(event.summary)
                            .font(.system(size: 13, weight: .medium))

                        Text(event.detail)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 6)
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 760, minHeight: 560)
    }
}
