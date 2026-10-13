import XCTest
@testable import SportApp

final class WorkoutStoreTests: XCTestCase {

    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("sportapp-test-\(UUID().uuidString).json")
    }

    private func emptySeed() -> AppData {
        AppData(version: AppData.currentVersion, exercises: [], gyms: [], templates: [], programs: [],
                settings: UserSettings(), history: [], activeSession: nil)
    }

    func testStartAndFinishWorkout() {
        let store = WorkoutStore(fileURL: nil, seed: MockData.appData())
        let startingHistory = store.data.history.count
        XCTAssertNil(store.activeSession)

        store.startSession(template: store.templates[0])
        XCTAssertEqual(store.activeSession?.name, "Push A")

        guard let session = store.activeSession else { return XCTFail("Geen lopende workout") }
        store.finishActiveSession(session)
        XCTAssertNil(store.activeSession)
        XCTAssertEqual(store.data.history.count, startingHistory + 1)
        XCTAssertNotNil(store.data.history.last?.endedAt)
    }

    func testRunningWorkoutSurvivesRestart() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let first = WorkoutStore(fileURL: url, seed: MockData.appData())
        first.startSession(template: first.templates[0])
        first.waitUntilSaved()

        let second = WorkoutStore(fileURL: url, seed: emptySeed())
        XCTAssertEqual(second.activeSession?.name, "Push A", "Na een crash kun je je workout hervatten")
        XCTAssertEqual(second.data.history.count, 2)
        XCTAssertFalse(second.library.all.isEmpty)
    }

    func testSettingsAreSavedAndReloaded() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let first = WorkoutStore(fileURL: url, seed: MockData.appData())
        first.updateSettings {
            $0.accentID = .viola
            $0.appearance = .dark
            $0.defaultRestSeconds = 120
        }
        first.waitUntilSaved()

        let second = WorkoutStore(fileURL: url, seed: emptySeed())
        XCTAssertEqual(second.settings.accentID, .viola)
        XCTAssertEqual(second.settings.appearance, .dark)
        XCTAssertEqual(second.settings.defaultRestSeconds, 120)
        XCTAssertTrue(second.settings.warmupFirstInSuperset, "Standaard aan (DESIGN.md 7.1)")
    }

    func testDefaultSettingsFollowTheDesign() {
        let settings = UserSettings()
        XCTAssertEqual(settings.accentID, .olive)
        XCTAssertEqual(settings.appearance, .system)
        XCTAssertEqual(settings.defaultRestSeconds, 90)
        XCTAssertEqual(UserSettings.restRange, 30...300)
        XCTAssertEqual(UserSettings.restStep, 15)
    }

    func testCurrentProgramAndGymComeFromSettings() {
        let store = WorkoutStore(fileURL: nil, seed: MockData.appData())
        XCTAssertEqual(store.currentProgram?.name, "Push Pull Legs")
        XCTAssertEqual(store.activeGym?.id, MockData.gymID)
    }

    func testUnreadableFileIsKeptAndReplacedBySeed() throws {
        let url = tempURL()
        try Data("dit is geen json".utf8).write(to: url)
        defer {
            try? FileManager.default.removeItem(at: url)
            let directory = url.deletingLastPathComponent()
            let leftovers = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
            for name in leftovers where name.hasPrefix(url.deletingPathExtension().lastPathComponent) {
                try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
            }
        }

        let store = WorkoutStore(fileURL: url, seed: MockData.appData())
        store.waitUntilSaved()
        XCTAssertEqual(store.data.history.count, 2, "Terugvallen op de startdata")

        let directory = url.deletingLastPathComponent()
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        let prefix = url.deletingPathExtension().lastPathComponent
        XCTAssertTrue(names.contains { $0.hasPrefix(prefix) && $0.contains("broken") },
                      "Het onleesbare bestand moet bewaard blijven, niet stilletjes verdwijnen")
    }
}

final class ProgramTests: XCTestCase {
    private let a = UUID(), b = UUID(), c = UUID()

    func testFirstWorkoutIsNextWhenNothingIsDone() {
        let program = Program(name: "PPL", workoutIDs: [a, b, c])
        XCTAssertEqual(program.nextWorkoutID(afterDone: []), a)
    }

    func testNextFollowsTheLastDoneWorkoutAndWrapsAround() {
        let program = Program(name: "PPL", workoutIDs: [a, b, c])
        XCTAssertEqual(program.nextWorkoutID(afterDone: [a]), b)
        XCTAssertEqual(program.nextWorkoutID(afterDone: [c, b]), a, "Na de laatste begin je weer bij de eerste")
    }

    func testWorkoutsOutsideTheProgramAreIgnored() {
        let program = Program(name: "PPL", workoutIDs: [a, b, c])
        XCTAssertEqual(program.nextWorkoutID(afterDone: [UUID(), b]), c)
    }

    func testEmptyProgramHasNoNextWorkout() {
        XCTAssertNil(Program(name: "Leeg").nextWorkoutID(afterDone: [a]))
    }
}
