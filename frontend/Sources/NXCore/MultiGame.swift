import Foundation

/// Detection and planning for multi-game cartridge XCI dumps.
package enum MultiGame {
    /// Extracts application title IDs when a build reports that the container holds more than one game.
    package static func parseTitleIDs(from log: String) -> [String] {
        var found: [String] = []

        // Pattern matching: "more than one game in the folder: 0100..., 0100...; ..." or older "...keep one game per folder: 0100..., 0100..."
        let pattern = #"more than one game in the folder.*?:\s*([0-9A-Fa-f]{16}(?:\s*,\s*[0-9A-Fa-f]{16})+)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let ns = log as NSString
            let matches = regex.matches(in: log, options: [], range: NSRange(location: 0, length: ns.length))
            if let lastMatch = matches.last, lastMatch.numberOfRanges > 1 {
                let matchedStr = ns.substring(with: lastMatch.range(at: 1))
                let ids = matchedStr.split(separator: ",").map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                }.filter { $0.count == 16 && UInt64($0, radix: 16) != nil }
                found.append(contentsOf: ids)
            }
        }

        // Secondary fallback: "holds several titles: ... base game 0100... ... base game 0100..."
        if found.count <= 1 && log.localizedCaseInsensitiveContains("holds several titles") {
            let baseGamePattern = #"base game\s+([0-9A-Fa-f]{16})"#
            if let regex = try? NSRegularExpression(pattern: baseGamePattern, options: [.caseInsensitive]) {
                let ns = log as NSString
                let matches = regex.matches(in: log, options: [], range: NSRange(location: 0, length: ns.length))
                for m in matches where m.numberOfRanges > 1 {
                    let tid = ns.substring(with: m.range(at: 1)).uppercased()
                    if tid.count == 16 && UInt64(tid, radix: 16) != nil && !found.contains(tid) {
                        found.append(tid)
                    }
                }
            }
        }

        // Deduplicate while preserving order
        var seen = Set<String>()
        var result: [String] = []
        for id in found {
            if !seen.contains(id) {
                seen.insert(id)
                result.append(id)
            }
        }
        guard result.count > 1 else { return [] }
        return result
    }
}

/// A sequential queue of title IDs to build from a multi-game dump.
package struct MultiGamePlan: Equatable, Sendable {
    package var titleIDs: [String]
    package var currentIndex: Int

    package init(titleIDs: [String], currentIndex: Int = 0) {
        self.titleIDs = titleIDs
        self.currentIndex = currentIndex
    }

    package var count: Int { titleIDs.count }
    package var isMultiGame: Bool { titleIDs.count > 1 }

    package var currentTitleID: String? {
        guard currentIndex >= 0 && currentIndex < titleIDs.count else { return nil }
        return titleIDs[currentIndex]
    }

    package var hasNext: Bool {
        currentIndex + 1 < titleIDs.count
    }

    package mutating func advance() -> String? {
        guard hasNext else { return nil }
        currentIndex += 1
        return currentTitleID
    }
}

