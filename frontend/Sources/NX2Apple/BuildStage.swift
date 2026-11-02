import Foundation
import SwiftUI
import NXCore

struct Stage: Identifiable {
    let id: Int          // k, the stage number in the script's own plan
    var name: String
    var state: StepState = .running
    var detail: String = ""
    var percent: Double? = nil
    var started: Date? = nil   // when the stage began here: its clock runs while the count may stand still
    var eta: Double? = nil     // the script's estimate of the seconds left, as of etaAt
    var etaAt: Date? = nil

    /// A stage's name in the launcher's language. The script names its stages in English (PROG.stage in
    /// build_ipa_from_nsp.py): stage.<name> in the table, "extract <name>" and "<API> shader capture" with their
    /// part kept; a name the table does not know (a newer script's) is shown as the script wrote it.
    static func localizedName(_ name: String, _ t: (String) -> String) -> String {
        func known(_ key: String) -> String? { let s = t(key); return s == key ? nil : s }
        let key = "stage." + name.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        if let s = known(key) { return s }
        if name.hasPrefix("extract "), let f = known("stage.extract") { return String(format: f, String(name.dropFirst("extract ".count))) }
        if name.hasSuffix(" shader capture"), let f = known("stage.capture") { return String(format: f, String(name.dropLast(" shader capture".count))) }
        return name
    }

    /// "3:42" since the stage began, then "1 min left" while the script's estimate, counted down from when it came,
    /// lasts: the estimate only arrives with a new count, so one taken as it was would stand still with the count.
    func clock(at now: Date, left: String) -> String {
        var parts: [String] = []
        if let started {
            let t = max(0, Int(now.timeIntervalSince(started)))
            parts.append(t >= 3600 ? String(format: "%d:%02d:%02d", t / 3600, t / 60 % 60, t % 60) : String(format: "%d:%02d", t / 60, t % 60))
        }
        if let eta, let etaAt {
            let remaining = eta - now.timeIntervalSince(etaAt)
            if remaining >= 1 { parts.append(String(format: left, BuildModel.duration(remaining))) }
        }
        return parts.joined(separator: " · ")
    }
}

enum StepState: Equatable {
    case pending, running, done, failed
    var icon: String {
        switch self {
        case .pending: return "circle"
        case .running: return "spinner"
        case .done: return "checkmark.circle.fill"
        case .failed: return "xmark.octagon.fill"
        }
    }
    var color: Color {
        switch self {
        case .pending: return .gray
        case .running: return .yellow
        case .done: return .green
        case .failed: return .red
        }
    }
}

/// One of the four things the user points at.
enum InputKind { case base, update, dlc, keys }

struct Slot: Identifiable {
    let id: String
    let kind: InputKind
    let title: String
    let optional: Bool
    var paths: [String] = []
    var problem: String = ""
    /// A finished sentence shown beside the file name (the update row: which of several updates was taken).
    var note: String = ""
    var ok: Bool { paths.contains { FileManager.default.fileExists(atPath: $0) } }
    /// `problem` holds either a finished message or a key + arguments, resolved by the model
    /// (it needs the current language, which a struct cannot read).
    var problemText: String { problem }
    func summary(_ t: (String) -> String) -> String {
        if !problem.isEmpty { return problem.hasPrefix("data.") ? t(problem) : problem }
        if paths.isEmpty {
            if kind == .dlc { return t("data.notSelectedDlc") }
            return optional ? t("data.notSelectedOptional") : t("data.notSelected")
        }
        if paths.count == 1 {
            let name = (paths[0] as NSString).lastPathComponent
            return note.isEmpty ? name : name + "\n" + note
        }
        return String(format: t("data.files"), paths.count) + paths.map { ($0 as NSString).lastPathComponent }.joined(separator: ", ")
    }
}

