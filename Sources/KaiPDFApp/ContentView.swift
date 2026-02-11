import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedCompression: CompressionLevel = .ebook
    @State private var reorderInputURL: URL?
    @State private var showQueue = false

    private let columns = [
        GridItem(.adaptive(minimum: 220), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        actionCard(
                            title: "Merge PDFs",
                            subtitle: "Combine multiple PDFs into one",
                            buttonTitle: "Start"
                        ) { mergePDFs() }

                        actionCard(
                            title: "Split PDF",
                            subtitle: "Export each page as separate PDF",
                            buttonTitle: "Start"
                        ) { splitPDF() }

                        actionCard(
                            title: "Reorder Pages",
                            subtitle: "Drag and drop page thumbnails",
                            buttonTitle: "Open Studio"
                        ) { openReorderStudio() }

                        actionCardWithAccessory(
                            title: "Compress PDF",
                            subtitle: "Reduce file size offline",
                            buttonTitle: "Compress"
                        ) {
                            compressPDF()
                        } accessory: {
                            Picker("Compression", selection: $selectedCompression) {
                                ForEach(CompressionLevel.allCases) { level in
                                    Text(level.rawValue.capitalized).tag(level)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 130)
                        }

                        actionCard(
                            title: "Word -> PDF",
                            subtitle: "Convert .doc/.docx using local LibreOffice",
                            buttonTitle: "Convert"
                        ) { wordToPDF() }

                        actionCard(
                            title: "PDF -> Word",
                            subtitle: "Convert to .docx locally",
                            buttonTitle: "Convert"
                        ) { pdfToWord() }
                    }

                    DisclosureGroup(isExpanded: $showQueue) {
                        QueuePanelView()
                            .environmentObject(appState)
                            .padding(.top, 10)
                    } label: {
                        Text("Batch Queue (Advanced)")
                            .font(.headline)
                    }
                    .padding(14)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(20)
            }

            Divider()
            LogsView()
                .padding(12)
        }
        .sheet(item: $reorderInputURL) { url in
            ReorderStudioView(inputURL: url)
                .environmentObject(appState)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("KaiPDF")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("Offline PDF and Word tools for macOS")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("No Cloud")
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.10), Color.cyan.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func actionCard(
        title: String,
        subtitle: String,
        buttonTitle: String,
        action: @escaping () -> Void,
        accessory: (() -> AnyView)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 2)

            HStack {
                if let accessory {
                    accessory()
                }
                Spacer()
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .frame(minHeight: 140)
        .background(Color.gray.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func mergePDFs() {
        let input = FilePickers.pickFiles(allowedTypes: ["pdf"])
        guard !input.isEmpty else { return }
        guard let output = FilePickers.saveFile(defaultName: "merged.pdf", allowedTypes: ["pdf"]) else { return }

        appState.runTask(title: "Merge PDFs") {
            try appState.pdfService.merge(inputURLs: input, outputURL: output)
        }
    }

    private func splitPDF() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["pdf"], allowsMultiple: false).first else { return }
        guard let outDir = FilePickers.pickDirectory() else { return }

        appState.runTask(title: "Split PDF") {
            try appState.pdfService.split(inputURL: input, outputDirectory: outDir)
        }
    }

    private func openReorderStudio() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["pdf"], allowsMultiple: false).first else { return }
        reorderInputURL = input
    }

    private func compressPDF() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["pdf"], allowsMultiple: false).first else { return }
        guard let output = FilePickers.saveFile(defaultName: "compressed.pdf", allowedTypes: ["pdf"]) else { return }

        appState.runTask(title: "Compress PDF") {
            try appState.pdfService.compress(inputURL: input, outputURL: output, level: selectedCompression)
        }
    }

    private func wordToPDF() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["doc", "docx"], allowsMultiple: false).first else { return }
        guard let outDir = FilePickers.pickDirectory() else { return }

        appState.runTask(title: "Word -> PDF") {
            try appState.conversionService.wordToPDF(inputURL: input, outputDirectory: outDir)
        }
    }

    private func pdfToWord() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["pdf"], allowsMultiple: false).first else { return }
        guard let outDir = FilePickers.pickDirectory() else { return }

        appState.runTask(title: "PDF -> Word") {
            try appState.conversionService.pdfToWord(inputURL: input, outputDirectory: outDir)
        }
    }
}

private struct QueuePanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCompression: CompressionLevel = .ebook

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button("+ Merge") { queueMerge() }
                Button("+ Split") { queueSplit() }
                Button("+ Word->PDF") { queueWordToPDF() }
                Button("+ PDF->Word") { queuePDFToWord() }
                Picker("Compression", selection: $selectedCompression) {
                    ForEach(CompressionLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .frame(width: 140)
                Button("+ Compress") { queueCompress() }
            }

            HStack {
                Button(appState.isRunningQueue ? "Running..." : "Run Queue") {
                    appState.runQueue()
                }
                .disabled(appState.isRunningQueue)

                Button("Clear Completed") {
                    appState.clearCompleted()
                }
            }

            List {
                ForEach(appState.queue) { item in
                    HStack {
                        Text(item.job.description)
                        Spacer()
                        Text(item.status.rawValue)
                            .foregroundStyle(color(for: item.status))
                    }
                }
            }
            .frame(minHeight: 180)
        }
    }

    private func queueMerge() {
        let inputs = FilePickers.pickFiles(allowedTypes: ["pdf"])
        guard !inputs.isEmpty else { return }
        guard let output = FilePickers.saveFile(defaultName: "merged.pdf", allowedTypes: ["pdf"]) else { return }
        appState.addJob(.init(type: .mergePDF, inputs: inputs, output: output, metadata: [:]))
    }

    private func queueSplit() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["pdf"], allowsMultiple: false).first else { return }
        guard let outputDir = FilePickers.pickDirectory() else { return }
        appState.addJob(.init(type: .splitPDF, inputs: [input], output: outputDir, metadata: [:]))
    }

    private func queueWordToPDF() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["doc", "docx"], allowsMultiple: false).first else { return }
        guard let outputDir = FilePickers.pickDirectory() else { return }
        appState.addJob(.init(type: .wordToPDF, inputs: [input], output: outputDir, metadata: [:]))
    }

    private func queuePDFToWord() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["pdf"], allowsMultiple: false).first else { return }
        guard let outputDir = FilePickers.pickDirectory() else { return }
        appState.addJob(.init(type: .pdfToWord, inputs: [input], output: outputDir, metadata: [:]))
    }

    private func queueCompress() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["pdf"], allowsMultiple: false).first else { return }
        guard let output = FilePickers.saveFile(defaultName: "compressed.pdf", allowedTypes: ["pdf"]) else { return }
        appState.addJob(.init(type: .compressPDF, inputs: [input], output: output, metadata: ["level": selectedCompression.rawValue]))
    }

    private func color(for status: JobStatus) -> Color {
        switch status {
        case .pending: return .secondary
        case .running: return .blue
        case .succeeded: return .green
        case .failed: return .red
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
            .frame(height: 130)
            .padding(8)
            .background(Color.gray.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private extension ContentView {
    func actionCardWithAccessory(
        title: String,
        subtitle: String,
        buttonTitle: String,
        action: @escaping () -> Void,
        @ViewBuilder accessory: @escaping () -> some View
    ) -> some View {
        actionCard(
            title: title,
            subtitle: subtitle,
            buttonTitle: buttonTitle,
            action: action,
            accessory: { AnyView(accessory()) }
        )
    }
}
