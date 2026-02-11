import Foundation

enum AppError: LocalizedError {
    case invalidInput(String)
    case commandFailure(String)
    case runtime(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let msg), .commandFailure(let msg), .runtime(let msg):
            return msg
        }
    }
}

enum CompressionLevel: String, CaseIterable, Identifiable {
    case screen
    case ebook
    case printer
    case prepress

    var id: String { rawValue }

    var ghostscriptSetting: String {
        switch self {
        case .screen: return "/screen"
        case .ebook: return "/ebook"
        case .printer: return "/printer"
        case .prepress: return "/prepress"
        }
    }
}

struct QueueJob: Identifiable {
    enum JobType: String, CaseIterable {
        case mergePDF
        case splitPDF
        case compressPDF
        case wordToPDF
        case pdfToWord
    }

    let id = UUID()
    let type: JobType
    let inputs: [URL]
    let output: URL
    let metadata: [String: String]

    var description: String {
        "\(type.rawValue) -> \(output.lastPathComponent)"
    }
}

enum JobStatus: String {
    case pending
    case running
    case succeeded
    case failed
}

struct QueueItem: Identifiable {
    let id = UUID()
    let job: QueueJob
    var status: JobStatus = .pending
    var message: String = "Waiting"
}
