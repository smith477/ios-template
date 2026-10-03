// Log.swift

import Foundation
import os

/// A module's log in Console, under the app's subsystem.
///
/// Takes only what is safe to show: event text fixed at compile time, integers,
/// and errors whose description stays private. `os` applies privacy only where a
/// message is written, so callers cannot pass one through.
public struct Log: Sendable {
    private let logger: Logger

    /// Creates a log whose Console category is the calling module's name, so a
    /// copied or renamed module needs no edit.
    public init(fileID: String = #fileID) {
        // `#fileID` is `Module/File.swift`.
        self.init(category: String(fileID.prefix { $0 != "/" }))
    }

    init(category: String) {
        logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "App", category: category)
    }

    /// Logs routine detail, kept in memory only, so it costs nothing in production.
    public func debug(_ event: StaticString, _ values: KeyValuePairs<StaticString, Int> = [:]) {
        write(.debug, event, values, error: nil)
    }

    /// Logs a failure the app absorbed, such as a refresh served from the cache.
    public func notice(_ event: StaticString, error: (any Error)? = nil, _ values: KeyValuePairs<StaticString, Int> = [:]) {
        write(.default, event, values, error: error)
    }

    /// Logs a failure the user sees, or one no caller will log again.
    public func error(_ event: StaticString, error: (any Error)? = nil, _ values: KeyValuePairs<StaticString, Int> = [:]) {
        write(.error, event, values, error: error)
    }

    private func write(
        _ level: OSLogType,
        _ event: StaticString,
        _ values: KeyValuePairs<StaticString, Int>,
        error: (any Error)?
    ) {
        // Built only from compile-time text and integers, so public by construction.
        let text = values.reduce("\(event)") { $0 + " \($1.key)=\($1.value)" }
        guard let error else {
            logger.log(level: level, "\(text, privacy: .public)")
            return
        }
        // Domain and code say what failed; the description can quote data or paths.
        let nsError = error as NSError
        let (domain, code, detail) = (nsError.domain, nsError.code, nsError.localizedDescription)
        logger.log(
            level: level,
            "\(text, privacy: .public): \(domain, privacy: .public) \(code, privacy: .public) \(detail, privacy: .private)"
        )
    }
}
