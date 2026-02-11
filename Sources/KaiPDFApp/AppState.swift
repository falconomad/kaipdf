import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var logs: [String] = []
    @Published var queue: [QueueItem] = []
    @Published var isRunningQueue = false

    let pdfService = PDFService()
    let conversionService = ConversionService()
    private let queueProcessor = QueueProcessor()

    func log(_ message: String) {
        logs.insert("[\(Self.timestamp())] \(message)", at: 0)
    }

    func runTask(title: String, _ operation: () throws -> Void) {
        do {
            try operation()
            log("\(title): success")
        } catch {
            log("\(title): \(error.localizedDescription)")
        }
    }

    func addJob(_ job: QueueJob) {
        queue.append(QueueItem(job: job))
        log("Queued: \(job.description)")
    }

    func runQueue() {
        guard !isRunningQueue else { return }
        isRunningQueue = true

        Task {
            defer { isRunningQueue = false }

            for idx in queue.indices {
                if queue[idx].status != .pending { continue }
                queue[idx].status = .running
                queue[idx].message = "Running"

                do {
                    try queueProcessor.run(queue[idx])
                    queue[idx].status = .succeeded
                    queue[idx].message = "Done"
                    log("Queue success: \(queue[idx].job.description)")
                } catch {
                    queue[idx].status = .failed
                    queue[idx].message = error.localizedDescription
                    log("Queue failed: \(queue[idx].job.description) - \(error.localizedDescription)")
                }
            }
        }
    }

    func clearCompleted() {
        queue.removeAll { $0.status == .succeeded }
    }

    private static func timestamp() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        return fmt.string(from: Date())
    }
}
