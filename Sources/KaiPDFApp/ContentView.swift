import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                V1ToolsView()
                    .tabItem { Text("V1 PDF Tools") }
                V2ConversionView()
                    .tabItem { Text("V2 Conversion") }
                V3BatchView()
                    .tabItem { Text("V3 Batch") }
            }

            Divider()

            LogsView()
                .frame(maxWidth: .infinity)
                .padding(12)
        }
    }
}

private struct LogsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity Log")
                .font(.headline)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(appState.logs, id: \.self) { line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(height: 150)
            .padding(8)
            .background(Color.gray.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
