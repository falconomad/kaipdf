import SwiftUI

struct V2ConversionView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("V2: Offline Word/PDF conversion")
                .font(.title3).bold()

            Text("Uses local LibreOffice CLI if installed. No network calls are made.")
                .foregroundStyle(.secondary)

            GroupBox("Word -> PDF") {
                Button("Pick .doc/.docx and convert") {
                    wordToPDF()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("PDF -> Word") {
                Button("Pick .pdf and convert to .docx") {
                    pdfToWord()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding()
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
