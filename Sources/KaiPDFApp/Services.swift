import Foundation
import PDFKit

struct Shell {
    @discardableResult
    static func run(_ launchPath: String, args: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = args

        let out = Pipe()
        let err = Pipe()
        process.standardOutput = out
        process.standardError = err

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw AppError.commandFailure(stderr.isEmpty ? stdout : stderr)
        }

        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

final class PDFService {
    func merge(inputURLs: [URL], outputURL: URL) throws {
        guard !inputURLs.isEmpty else { throw AppError.invalidInput("Select at least one PDF") }

        let merged = PDFDocument()
        var pageIndex = 0

        for url in inputURLs {
            guard let doc = PDFDocument(url: url) else {
                throw AppError.runtime("Could not open PDF: \(url.lastPathComponent)")
            }
            for i in 0..<doc.pageCount {
                guard let page = doc.page(at: i) else { continue }
                merged.insert(page, at: pageIndex)
                pageIndex += 1
            }
        }

        guard merged.write(to: outputURL) else {
            throw AppError.runtime("Could not write merged PDF")
        }
    }

    func split(inputURL: URL, outputDirectory: URL) throws {
        guard let doc = PDFDocument(url: inputURL) else {
            throw AppError.runtime("Could not open PDF")
        }

        let base = inputURL.deletingPathExtension().lastPathComponent
        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i) else { continue }
            let single = PDFDocument()
            single.insert(page, at: 0)
            let outURL = outputDirectory.appendingPathComponent("\(base)-page-\(i + 1).pdf")
            guard single.write(to: outURL) else {
                throw AppError.runtime("Failed splitting at page \(i + 1)")
            }
        }
    }

    func reorder(inputURL: URL, order: [Int], outputURL: URL) throws {
        guard let doc = PDFDocument(url: inputURL) else {
            throw AppError.runtime("Could not open PDF")
        }
        guard Set(order).count == order.count else {
            throw AppError.invalidInput("Duplicate page numbers in reorder sequence")
        }

        let reordered = PDFDocument()
        for (idx, pageNumber) in order.enumerated() {
            let sourceIndex = pageNumber - 1
            guard sourceIndex >= 0, sourceIndex < doc.pageCount else {
                throw AppError.invalidInput("Invalid page number: \(pageNumber)")
            }
            guard let page = doc.page(at: sourceIndex) else { continue }
            reordered.insert(page, at: idx)
        }

        guard reordered.write(to: outputURL) else {
            throw AppError.runtime("Could not write reordered PDF")
        }
    }

    func compress(inputURL: URL, outputURL: URL, level: CompressionLevel) throws {
        let gs = ["/opt/homebrew/bin/gs", "/usr/local/bin/gs", "/usr/bin/gs"]
            .first(where: { FileManager.default.fileExists(atPath: $0) })

        guard let gsPath = gs else {
            throw AppError.runtime("Ghostscript not found. Install with: brew install ghostscript")
        }

        _ = try Shell.run(gsPath, args: [
            "-sDEVICE=pdfwrite",
            "-dCompatibilityLevel=1.4",
            "-dPDFSETTINGS=\(level.ghostscriptSetting)",
            "-dNOPAUSE",
            "-dBATCH",
            "-dQUIET",
            "-sOutputFile=\(outputURL.path)",
            inputURL.path
        ])
    }
}

final class ConversionService {
    private let fm = FileManager.default

    func wordToPDF(inputURL: URL, outputDirectory: URL) throws {
        try convertWithSoffice(inputURL: inputURL, outputDirectory: outputDirectory, targetFormat: "pdf")
    }

    func pdfToWord(inputURL: URL, outputDirectory: URL) throws {
        try convertWithSoffice(inputURL: inputURL, outputDirectory: outputDirectory, targetFormat: "docx")
    }

    private func convertWithSoffice(inputURL: URL, outputDirectory: URL, targetFormat: String) throws {
        let candidates = [
            "/Applications/LibreOffice.app/Contents/MacOS/soffice",
            "/opt/homebrew/bin/soffice",
            "/usr/local/bin/soffice"
        ]

        guard let soffice = candidates.first(where: { fm.fileExists(atPath: $0) }) else {
            throw AppError.runtime("LibreOffice not found. Install LibreOffice to enable offline Word/PDF conversion.")
        }

        _ = try Shell.run(soffice, args: [
            "--headless",
            "--convert-to", targetFormat,
            "--outdir", outputDirectory.path,
            inputURL.path
        ])
    }
}

final class QueueProcessor {
    private let pdfService = PDFService()
    private let conversionService = ConversionService()

    func run(_ item: QueueItem) throws {
        let job = item.job

        switch job.type {
        case .mergePDF:
            try pdfService.merge(inputURLs: job.inputs, outputURL: job.output)
        case .splitPDF:
            guard let first = job.inputs.first else { throw AppError.invalidInput("Missing split input") }
            try pdfService.split(inputURL: first, outputDirectory: job.output)
        case .compressPDF:
            guard let first = job.inputs.first else { throw AppError.invalidInput("Missing compress input") }
            let levelRaw = job.metadata["level"] ?? CompressionLevel.ebook.rawValue
            let level = CompressionLevel(rawValue: levelRaw) ?? .ebook
            try pdfService.compress(inputURL: first, outputURL: job.output, level: level)
        case .wordToPDF:
            guard let first = job.inputs.first else { throw AppError.invalidInput("Missing input") }
            try conversionService.wordToPDF(inputURL: first, outputDirectory: job.output)
        case .pdfToWord:
            guard let first = job.inputs.first else { throw AppError.invalidInput("Missing input") }
            try conversionService.pdfToWord(inputURL: first, outputDirectory: job.output)
        }
    }
}
