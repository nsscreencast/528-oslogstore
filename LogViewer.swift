import Foundation
import SwiftUI
import OSLog

private extension OSLogEntryLog {
    var color: UIColor {
        switch level {
        case .debug: return .yellow
        case .error, .fault: return .red
        default:
            return .gray
        }
    }
}

final class LogViewModel: ObservableObject {
    let logStore: OSLogStore

    struct Entry: Identifiable {
        let id = UUID()
        let date: String
        let category: String
        let message: String
        let color: UIColor
    }

    @Published var entries: [Entry] = []

    init() {
        logStore = try! OSLogStore(scope: .currentProcessIdentifier)

        let position = logStore.position(date: Date().addingTimeInterval(-86400))
        entries = try! logStore.getEntries(at: position)
            .compactMap { $0 as? OSLogEntryLog }
            .filter { $0.subsystem.starts(with: "com.nsscreencast") }
            .map {
                Entry(date: $0.date.formatted(), category: $0.category, message: $0.composedMessage, color: $0.color)
            }
    }
}

struct LogViewer: View {
    @ObservedObject var viewModel = LogViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.entries) { entry in
                LogEntryRow(entry: entry)
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Logs")
        }
    }
}

struct LogEntryRow: View {
    let entry: LogViewModel.Entry

    var body: some View {
        HStack {
            Color(entry.color)
                .frame(width: 4)

            VStack(spacing: 12) {
                HStack {
                    Text(entry.date)
                    Spacer()
                    Text(entry.category)
                }
                .foregroundColor(Color(uiColor: .secondaryLabel))

                Text(entry.message)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.caption)
        }
    }
}

class LogViewerController: UIHostingController<LogViewer> {
    init() {
        super.init(rootView: LogViewer())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
