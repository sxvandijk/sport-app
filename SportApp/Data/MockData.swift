import Foundation

/// Voorbeelddata om de app direct te kunnen testen: oefeningen, een gym met verschillende gewichtsstappen,
/// drie schema's en twee eerdere Push-workouts (voor placeholders en PR's).
enum MockData {

    // Vaste ID's, zodat oefeningen naar elkaar kunnen verwijzen en tests voorspelbaar zijn.
    static func uid(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012ld", n))!
    }

    static let gymID = uid(900)
    static let programID = uid(700)

    // MARK: - Oefeningen

    private static func ex(_ n: Int,
                           _ name: String,
                           _ muscle: MuscleGroup,
                           _ equipment: EquipmentType,
                           _ movement: MovementPattern,
                           secondary: [MuscleGroup] = [],
                           alt: [Int] = [],
                           preferred: Int? = nil,
                           rest: Int = 90) -> Exercise {
        Exercise(id: uid(n),
                 name: name,
                 primaryMuscle: muscle,
                 secondaryMuscles: secondary,
                 equipmentTypeID: equipment.id,
                 movement: movement,
                 defaultAlternativeIDs: alt.map { uid($0) },
                 preferredAlternativeID: preferred.map { uid($0) },
                 defaultRestSeconds: rest)
    }

    static func exercises() -> [Exercise] {
        [
            // Borst
            ex(1, "Chest press machine", .chest, .chestPress, .horizontalPush, secondary: [.triceps, .shoulders], alt: [2, 4, 3], preferred: 2, rest: 120),
            ex(2, "Dumbbell bench press", .chest, .dumbbell, .horizontalPush, secondary: [.triceps, .shoulders], alt: [1, 3, 7], preferred: 3, rest: 120),
            ex(3, "Incline dumbbell press", .chest, .dumbbell, .horizontalPush, secondary: [.shoulders, .triceps], alt: [2, 1], rest: 90),
            ex(4, "Barbell bench press", .chest, .barbell, .horizontalPush, secondary: [.triceps, .shoulders], alt: [2, 1], preferred: 2, rest: 150),
            ex(5, "Pec deck", .chest, .pecDeck, .isolation, alt: [6], preferred: 6, rest: 60),
            ex(6, "Cable fly", .chest, .cable, .isolation, alt: [5], preferred: 5, rest: 60),
            ex(7, "Push-up", .chest, .bodyweight, .horizontalPush, secondary: [.triceps, .shoulders], alt: [2], rest: 60),
            // Schouders
            ex(10, "Shoulder press machine", .shoulders, .shoulderPress, .verticalPush, secondary: [.triceps], alt: [11], preferred: 11, rest: 90),
            ex(11, "Dumbbell shoulder press", .shoulders, .dumbbell, .verticalPush, secondary: [.triceps], alt: [10], preferred: 10, rest: 90),
            ex(12, "Dumbbell lateral raise", .shoulders, .dumbbell, .isolation, alt: [13], preferred: 13, rest: 60),
            ex(13, "Cable lateral raise", .shoulders, .cable, .isolation, alt: [12], preferred: 12, rest: 60),
            // Triceps
            ex(20, "Triceps pushdown", .triceps, .cable, .isolation, alt: [21], preferred: 21, rest: 60),
            ex(21, "Cable overhead triceps extension", .triceps, .cable, .isolation, alt: [20], preferred: 20, rest: 60),
            // Rug
            ex(30, "Lat pulldown", .lats, .latPulldown, .verticalPull, secondary: [.biceps, .upperBack], alt: [31, 33], preferred: 31, rest: 90),
            ex(31, "Pull-up", .lats, .bodyweight, .verticalPull, secondary: [.biceps, .upperBack], alt: [30], preferred: 30, rest: 120),
            ex(32, "Seated cable row", .upperBack, .seatedRow, .horizontalPull, secondary: [.biceps, .lats], alt: [33, 34], preferred: 34, rest: 90),
            ex(33, "Chest-supported row machine", .upperBack, .rowMachine, .horizontalPull, secondary: [.biceps, .lats], alt: [32, 34], rest: 90),
            ex(34, "One-arm dumbbell row", .upperBack, .dumbbell, .horizontalPull, secondary: [.biceps, .lats], alt: [32, 33], rest: 90),
            // Biceps
            ex(40, "Dumbbell curl", .biceps, .dumbbell, .isolation, alt: [41], preferred: 41, rest: 60),
            ex(41, "Cable curl", .biceps, .cable, .isolation, alt: [40], preferred: 40, rest: 60),
            // Benen
            ex(50, "Leg press", .quads, .legPress, .squat, secondary: [.glutes, .hamstrings], alt: [52], rest: 150),
            ex(51, "Leg extension", .quads, .legExtension, .isolation, alt: [50], rest: 75),
            ex(52, "Barbell squat", .quads, .barbell, .squat, secondary: [.glutes, .hamstrings, .core], alt: [50], rest: 180),
            ex(53, "Lying leg curl", .hamstrings, .legCurl, .isolation, alt: [54], rest: 75),
            ex(54, "Romanian deadlift", .hamstrings, .barbell, .hinge, secondary: [.glutes, .upperBack], alt: [53, 55], rest: 150),
            ex(55, "Barbell hip thrust", .glutes, .barbell, .hinge, secondary: [.hamstrings], alt: [54], rest: 120),
            ex(56, "Standing calf raise machine", .calves, .calfMachine, .isolation, rest: 60),
            ex(57, "Cable crunch", .core, .cable, .core, rest: 60),
            ex(58, "Cable external rotation", .shoulders, .cable, .isolation, rest: 45),
            ex(59, "Band pull-apart", .upperBack, .bodyweight, .horizontalPull, rest: 45)
        ]
    }

    // MARK: - Gym

    /// Bewust een gym zonder shoulder press machine en row machine, om het filteren van alternatieven te tonen.
    static func gym() -> GymProfile {
        GymProfile(id: gymID, name: "Mijn gym", equipment: [
            GymEquipment(id: uid(901), equipmentTypeID: EquipmentType.barbell.id, name: "Olympic barbell",
                         scale: .barbell(barWeight: 20, maxWeight: 200, smallestStep: 2.5)),
            GymEquipment(id: uid(902), equipmentTypeID: EquipmentType.dumbbell.id, name: "Dumbbells",
                         scale: .dumbbells(min: 2.5, max: 40, step: 2.5)),
            GymEquipment(id: uid(903), equipmentTypeID: EquipmentType.cable.id, name: "Cable station",
                         scale: .stack(min: 5, max: 70, step: 5, addOn: 2.5)),
            // Onregelmatige stapel: laat zien waarom een lijst nodig is naast min/max/stap.
            GymEquipment(id: uid(904), equipmentTypeID: EquipmentType.chestPress.id, name: "Chest press machine",
                         scale: WeightScale(kind: .stack,
                                            availableWeights: [10, 15, 20, 25, 30, 35, 40, 45, 55, 65, 75, 85, 100])),
            GymEquipment(id: uid(905), equipmentTypeID: EquipmentType.pecDeck.id, name: "Pec deck",
                         scale: .stack(min: 5, max: 80, step: 5)),
            GymEquipment(id: uid(906), equipmentTypeID: EquipmentType.latPulldown.id, name: "Lat pulldown",
                         scale: .stack(min: 5, max: 95, step: 5, addOn: 2.5)),
            GymEquipment(id: uid(907), equipmentTypeID: EquipmentType.seatedRow.id, name: "Seated row",
                         scale: .stack(min: 5, max: 95, step: 5)),
            GymEquipment(id: uid(908), equipmentTypeID: EquipmentType.legPress.id, name: "Leg press",
                         scale: .plateLoaded(min: 50, max: 300, step: 10)),
            GymEquipment(id: uid(909), equipmentTypeID: EquipmentType.legExtension.id, name: "Leg extension",
                         scale: .stack(min: 5, max: 90, step: 5)),
            GymEquipment(id: uid(910), equipmentTypeID: EquipmentType.legCurl.id, name: "Leg curl",
                         scale: .stack(min: 5, max: 90, step: 5)),
            GymEquipment(id: uid(911), equipmentTypeID: EquipmentType.calfMachine.id, name: "Calf raise machine",
                         scale: .stack(min: 10, max: 120, step: 10))
        ])
    }

    // MARK: - Schema's

    static func templates() -> [WorkoutTemplate] {
        let pushSuperset = uid(850)
        let pullSuperset = uid(851)
        let legSuperset = uid(852)
        let push = WorkoutTemplate(id: uid(800), name: "Push A", items: [
            TemplateItem(exerciseID: uid(1), targetSets: 3, minReps: 8, maxReps: 10, restSeconds: 120, hasWarmupSet: true),
            TemplateItem(exerciseID: uid(3), targetSets: 3, minReps: 8, maxReps: 12, restSeconds: 90),
            TemplateItem(exerciseID: uid(12), targetSets: 3, minReps: 12, maxReps: 15, restSeconds: 75, supersetGroupID: pushSuperset),
            TemplateItem(exerciseID: uid(20), targetSets: 3, minReps: 10, maxReps: 12, restSeconds: 75, supersetGroupID: pushSuperset),
            TemplateItem(exerciseID: uid(5), targetSets: 2, minReps: 12, maxReps: 15, restSeconds: 60)
        ])

        let pull = WorkoutTemplate(id: uid(801), name: "Pull A", items: [
            TemplateItem(exerciseID: uid(30), targetSets: 3, minReps: 8, maxReps: 12, restSeconds: 90, hasWarmupSet: true),
            TemplateItem(exerciseID: uid(32), targetSets: 3, minReps: 8, maxReps: 12, restSeconds: 90),
            TemplateItem(exerciseID: uid(34), targetSets: 2, minReps: 10, maxReps: 12, restSeconds: 90),
            TemplateItem(exerciseID: uid(40), targetSets: 2, minReps: 10, maxReps: 12, restSeconds: 60, supersetGroupID: pullSuperset),
            TemplateItem(exerciseID: uid(41), targetSets: 2, minReps: 10, maxReps: 12, restSeconds: 60, supersetGroupID: pullSuperset)
        ])

        let legs = WorkoutTemplate(id: uid(802), name: "Benen", items: [
            TemplateItem(exerciseID: uid(50), targetSets: 3, minReps: 8, maxReps: 12, restSeconds: 150, hasWarmupSet: true),
            TemplateItem(exerciseID: uid(54), targetSets: 3, minReps: 8, maxReps: 10, restSeconds: 150),
            TemplateItem(exerciseID: uid(51), targetSets: 3, minReps: 10, maxReps: 15, restSeconds: 75, supersetGroupID: legSuperset),
            TemplateItem(exerciseID: uid(53), targetSets: 3, minReps: 10, maxReps: 15, restSeconds: 75, supersetGroupID: legSuperset),
            TemplateItem(exerciseID: uid(56), targetSets: 3, minReps: 12, maxReps: 20, restSeconds: 60)
        ])

        return [push, pull, legs]
    }

    // MARK: - Historie

    private static func finishedSession(template: WorkoutTemplate,
                                        gym: GymProfile,
                                        library: ExerciseLibrary,
                                        daysAgo: Int,
                                        now: Date,
                                        weights: [Int: Double]) -> ActiveWorkoutSession {
        let start = Calendar.current.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        var session = ActiveWorkoutSession.make(from: template, gym: gym, library: library, now: start)
        var weightsByID: [UUID: Double] = [:]
        for (number, weight) in weights { weightsByID[uid(number)] = weight }

        var clock = start.addingTimeInterval(8 * 60)
        for e in session.exercises.indices {
            // De voorbeeldhistorie bevat alleen werksets, zodat gewichten en herhalingen voorspelbaar blijven.
            session.exercises[e].sets.removeAll { $0.isWarmup }
            for s in session.exercises[e].sets.indices {
                session.exercises[e].sets[s].weight = weightsByID[session.exercises[e].exerciseID]
                session.exercises[e].sets[s].reps = max(6, 10 - s)
                clock = clock.addingTimeInterval(110)
                session.exercises[e].sets[s].timestamp = clock
            }
        }
        session.endedAt = clock.addingTimeInterval(120)
        return session
    }

    static func appData(now: Date = Date()) -> AppData {
        // Bewust andere namen dan de functies hierboven: `let gym = gym()` geeft in Swift 5.7 een compileerfout.
        let allExercises = exercises()
        let library = ExerciseLibrary(allExercises)
        let mockGym = gym()
        let allTemplates = templates()
        let push = allTemplates[0]

        let older = finishedSession(template: push, gym: mockGym, library: library, daysAgo: 9, now: now,
                                    weights: [1: 45, 3: 17.5, 12: 7.5, 20: 25, 5: 35])
        let newer = finishedSession(template: push, gym: mockGym, library: library, daysAgo: 3, now: now,
                                    weights: [1: 55, 3: 20, 12: 7.5, 20: 30, 5: 40])

        let program = Program(id: programID, name: "Push Pull Legs", workoutIDs: allTemplates.map { $0.id })

        return AppData(version: AppData.currentVersion,
                       exercises: allExercises,
                       gyms: [mockGym],
                       templates: allTemplates,
                       programs: [program],
                       settings: UserSettings(currentGymID: mockGym.id, currentProgramID: program.id),
                       history: [older, newer],
                       activeSession: nil)
    }
}
