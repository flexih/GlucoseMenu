//
//  Logger.swift
//  glu
//
//  Created by fanxinghua on 2025/5/8.
//

import os.log
import OSLog

public extension Logger {
  static let main = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "main")
  static let store = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "store")

  //	func logEntries(since time: Date?) async -> [OSLogEntryLog] {
//        let results = Task {
//            do {
//                let entries = try getLogEntries(since: time)
//                return entries
//            } catch {
//                Logger.main.debug("\(error)")
//                return []
//            }
//        }
//        return await results.value
//    }

//    func getLogEntries(since time: Date?) throws -> [OSLogEntryLog] {
//        // Open the log store.
//        let logStore = try OSLogStore(scope: .currentProcessIdentifier)
//
//        // Get all the logs from the last hour.
//        let oneHourAgo = logStore.position(date: time ?? Date().addingTimeInterval(-3600))
//
//        let predicate = NSPredicate(format: "subsystem == %@", Bundle.main.bundleIdentifier!)
//
//        // Fetch log objects.
//        let allEntries = try logStore.getEntries(with: .reverse, at: oneHourAgo, matching: predicate)
//
//        // Filter the log to be relevant for our specific subsystem
//        // and remove other elements (signposts, etc).
//        return allEntries.compactMap { $0 as? OSLogEntryLog }
//            //.filter { $0.subsystem == subsystem }
//    }
//
//    func getLog() -> String? {
//        guard let entries = try? getLogEntries(since: nil) else { return nil }
//        return entries.map { entry in
//            "\(DateFormatter.timeFormatter.string(from: entry.date)) \(entry.category) \(entry.composedMessage)"
//        }.joined(separator: "\r\n")
//    }
//
//    func write2Disk(string: String) {
//        do {
//            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//                let logURL = documentDirectory.appendingPathComponent("logs.txt")
//                try string.write(to: logURL, atomically: true, encoding: .utf8)
//            }
//        } catch {
//            Logger.main.debug("\(error)")
//        }
//    }
}
