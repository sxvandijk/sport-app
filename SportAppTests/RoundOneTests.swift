import XCTest
@testable import SportApp

final class RoundOneTests: XCTestCase {
    func testSeedHasFourSchemasAndNoHistory() {
        let t = SeedData.templates
        XCTAssertEqual(Set(t.keys), Set(["Push", "Pull", "Legs", "Upper"]))
        XCTAssertEqual(t["Push"]?.count, 9)
        XCTAssertEqual(t["Legs"]?.count, 9)
        XCTAssertEqual(t["Pull"]?.count, 8)
        XCTAssertEqual(t["Upper"]?.count, 11)
        XCTAssertEqual(AppModel.defaultState(now: Date()).history.count, 0)
        let push = t["Push"] ?? []
        XCTAssertEqual(push.reduce(0) { $0 + $1.sets.count }, 27)
        XCTAssertEqual(push[0].sets[0].rmax, 12)
    }

    func testPreviousTimeComesFromHistory() {
        let logged = LoggedExercise(name: "Butterfly", sets: [LoggedSet(w: 72.5, r: 10, type: .work),
                                                              LoggedSet(w: 72.5, r: 9, type: .work)])
        let entry = HistoryEntry(date: Date(), name: "Push", minutes: 50, exercises: [logged])
        let s = LiveSession.make(name: "Push", startAt: Date(), templates: SeedData.templates, history: [entry])
        let ex = s.exercises.first(where: { $0.name == "Butterfly" })
        XCTAssertEqual(ex?.sets.first?.pw, 72.5)
        XCTAssertEqual(ex?.sets.first?.w, 72.5)
        XCTAssertEqual(ex?.sets.last?.pr, 9)
        let fresh = LiveSession.make(name: "Push", startAt: Date(), templates: SeedData.templates)
        XCTAssertNil(fresh.exercises.first?.sets.first?.pw)
        XCTAssertEqual(fresh.exercises.first?.sets.first?.rmin, 8)
    }

    func testCardioAndBodyweightText() {
        XCTAssertEqual(Format.setText(.cardio, 2.37, 3), "2,37 km · 3 min")
        XCTAssertEqual(Format.setText(.bodyweight, 0, 12), "12 reps")
        XCTAssertEqual(Format.setText(.bodyweight, 10, 9), "+10 kg × 9")
        XCTAssertEqual(Format.setText(.weights, 7.5, 12), "7,5 kg × 12")
        XCTAssertEqual(Format.reps(8, 12), "8–12")
        XCTAssertEqual(Format.reps(12, nil), "12")
        XCTAssertEqual(Catalog.kind("Hardlopen op de loopband"), .cardio)
        XCTAssertEqual(Catalog.kind("Pullups"), .bodyweight)
    }

    func testProgressStatsRecordsAndVolume() {
        let now = Date()
        let cal = Calendar.current
        let old = cal.date(byAdding: .day, value: -10, to: now) ?? now
        let a = HistoryEntry(date: old, name: "Push", minutes: 50,
                             exercises: [LoggedExercise(name: "Butterfly", sets: [LoggedSet(w: 60, r: 10, type: .work),
                                                                                 LoggedSet(w: 30, r: 12, type: .warmup)])])
        let b = HistoryEntry(date: now, name: "Push", minutes: 50,
                             exercises: [LoggedExercise(name: "Butterfly", sets: [LoggedSet(w: 70, r: 8, type: .work)]),
                                         LoggedExercise(name: "Hardlopen op de loopband", sets: [LoggedSet(w: 2.4, r: 3, type: .work)])])
        let st = ProgressStats.make(history: [a, b], now: now)
        XCTAssertEqual(st.trainings, 2)
        XCTAssertEqual(st.volume, 60 * 10 + 70 * 8, accuracy: 0.001)
        XCTAssertEqual(st.records.first(where: { $0.name == "Butterfly" })?.weight, 70)
        XCTAssertNil(st.records.first(where: { $0.name == "Hardlopen op de loopband" }))
        XCTAssertEqual(st.newRecords, 1)
        XCTAssertEqual(st.weekVolumes.count, 8)
    }

    func testCustomExerciseIsRemembered() {
        let model = AppModel(fileURL: nil)
        let name = model.addCustomExercise(name: "Farmer walk", muscle: "Core", equipment: "Eigen", kind: .weights)
        XCTAssertEqual(name, "Farmer walk")
        XCTAssertEqual(Catalog.info("Farmer walk").muscle, "Core")
        XCTAssertEqual(model.addCustomExercise(name: "farmer walk", muscle: "Core", equipment: "Eigen", kind: .weights), "Farmer walk")
        Catalog.setCustom([])
    }

    func testGeneralWarmupIsFirstExerciseAndNotAWorkSet() {
        let s = LiveSession.make(name: "Push", startAt: Date(), templates: SeedData.templates, startWarmupMinutes: 5)
        XCTAssertEqual(s.exercises.first?.name, Catalog.generalWarmupName)
        XCTAssertEqual(s.exercises.first?.sets.first?.type, .warmup)
        XCTAssertEqual(s.exercises.first?.sets.first?.r, 5)
        XCTAssertEqual(s.workSetCounts.total, 27)
        let none = LiveSession.make(name: "Push", startAt: Date(), templates: SeedData.templates)
        XCTAssertNotEqual(none.exercises.first?.name, Catalog.generalWarmupName)
    }

    func testDeleteProgramRemovesItsTrainings() {
        let model = AppModel(fileURL: nil)
        XCTAssertEqual(model.restDefault, 180)
        model.deleteProgram(model.program.id)
        XCTAssertEqual(model.programs.count, 1)
        XCTAssertTrue(model.program.workouts.isEmpty)
        XCTAssertTrue(model.templates.isEmpty)
    }
}
