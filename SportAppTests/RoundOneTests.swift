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

    func testWarmupBlockIsNotAWorkSet() {
        var t = SeedData.templates
        t["Push"]?.insert(PlanItem(name: "Rotator cuff external rotation", group: 99,
                                   sets: [PlanSet(w: 0, r: 15, rmax: nil)], isWarmup: true), at: 0)
        let s = LiveSession.make(name: "Push", startAt: Date(), templates: t)
        XCTAssertEqual(s.exercises.first?.name, "Rotator cuff external rotation")
        XCTAssertEqual(s.workSetCounts.total, 27)
    }

    func testDeleteProgramRemovesItsTrainings() {
        let model = AppModel(fileURL: nil)
        XCTAssertEqual(model.restDefault, 180)
        model.deleteProgram(model.program.id)
        XCTAssertEqual(model.programs.count, 1)
        XCTAssertTrue(model.program.workouts.isEmpty)
        XCTAssertTrue(model.templates.isEmpty)
    }

    func testChosenSetIsCompletedAndFlowReturnsToTheFirstOpenSet() {
        var s = LiveSession.make(name: "Push", startAt: Date(), templates: SeedData.templates)
        let q = s.queue(warmFirst: true)
        XCTAssertGreaterThan(q.count, 4)
        let chosen = q[4]
        let r = s.complete(focus: nil, focusSet: chosen.setID, warmFirst: true, restDefault: 180)
        XCTAssertEqual(s.findSet(chosen.setID)?.done, true)
        XCTAssertEqual(r?.nextFocus, q[0].exID)
        // Een gedane set nog eens afronden doet niets.
        XCTAssertNil(s.complete(focus: nil, focusSet: chosen.setID, warmFirst: true, restDefault: 180))
    }

    func testSwapInScheduleChangesTheTemplate() {
        let model = AppModel(fileURL: nil)
        model.doStart("Push")
        guard let ex = model.session?.exercises.first else { return XCTFail("geen oefening") }
        let old = ex.name
        model.sheetEx = ex.id
        model.swapScope = .schema
        model.swapExercise(to: "Dumbbell Shrug", manual: false)
        XCTAssertEqual(model.templates["Push"]?.first?.name, "Dumbbell Shrug")
        XCTAssertNotEqual(old, "Dumbbell Shrug")
    }

    func testPreferenceOnlyDoesNotSwap() {
        let model = AppModel(fileURL: nil)
        model.doStart("Push")
        guard let ex = model.session?.exercises.first else { return XCTFail("geen oefening") }
        model.sheetEx = ex.id
        model.swapScope = .prefOnly
        model.swapExercise(to: "Dumbbell Shrug", manual: true)
        XCTAssertEqual(model.session?.exercises.first?.name, ex.name)
        XCTAssertEqual(model.prefs[ex.name], "Dumbbell Shrug")
    }

    func testMultipleWarmupSetsRampUp() {
        var plan = PlanItem(name: "Dumbbell Bench Press", group: 1, sets: [PlanSet(w: 20, r: 8, rmax: nil)])
        plan.warm = PlanSet(w: 10, r: 12)
        plan.warmCount = 3
        let ex = LiveSession.makeExercise(name: plan.name, group: 1, plan: plan)
        let warm = ex.sets.filter { $0.type == .warmup }
        XCTAssertEqual(warm.count, 3)
        XCTAssertTrue(warm[0].w < warm[1].w && warm[1].w < warm[2].w)
        XCTAssertTrue(warm[2].w < 20)
        var draft = Draft(name: "X", plans: [plan])
        XCTAssertEqual(draft.items[0].warmSets, 3)
        draft.items[0].warmSets = 0
        XCTAssertNil(draft.toPlans()[0].warm)
    }
}
