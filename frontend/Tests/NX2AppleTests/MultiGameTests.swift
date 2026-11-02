import XCTest
@testable import NXCore
@testable import NX2Apple

final class MultiGameTests: XCTestCase {
    func testParseModernUpstreamSeveralGamesError() {
        let log = "[RED] more than one game in the folder: 010061D00DB74000, 01008DD013200000; keep one game per folder, or name the one to pack with --title-id / TITLE_ID (a cartridge dump that holds two games)"
        let parsed = MultiGame.parseTitleIDs(from: log)
        XCTAssertEqual(parsed, ["010061D00DB74000", "01008DD013200000"])
    }

    func testParseOlderSeveralGamesError() {
        let log = "[RED] more than one game in the folder, keep one game per folder: 0100000000010000, 01006F8002326000"
        let parsed = MultiGame.parseTitleIDs(from: log)
        XCTAssertEqual(parsed, ["0100000000010000", "01006F8002326000"])
    }

    func testParseThreeGameCollection() {
        let log = "[RED] more than one game in the folder: 0100000000010000, 01006F8002326000, 01008DD013200000; keep one game per folder"
        let parsed = MultiGame.parseTitleIDs(from: log)
        XCTAssertEqual(parsed, ["0100000000010000", "01006F8002326000", "01008DD013200000"])
    }

    func testParseFallbackBaseGamesInLog() {
        let log = "Collection.xci holds several titles: base game 010061D00DB74000 v0, base game 01008DD013200000 v0, update 010061D00DB74800 v131072"
        let parsed = MultiGame.parseTitleIDs(from: log)
        XCTAssertEqual(parsed, ["010061D00DB74000", "01008DD013200000"])
    }

    func testSingleGameLogGivesNoMultiGame() {
        let log = "extracting base game 010061D00DB74000\n[9/9] packing"
        let parsed = MultiGame.parseTitleIDs(from: log)
        XCTAssertTrue(parsed.isEmpty)
    }

    func testMultiGamePlanProgression() {
        var plan = MultiGamePlan(titleIDs: ["010061D00DB74000", "01008DD013200000"])
        XCTAssertEqual(plan.count, 2)
        XCTAssertTrue(plan.isMultiGame)
        XCTAssertEqual(plan.currentTitleID, "010061D00DB74000")
        XCTAssertTrue(plan.hasNext)

        let next = plan.advance()
        XCTAssertEqual(next, "01008DD013200000")
        XCTAssertEqual(plan.currentTitleID, "01008DD013200000")
        XCTAssertFalse(plan.hasNext)

        let none = plan.advance()
        XCTAssertNil(none)
    }

    func testRememberInputsCreatesSeparateEntriesPerTitle() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let libFile = tmp.appendingPathComponent("library.json")
        let library = GameLibrary(file: libFile)

        let model = BuildModel()
        model.slots[0].paths = ["/Volumes/Games/Ori Collection.xci"]

        // 1. Initial rememberInputs before multi-game detection uses file path
        let initialID = library.rememberInputs(model)
        XCTAssertNotNil(initialID)
        XCTAssertEqual(library.games.count, 1)
        XCTAssertEqual(library.games[0].titleID, "/Volumes/Games/Ori Collection.xci")

        // 2. Multi-game detected: game 1 active
        model.activeTitleID = "010061D00DB74000"
        let game1ID = library.rememberInputs(model)
        XCTAssertEqual(game1ID, initialID, "placeholder entry transitions to first game")
        XCTAssertEqual(library.games.count, 1)
        XCTAssertEqual(library.games[0].titleID, "010061D00DB74000")

        // 3. Game 2 active
        model.activeTitleID = "01008DD013200000"
        let game2ID = library.rememberInputs(model)
        XCTAssertNotEqual(game2ID, game1ID, "second game gets its own distinct entry")
        XCTAssertEqual(library.games.count, 2)

        let titles = Set(library.games.map(\.titleID))
        XCTAssertEqual(titles, ["010061D00DB74000", "01008DD013200000"])
    }

    func testMultiGameLocalizationStringsExist() {
        for lang in Lang.allCases {
            let detected = L10n.string("msg.multiGameDetected", lang)
            XCTAssertFalse(detected.isEmpty)
            XCTAssertNotEqual(detected, "msg.multiGameDetected")

            let done = L10n.string("msg.multiGameDone", lang)
            XCTAssertFalse(done.isEmpty)
            XCTAssertNotEqual(done, "msg.multiGameDone")
        }
    }
}

