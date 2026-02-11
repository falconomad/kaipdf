import SwiftUI

struct V3BatchView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCompression: CompressionLevel = .ebook

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("V3: Batch Queue")
                .font(.title3).bold()

            HStack {
                Button("Queue Merge PDFs") { queueMerge() }
                Button("Queue Split PDF") { queueSplit() }
                Button("Queue Word -> PDF") { queueWordToPDF() }
                Button("Queue PDF -> Word") { queuePDFToWord() }
                Picker("Compression", selection: $selectedCompression) {
                    ForEach(CompressionLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .frame(width: 150)
                Button("Queue Compress PDF") { queueCompress() }
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
                        Text(item.message)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    private func queueMerge() {
        let inputs = FilePickers.pickFiles(allowedTypes: ["pdf"])
        guard !inputs.isEmpty else { return }
        guard let output = FilePickers.saveFile(defaultName: "merged.pdf", allowedTypes: ["pdf"]) else { return }

        let job = QueueJob(type: .mergePDF, inputs: inputs, output: output, metadata: [:])
        appState.addJob(job)
    }

    private func queueSplit() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["pdf"], allowsMultiple: false).first else { return }
        guard let outputDir = FilePickers.pickDirectory() else { return }

        let job = QueueJob(type: .splitPDF, inputs: [input], output: outputDir, metadata: [:])
        appState.addJob(job)
    }

    private func queueWordToPDF() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["doc", "docx"], allowsMultiple: false).first else { return }
        guard let outputDir = FilePickers.pickDirectory() else { return }

        let job = QueueJob(type: .wordToPDF, inputs: [input], output: outputDir, metadata: [:])
        appState.addJob(job)
    }

    private func queuePDFToWord() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["pdf"], allowsMultiple: false).first else { return }
        guard let outputDir = FilePickers.pickDirectory() else { return }

        let job = QueueJob(type: .pdfToWord, inputs: [input], output: outputDir, metadata: [:])
        appState.addJob(job)
    }

    private func queueCompress() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["pdf"], allowsMultiple: false).first else { return }
        guard let output = FilePickers.saveFile(defaultName: "compressed.pdf", allowedTypes: ["pdf"]) else { return }

        let job = QueueJob(
            type: .compressPDF,
            inputs: [input],
            output: output,
            metadata: ["level": selectedCompression.rawValue]
        )
        appState.addJob(job)
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
