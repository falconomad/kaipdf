import AppKit
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct ReorderPageItem: Identifiable, Equatable {
    let id = UUID()
    let sourcePage: Int
    let thumbnail: NSImage
}

struct ReorderStudioView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    let inputURL: URL

    @State private var items: [ReorderPageItem] = []
    @State private var error: String?

    private let cardSize = CGSize(width: 160, height: 220)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reorder Pages")
                .font(.title2).bold()
            Text(inputURL.lastPathComponent)
                .foregroundStyle(.secondary)

            if let error {
                Text(error)
                    .foregroundStyle(.red)
            }

            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(items) { item in
                        VStack(spacing: 8) {
                            Image(nsImage: item.thumbnail)
                                .resizable()
                                .scaledToFit()
                                .frame(width: cardSize.width, height: cardSize.height)
                                .background(Color.gray.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Text("Page \(item.sourcePage)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.001))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        }
                        .onDrag {
                            NSItemProvider(object: NSString(string: item.id.uuidString))
                        }
                        .onDrop(of: [UTType.text], delegate: ReorderDropDelegate(target: item, items: $items))
                    }
                }
                .padding(.vertical, 8)
            }

            HStack {
                Button("Save Reordered PDF") {
                    saveReorderedPDF()
                }
                Button("Close") {
                    dismiss()
                }
            }
        }
        .padding()
        .frame(minWidth: 900, minHeight: 420)
        .onAppear {
            loadPages()
        }
    }

    private func loadPages() {
        guard let doc = PDFDocument(url: inputURL) else {
            error = "Could not open PDF"
            return
        }

        var pageItems: [ReorderPageItem] = []
        let thumbSize = NSSize(width: 280, height: 380)

        for idx in 0..<doc.pageCount {
            guard let page = doc.page(at: idx) else { continue }
            let image = page.thumbnail(of: thumbSize, for: .mediaBox)
            pageItems.append(ReorderPageItem(sourcePage: idx + 1, thumbnail: image))
        }

        items = pageItems
    }

    private func saveReorderedPDF() {
        guard let output = FilePickers.saveFile(defaultName: "reordered.pdf", allowedTypes: ["pdf"]) else { return }
        let order = items.map(\.sourcePage)

        appState.runTask(title: "Reorder PDF") {
            try appState.pdfService.reorder(inputURL: inputURL, order: order, outputURL: output)
        }
    }
}

private struct ReorderDropDelegate: DropDelegate {
    let target: ReorderPageItem
    @Binding var items: [ReorderPageItem]

    func dropEntered(info: DropInfo) {
        guard
            let provider = info.itemProviders(for: [UTType.text]).first
        else { return }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard
                let nsString = object as? NSString,
                let raw = nsString as String?,
                let sourceID = UUID(uuidString: raw)
            else { return }

            DispatchQueue.main.async {
                guard
                    let from = items.firstIndex(where: { $0.id == sourceID }),
                    let to = items.firstIndex(of: target),
                    from != to
                else { return }

                withAnimation {
                    let moving = items.remove(at: from)
                    items.insert(moving, at: to)
                }
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool { true }
}
