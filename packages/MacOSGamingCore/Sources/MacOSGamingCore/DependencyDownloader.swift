import Foundation

public struct DependencyDownloadProgress: Sendable, Equatable {
    public let dependencyId: String
    public let name: String
    public let fractionCompleted: Double
    public let bytesWritten: Int64
    public let totalBytesExpected: Int64

    public var percentageString: String {
        String(format: "%.0f%%", fractionCompleted * 100.0)
    }

    public var formattedWrittenMB: String {
        String(format: "%.1f MB", Double(bytesWritten) / (1024.0 * 1024.0))
    }

    public var formattedTotalMB: String {
        String(format: "%.1f MB", Double(totalBytesExpected) / (1024.0 * 1024.0))
    }

    public init(
        dependencyId: String,
        name: String,
        fractionCompleted: Double,
        bytesWritten: Int64,
        totalBytesExpected: Int64
    ) {
        self.dependencyId = dependencyId
        self.name = name
        self.fractionCompleted = fractionCompleted
        self.bytesWritten = bytesWritten
        self.totalBytesExpected = totalBytesExpected
    }
}

public enum DependencyDownloadError: Error, LocalizedError, Sendable {
    case missingDownloadURL(String)
    case downloadFailed(String)
    case cancelled
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .missingDownloadURL(let name):
            return "No direct download URL available for '\(name)'."
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        case .cancelled:
            return "Download was cancelled by the user."
        case .invalidResponse:
            return "Invalid server response during download."
        }
    }
}

public final class DependencyDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    public typealias ProgressCallback = @Sendable (DependencyDownloadProgress) -> Void

    private let sessionConfiguration: URLSessionConfiguration
    private var activeSession: URLSession?
    private var activeTask: URLSessionDownloadTask?

    private var currentDependency: GameDependency?
    private var currentProgressCallback: ProgressCallback?
    private var downloadContinuation: CheckedContinuation<URL, Error>?

    private let lock = NSLock()

    public init(configuration: URLSessionConfiguration = .default) {
        self.sessionConfiguration = configuration
        super.init()
    }

    /// Downloads a single confirmed dependency with real-time progress callbacks via URLSessionDownloadDelegate
    public func download(
        dependency: GameDependency,
        destinationDirectory: URL? = nil,
        onProgress: ProgressCallback? = nil
    ) async throws -> URL {
        guard let downloadURL = dependency.downloadURL else {
            throw DependencyDownloadError.missingDownloadURL(dependency.name)
        }

        return try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            self.currentDependency = dependency
            self.currentProgressCallback = onProgress
            self.downloadContinuation = continuation

            let session = URLSession(
                configuration: self.sessionConfiguration,
                delegate: self,
                delegateQueue: OperationQueue()
            )
            self.activeSession = session

            let task = session.downloadTask(with: downloadURL)
            self.activeTask = task
            lock.unlock()

            task.resume()
        }
    }

    /// Cancels active download task if one is running
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        activeTask?.cancel()
        activeTask = nil
        if let cont = downloadContinuation {
            downloadContinuation = nil
            cont.resume(throwing: DependencyDownloadError.cancelled)
        }
    }

    // MARK: - URLSessionDownloadDelegate

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        lock.lock()
        let dep = self.currentDependency
        let callback = self.currentProgressCallback
        lock.unlock()

        guard let dependency = dep else { return }

        let fraction: Double
        if totalBytesExpectedToWrite > 0 {
            fraction = min(1.0, max(0.0, Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)))
        } else {
            fraction = 0.0
        }

        let progress = DependencyDownloadProgress(
            dependencyId: dependency.dependencyId,
            name: dependency.name,
            fractionCompleted: fraction,
            bytesWritten: totalBytesWritten,
            totalBytesExpected: totalBytesExpectedToWrite
        )

        callback?(progress)
    }

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        lock.lock()
        let continuation = self.downloadContinuation
        self.downloadContinuation = nil
        let dep = self.currentDependency
        lock.unlock()

        guard let cont = continuation else { return }

        // Copy downloaded file into permanent cache before URLSession removes the temp file
        let filename = dep?.targetFilename ?? location.lastPathComponent
        let destinationDir = FileManager.default.temporaryDirectory.appendingPathComponent("MacOSGamingDownloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        let destination = destinationDir.appendingPathComponent("\(UUID().uuidString)_\(filename)")

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            cont.resume(returning: destination)
        } catch {
            cont.resume(throwing: error)
        }
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error {
            lock.lock()
            let continuation = self.downloadContinuation
            self.downloadContinuation = nil
            lock.unlock()

            continuation?.resume(throwing: error)
        }
    }
}
