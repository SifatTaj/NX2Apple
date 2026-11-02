import Foundation
import NXCore

extension BuildModel {
    /// Starts building the games detected from a multi-game cartridge dump.
    func startMultiGameBuild(titles: [String]) {
        guard titles.count > 1 else { return }
        let plan = MultiGamePlan(titleIDs: titles, currentIndex: 0)
        self.multiGamePlan = plan
        self.activeTitleID = titles[0]
        self.failure = nil
        self.stages = []
        self.logTail = ""
        self.resetProgress()
        self.say(String(format: self.t("msg.multiGameDetected"), titles.count, 1, titles.count, titles[0]))
        self.startBuild()
    }

    /// Checks if the build stopped because the container holds multiple games.
    /// If so, sets up the multi-game plan and starts building the first game.
    /// Returns true if a multi-game build was initiated.
    func handleMultiGameDetectedIfNeeded() -> Bool {
        guard self.multiGamePlan == nil else { return false }
        let detected = MultiGame.parseTitleIDs(from: self.logTail)
        guard detected.count > 1 else { return false }
        self.cleanupStaging()
        self.startMultiGameBuild(titles: detected)
        return true
    }

    /// If a multi-game plan is active and has more games to build, advances to the next title
    /// and schedules its build.
    /// Returns true if more games remain in the multi-game plan.
    func advanceMultiGameBuild() -> Bool {
        guard let plan = self.multiGamePlan else { return false }
        if plan.hasNext {
            DispatchQueue.main.async {
                guard let currentPlan = self.multiGamePlan, currentPlan.hasNext else { return }
                var nextPlan = currentPlan
                guard let nextTitle = nextPlan.advance() else { return }
                self.multiGamePlan = nextPlan
                self.activeTitleID = nextTitle
                self.done = false
                self.resetProgress()
                self.stages = []
                self.logTail = ""
                self.say(String(format: self.t("msg.multiGameDetected"), nextPlan.count, nextPlan.currentIndex + 1, nextPlan.count, nextTitle))
                self.startBuild()
            }
            return true
        } else {
            let count = plan.count
            self.doneNote = String(format: self.t("msg.multiGameDone"), count)
            self.multiGamePlan = nil
            self.activeTitleID = nil
            self.running = false
            self.cleanupStaging()
            return false
        }
    }
}

