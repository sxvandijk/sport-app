import XCTest
@testable import SportApp

// MARK: - Hulpjes

private let library = ExerciseLibrary(MockData.exercises())
private let gym = MockData.gym()

private func ex(_ n: Int) -> Exercise {
    guard let exercise = library[MockData.uid(n)] else { fatalError("Mock-oefening \(n) bestaat niet") }
    return exercise
}

/// Een afgeronde workout met één oefening en de opgegeven (gewicht, reps)-sets.
private func finishedSession(daysAgo: Int, exerciseID: UUID, sets: [(Double, Int)]) -> ActiveWorkoutSession {
    let date = Date().addingTimeInterval(TimeInterval(-daysAgo * 86_400))
    let workSets = sets.map { WorkoutSet(exerciseID: exerciseID, weight: $0.0, reps: $0.1, timestamp: date) }
    let item = SessionExercise(plannedExerciseID: exerciseID, exerciseID: exerciseID, sets: workSets)
    return ActiveWorkoutSession(name: "Test", startedAt: date, endedAt: date.addingTimeInterval(3600), exercises: [item])
}

/// Een open oefening met `count` lege sets.
private func openExercise(_ id: UUID, sets count: Int, rest: Int, group: UUID? = nil) -> SessionExercise {
    SessionExercise(plannedExerciseID: id,
                    exerciseID: id,
                    supersetGroupID: group,
                    restSeconds: rest,
                    sets: (0..<count).map { _ in WorkoutSet(exerciseID: id) })
}

// MARK: - Gewichtsstappen

final class WeightScaleTests: XCTestCase {

    func testRegularStackSnapsAndSteps() {
        let scale = WeightScale.stack(min: 5, max: 95, step: 5)
        XCTAssertEqual(scale.snap(37), 35)
        XCTAssertEqual(scale.snap(37.5), 40, "Bij een gelijke afstand wint het zwaardere gewicht")
        XCTAssertEqual(scale.snap(0), 5)
        XCTAssertEqual(scale.snap(200), 95)
        XCTAssertEqual(scale.next(after: 37), 40)
        XCTAssertEqual(scale.previous(before: 37), 35)
        XCTAssertNil(scale.next(after: 95))
        XCTAssertNil(scale.previous(before: 5))
        XCTAssertEqual(scale.step(from: 95, up: true), 95, "Aan het eind van de stapel blijft het gewicht staan")
    }

    func testAddOnPlateCreatesHalfSteps() {
        let scale = WeightScale.stack(min: 5, max: 20, step: 5, addOn: 2.5)
        XCTAssertEqual(scale.validWeights(), [5, 7.5, 10, 12.5, 15, 17.5, 20])
        XCTAssertEqual(scale.next(after: 10), 12.5)
    }

    func testIrregularStackUsesTheList() {
        let scale = WeightScale(kind: .stack, availableWeights: [10, 15, 20, 25, 35, 45])
        XCTAssertEqual(scale.next(after: 25), 35, "30 bestaat niet op deze machine")
        XCTAssertEqual(scale.previous(before: 35), 25)
        XCTAssertFalse(scale.isValid(30))
        XCTAssertTrue(scale.isValid(35))
        XCTAssertEqual(scale.snap(30), 35)
    }

    func testBarbellNeverGoesBelowTheEmptyBar() {
        // Het Fitbod-probleem: 17,5 kg adviseren op een stang van 20 kg.
        let scale = WeightScale.barbell(barWeight: 20, maxWeight: 100, smallestStep: 2.5)
        XCTAssertEqual(scale.snap(17.5), 20)
        XCTAssertEqual(scale.snap(21.5), 22.5)
        XCTAssertNil(scale.previous(before: 20))
    }

    func testFallbackScaleIsUnbounded() {
        let scale = WeightScale.fallback
        XCTAssertEqual(scale.next(after: 10), 12.5)
        XCTAssertEqual(scale.previous(before: 2.5), 0)
        XCTAssertNil(scale.previous(before: 0))
    }

    func testInferIncrementFromScannedNumbers() {
        XCTAssertEqual(WeightScale.inferIncrement(from: [5, 10, 15, 20, 25, 35]), 5)
        XCTAssertEqual(WeightScale.inferIncrement(from: [5, 10]), 5)
        XCTAssertNil(WeightScale.inferIncrement(from: [10]))
        XCTAssertNil(WeightScale.inferIncrement(from: [3, 10, 11, 40]), "Geen patroon = geen gok")
    }

    func testCodableRoundTrip() throws {
        let scale = WeightScale.stack(min: 5, max: 70, step: 5, addOn: 2.5)
        let data = try JSONEncoder().encode(scale)
        XCTAssertEqual(try JSONDecoder().decode(WeightScale.self, from: data), scale)
    }
}

// MARK: - PR-tracking

final class PersonalRecordTests: XCTestCase {

    func testEpley() throws {
        XCTAssertEqual(try XCTUnwrap(E1RM.epley(weight: 100, reps: 5)), 116.667, accuracy: 0.001)
        XCTAssertEqual(E1RM.epley(weight: 100, reps: 1), 100)
        XCTAssertNil(E1RM.epley(weight: 100, reps: 11), "Boven 10 reps is de formule te onbetrouwbaar")
        XCTAssertNil(E1RM.epley(weight: 0, reps: 5))
    }

    func testRecordsPickHeaviestAndBestEstimate() throws {
        let id = MockData.uid(1)
        let records = PRService.records(from: [
            finishedSession(daysAgo: 7, exerciseID: id, sets: [(50, 10), (60, 5)])
        ])
        let record = try XCTUnwrap(records[id])
        XCTAssertEqual(record.heaviest?.weight, 60)
        // 50 × 10 → 66,7 ; 60 × 5 → 70,0
        XCTAssertEqual(record.bestE1RM?.weight, 60)
    }

    func testNewRecordDetection() {
        let id = MockData.uid(1)
        let records = PRService.records(from: [finishedSession(daysAgo: 7, exerciseID: id, sets: [(60, 5)])])
        let now = Date()

        let heavier = WorkoutSet(exerciseID: id, weight: 62.5, reps: 3, timestamp: now)
        XCTAssertEqual(PRService.newRecords(for: heavier, against: records), [.heaviestWeight])

        let moreReps = WorkoutSet(exerciseID: id, weight: 60, reps: 8, timestamp: now)
        XCTAssertEqual(PRService.newRecords(for: moreReps, against: records), [.estimated1RM])

        let easier = WorkoutSet(exerciseID: id, weight: 50, reps: 5, timestamp: now)
        XCTAssertEqual(PRService.newRecords(for: easier, against: records), [])
    }

    func testFirstTimeAndWarmupsAreNoRecords() {
        let id = MockData.uid(1)
        let now = Date()
        let first = WorkoutSet(exerciseID: id, weight: 100, reps: 5, timestamp: now)
        XCTAssertEqual(PRService.newRecords(for: first, against: [:]), [], "De eerste keer is geen PR")

        let records = PRService.records(from: [finishedSession(daysAgo: 7, exerciseID: id, sets: [(60, 5)])])
        let warmup = WorkoutSet(exerciseID: id, weight: 200, reps: 5, kind: .warmup, timestamp: now)
        XCTAssertEqual(PRService.newRecords(for: warmup, against: records), [])
    }
}

// MARK: - Resterende tijd

final class DurationEstimatorTests: XCTestCase {
    private let estimator = DurationEstimator(assumedSetSeconds: 45)

    func testSingleExercise() {
        let id = MockData.uid(1)
        var session = ActiveWorkoutSession(name: "T", exercises: [openExercise(id, sets: 3, rest: 90)])
        // 3 × 45 s + 3 × 90 s rust − de rust na de laatste set
        XCTAssertEqual(estimator.remainingTime(for: session), 315, accuracy: 0.001)

        session.exercises[0].sets[0].timestamp = Date()
        XCTAssertEqual(estimator.remainingTime(for: session), 180, accuracy: 0.001)
    }

    func testSupersetRestsOncePerRound() {
        let group = UUID()
        let session = ActiveWorkoutSession(name: "T", exercises: [
            openExercise(MockData.uid(12), sets: 3, rest: 60, group: group),
            openExercise(MockData.uid(20), sets: 3, rest: 60, group: group)
        ])
        // 6 sets × 45 s + 3 rondes × 60 s − 60 s
        XCTAssertEqual(estimator.remainingTime(for: session), 390, accuracy: 0.001)
    }

    func testWarmupSetCountsWithHalfRest() {
        let id = MockData.uid(1)
        var item = openExercise(id, sets: 1, rest: 90)
        item.sets.insert(WorkoutSet(exerciseID: id, kind: .warmup), at: 0)
        let session = ActiveWorkoutSession(name: "T", exercises: [item])
        // 2 sets × 45 s + 1 werkset × 90 s + 1 warming-upset × 45 s halve rust − de rust na de laatste werkset
        XCTAssertEqual(estimator.remainingTime(for: session), 135, accuracy: 0.001)
    }

    func testFinishedWorkoutHasNothingLeft() {
        var session = ActiveWorkoutSession(name: "T", exercises: [openExercise(MockData.uid(1), sets: 2, rest: 90)])
        for s in session.exercises[0].sets.indices { session.exercises[0].sets[s].timestamp = Date() }
        XCTAssertEqual(estimator.remainingTime(for: session), 0, accuracy: 0.001)
    }

    func testCalibrationNeedsEnoughData() {
        XCTAssertNil(DurationEstimator.calibratedSetSeconds(from: []))
    }
}

// MARK: - Workout opbouwen, supersets en wisselen

final class WorkoutSessionTests: XCTestCase {

    func testMakeFromTemplate() throws {
        let push = MockData.templates()[0]
        let session = ActiveWorkoutSession.make(from: push, gym: gym, library: library)

        XCTAssertEqual(session.name, "Push A")
        XCTAssertEqual(session.exercises.count, 5)
        XCTAssertEqual(session.exercises[0].sets.count, 4, "Chest press heeft een warming-upset en 3 werksets")
        XCTAssertEqual(session.exercises[0].sets[0].kind, .warmup)
        XCTAssertEqual(session.exercises[1].sets.count, 3)
        XCTAssertEqual(session.exercises[0].gymEquipmentID, MockData.uid(904), "Chest press → de chest press in jouw gym")
        XCTAssertNotNil(session.exercises[2].supersetGroupID)
        XCTAssertEqual(session.exercises[2].supersetGroupID, session.exercises[3].supersetGroupID)
        XCTAssertEqual(session.blocks.count, 4, "5 oefeningen waarvan 2 in een superset = 4 blokken")
        XCTAssertTrue(session.blocks[2].isSuperset)
    }

    func testWarmupSetOnlyWhenTheTemplateAsksForIt() {
        let legs = MockData.templates()[2]
        let session = ActiveWorkoutSession.make(from: legs, gym: gym, library: library)
        XCTAssertEqual(session.exercises[0].sets.filter { $0.isWarmup }.count, 1, "Leg press heeft een warming-upset")
        XCTAssertEqual(session.exercises[1].sets.filter { $0.isWarmup }.count, 0)
    }

    func testOnlyWarmupsAreLeftOutOfSetsAndVolume() {
        let id = MockData.uid(1)
        let now = Date()
        let sets = [
            WorkoutSet(exerciseID: id, weight: 20, reps: 10, kind: .warmup, timestamp: now),
            WorkoutSet(exerciseID: id, weight: 50, reps: 10, kind: .working, timestamp: now),
            WorkoutSet(exerciseID: id, weight: 40, reps: 8, kind: .drop, timestamp: now),
            WorkoutSet(exerciseID: id, weight: 50, reps: 6, kind: .failure, timestamp: now),
            WorkoutSet(exerciseID: id, weight: 50, reps: 10, kind: .working)   // nog niet gedaan
        ]
        let session = ActiveWorkoutSession(name: "T", exercises: [
            SessionExercise(plannedExerciseID: id, exerciseID: id, sets: sets)
        ])
        XCTAssertEqual(session.completedWorkingSetCount, 3, "Dropset en tot falen tellen mee, warming-up en open set niet")
        let expectedVolume: Double = 500 + 320 + 300   // 50×10 + 40×8 + 50×6
        XCTAssertEqual(session.totalVolume, expectedVolume, accuracy: 0.001)
    }

    func testAddWarmupSetGoesBeforeTheWorkingSets() {
        var session = ActiveWorkoutSession(name: "T", exercises: [openExercise(MockData.uid(1), sets: 2, rest: 90)])
        let item = session.exercises[0].id
        session.addSet(toExercise: item, kind: .warmup)
        session.addSet(toExercise: item, kind: .drop)
        XCTAssertEqual(session.exercises[0].sets.map { $0.kind }, [.warmup, .working, .working, .drop])
    }

    func testSupersetTimerFiresAfterTheLastExercise() throws {
        let group = UUID()
        var session = ActiveWorkoutSession(name: "T", exercises: [
            openExercise(MockData.uid(12), sets: 2, rest: 60, group: group),
            openExercise(MockData.uid(20), sets: 2, rest: 60, group: group)
        ])
        let a1 = session.exercises[0].sets[0].id
        let b1 = session.exercises[1].sets[0].id

        session.exercises[0].sets[0].timestamp = Date()
        let next = try XCTUnwrap(session.nextSupersetTarget(afterCompleting: a1))
        XCTAssertEqual(next.setID, b1, "Na A hoort B (zelfde ronde)")
        XCTAssertFalse(session.shouldStartRest(afterCompleting: a1))

        session.exercises[1].sets[0].timestamp = Date()
        XCTAssertNil(session.nextSupersetTarget(afterCompleting: b1))
        XCTAssertTrue(session.shouldStartRest(afterCompleting: b1), "Rust start na de láátste oefening")
    }

    func testNormalExerciseAlwaysRests() {
        var session = ActiveWorkoutSession(name: "T", exercises: [openExercise(MockData.uid(1), sets: 2, rest: 90)])
        let first = session.exercises[0].sets[0].id
        session.exercises[0].sets[0].timestamp = Date()
        XCTAssertTrue(session.shouldStartRest(afterCompleting: first))
    }

    func testSwapKeepsCompletedSetsAndSnapsOpenWeights() throws {
        let chestPress = ex(1)
        let dumbbellPress = ex(2)
        var item = openExercise(chestPress.id, sets: 2, rest: 120)
        item.gymEquipmentID = MockData.uid(904)
        item.sets[0].weight = 45
        item.sets[0].reps = 8
        item.sets[0].timestamp = Date()
        item.sets[1].weight = 52        // al ingetypt, maar nog niet gedaan
        var session = ActiveWorkoutSession(name: "T", exercises: [item])

        session.swapExercise(item.id, to: dumbbellPress, gym: gym)

        let swapped = session.exercises[0]
        XCTAssertEqual(swapped.sets.count, 2, "Er gaat geen set verloren")
        XCTAssertEqual(swapped.exerciseID, dumbbellPress.id)
        XCTAssertEqual(swapped.plannedExerciseID, chestPress.id)
        XCTAssertTrue(swapped.wasSwapped)
        XCTAssertEqual(swapped.gymEquipmentID, MockData.uid(902), "Nu de dumbbells van jouw gym")

        XCTAssertEqual(swapped.sets[0].exerciseID, chestPress.id, "Afgeronde set blijft bij de chest press")
        XCTAssertEqual(swapped.sets[0].weight, 45)
        XCTAssertEqual(swapped.sets[1].exerciseID, dumbbellPress.id)
        XCTAssertEqual(swapped.sets[1].weight, 40, "52 kg bestaat niet bij dumbbells (max 40)")
    }

    func testLinkAndUnlinkSuperset() {
        var session = ActiveWorkoutSession(name: "T", exercises: [
            openExercise(MockData.uid(12), sets: 2, rest: 60),
            openExercise(MockData.uid(20), sets: 2, rest: 60)
        ])
        XCTAssertEqual(session.blocks.count, 2)
        session.linkWithPrevious(session.exercises[1].id)
        XCTAssertEqual(session.blocks.count, 1)
        session.unlinkSuperset(session.exercises[1].id)
        XCTAssertEqual(session.blocks.count, 2)
    }
}

// MARK: - Alternatieven en historie

final class AlternativesAndHistoryTests: XCTestCase {

    func testSuggestionsCuratedFirst() {
        let suggester = AlternativeSuggester(library: library, gym: gym)
        let top = suggester.suggestions(for: ex(1), limit: 3)
        XCTAssertEqual(top.first?.reason, .curated)
        XCTAssertEqual(Set(top.map { $0.exercise.id }), Set([2, 3, 4].map { MockData.uid($0) }))
    }

    func testSuggestionsOnlyContainWhatYourGymHas() {
        // Jouw gym heeft geen shoulder press machine, dus die mag nooit worden voorgesteld.
        let suggester = AlternativeSuggester(library: library, gym: gym)
        let current = ex(11)   // dumbbell shoulder press, voorkeur = machine (niet beschikbaar)
        let suggestions = suggester.suggestions(for: current)
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertFalse(suggestions.contains { $0.exercise.id == MockData.uid(10) })

        let preferred = suggester.preferred(for: current)
        XCTAssertEqual(preferred?.exercise.id, MockData.uid(10))
        XCTAssertEqual(preferred?.isAvailable, false)
    }

    func testExcludedExercisesAreSkipped() {
        let suggester = AlternativeSuggester(library: library, gym: gym)
        let excluded = Set([2, 3, 4].map { MockData.uid($0) })
        let suggestions = suggester.suggestions(for: ex(1), excluding: excluded)
        XCTAssertTrue(suggestions.allSatisfy { !excluded.contains($0.exercise.id) })
    }

    func testPlaceholdersComeFromTheLastSessionOnTheSameMachine() {
        let history = WorkoutHistory(sessions: MockData.appData().history)
        let sets = history.lastPerformance(of: MockData.uid(1), onEquipment: MockData.uid(904))
        XCTAssertEqual(sets.count, 3)
        XCTAssertTrue(sets.allSatisfy { $0.weight == 55 }, "De nieuwste sessie (3 dagen geleden) wint")

        let otherMachine = history.lastPerformance(of: MockData.uid(1), onEquipment: UUID())
        XCTAssertEqual(otherMachine.count, 3, "Onbekend apparaat → terugvallen op elk apparaat")
        XCTAssertTrue(history.lastPerformance(of: MockData.uid(57), onEquipment: nil).isEmpty)
    }

    func testMockDataIsConsistent() {
        let data = MockData.appData()
        let ids = Set(data.exercises.map { $0.id })
        XCTAssertEqual(ids.count, data.exercises.count, "Dubbele oefening-ID's")
        for exercise in data.exercises {
            XCTAssertTrue(exercise.defaultAlternativeIDs.allSatisfy { ids.contains($0) }, exercise.name)
            if let preferred = exercise.preferredAlternativeID { XCTAssertTrue(ids.contains(preferred), exercise.name) }
        }
        for template in data.templates {
            XCTAssertTrue(template.items.allSatisfy { ids.contains($0.exerciseID) }, template.name)
        }
        XCTAssertEqual(data.history.count, 2)
        let templateIDs = Set(data.templates.map { $0.id })
        for program in data.programs {
            XCTAssertTrue(program.workoutIDs.allSatisfy { templateIDs.contains($0) }, program.name)
        }
        XCTAssertEqual(data.settings.currentProgramID, data.programs.first?.id)
        XCTAssertEqual(data.settings.currentGymID, data.gyms.first?.id)
    }

    func testExerciseNamesAreEnglish() {
        let names = Set(MockData.exercises().map { $0.name })
        for expected in ["Chest press machine", "Dumbbell bench press", "Cable lateral raise", "Pull-up", "Romanian deadlift"] {
            XCTAssertTrue(names.contains(expected), expected)
        }
        XCTAssertFalse(names.contains("Optrekken"))
    }
}
