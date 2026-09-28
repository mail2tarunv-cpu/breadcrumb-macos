import SwiftUI

struct DiagnosticsView: View {
    @State private var events: [DiagnosticEvent]
    @State private var selectedCategory = "All"
    @State private var searchText = ""

    let onRefresh: () -> [DiagnosticEvent]
    let onClear: () -> Void

    private let timer = Timer.publish(
        every: 1,
        on: .main,
        in: .common
    ).autoconnect()

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
        var source = selectedCategory == "All"
            ? events
            : events.filter { $0.category == selectedCategory }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !query.isEmpty {
            source = source.filter {
                $0.category.localizedCaseInsensitiveContains(query)
                || $0.summary.localizedCaseInsensitiveContains(query)
                || $0.detail.localizedCaseInsensitiveContains(query)
            }
        }

        return source.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Context Diagnostics")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Live record of what Breadcrumb detects and every show/hide decision.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .frame(width: 165)

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
                    description: Text("Switch windows or create a breadcrumb to generate context events.")
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

                            Text(
                                event.timestamp.formatted(
                                    date: .abbreviated,
                                    time: .standard
                                )
                            )
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
                    .padding(.vertical, 7)
                }
                .listStyle(.inset)
            }
        }
        .searchable(
            text: $searchText,
            placement: .toolbar,
            prompt: "Search logs"
        )
        .frame(minWidth: 860, minHeight: 620)
        .onReceive(timer) { _ in
            events = onRefresh()
        }
    }
}
