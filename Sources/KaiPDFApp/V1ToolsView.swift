import AppKit
import SwiftUI

struct V1ToolsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCompression: CompressionLevel = .ebook
    @State private var reorderInputURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("V1: Native PDFKit tools (fully offline)")
                .font(.title3).bold()

            GroupBox("Merge PDFs") {
                HStack {
                    Button("Pick PDFs and Merge") {
                        mergePDFs()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Split PDF") {
                Button("Pick PDF and Output Folder") {
                    splitPDF()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Reorder PDF Pages") {
                HStack {
                    Button("Quick Reorder (comma sequence)") {
                        reorderPDFQuick()
                    }
                    Button("Open Drag-and-Drop Reorder Studio") {
                        openReorderStudio()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Compress PDF") {
                HStack {
                    Picker("Profile", selection: $selectedCompression) {
                        ForEach(CompressionLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)

                    Button("Pick PDF and Compress") {
                        compressPDF()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding()
        .sheet(item: $reorderInputURL) { url in
            ReorderStudioView(inputURL: url)
                .environmentObject(appState)
        }
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

    private func reorderPDFQuick() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["pdf"], allowsMultiple: false).first else { return }
        guard let output = FilePickers.saveFile(defaultName: "reordered.pdf", allowedTypes: ["pdf"]) else { return }

        let orderRaw = prompt("Enter page order as comma separated numbers (example: 3,1,2)")
        let order = orderRaw?
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) } ?? []

        appState.runTask(title: "Reorder PDF") {
            try appState.pdfService.reorder(inputURL: input, order: order, outputURL: output)
        }
    }

    private func compressPDF() {
        guard let input = FilePickers.pickFiles(allowedTypes: ["pdf"], allowsMultiple: false).first else { return }
        guard let output = FilePickers.saveFile(defaultName: "compressed.pdf", allowedTypes: ["pdf"]) else { return }

        appState.runTask(title: "Compress PDF") {
            try appState.pdfService.compress(inputURL: input, outputURL: output, level: selectedCompression)
        }
    }

    private func prompt(_ message: String) -> String? {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: .init(x: 0, y: 0, width: 280, height: 24))
        input.stringValue = ""
        alert.accessoryView = input

        let response = alert.runModal()
        return response == .alertFirstButtonReturn ? input.stringValue : nil
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
