import Foundation

/// Soort set. Alleen een warming-up telt niet mee voor "sets te gaan", volume en records.
enum SetKind: String, Codable, CaseIterable, Hashable {
    case warmup, working, drop, failure

    var countsTowardWork: Bool { self != .warmup }
}

/// Eén set. `exerciseID` is de oefening waarop de set écht is uitgevoerd. Dat blijft kloppen na een
/// "machine bezet"-wissel: al afgeronde sets houden hun oorspronkelijke oefening (juiste PR's en historie).
struct WorkoutSet: Identifiable, Codable, Hashable {
    var id: UUID
    var exerciseID: UUID
    var weight: Double?
    var reps: Int?
    var kind: SetKind
    /// Moment van afvinken. `nil` = nog niet gedaan. Dit is de enige bron van waarheid voor "afgerond".
    var timestamp: Date?

    var isCompleted: Bool { timestamp != nil }
    var isWarmup: Bool { kind == .warmup }

    /// Volume (gewicht × reps) van een afgeronde set.
    var volume: Double {
        guard isCompleted, let weight = weight, let reps = reps else { return 0 }
        return weight * Double(reps)
    }

    init(id: UUID = UUID(),
         exerciseID: UUID,
         weight: Double? = nil,
         reps: Int? = nil,
         kind: SetKind = .working,
         timestamp: Date? = nil) {
        self.id = id
        self.exerciseID = exerciseID
        self.weight = weight
        self.reps = reps
        self.kind = kind
        self.timestamp = timestamp
    }
}

/// Een oefening binnen een lopende workout.
struct SessionExercise: Identifiable, Codable, Hashable {
    var id: UUID
    /// De oefening uit het schema. Verandert nooit door een wissel.
    var plannedExerciseID: UUID
    /// De oefening die je nu doet (na een eventuele wissel).
    var exerciseID: UUID
    var gymEquipmentID: UUID?
    var supersetGroupID: UUID?
    var restSeconds: Int
    var targetRepsMin: Int
    var targetRepsMax: Int
    var sets: [WorkoutSet]

    var wasSwapped: Bool { plannedExerciseID != exerciseID }

    init(id: UUID = UUID(),
         plannedExerciseID: UUID,
         exerciseID: UUID,
         gymEquipmentID: UUID? = nil,
         supersetGroupID: UUID? = nil,
         restSeconds: Int = 90,
         targetRepsMin: Int = 8,
         targetRepsMax: Int = 12,
         sets: [WorkoutSet] = []) {
        self.id = id
        self.plannedExerciseID = plannedExerciseID
        self.exerciseID = exerciseID
        self.gymEquipmentID = gymEquipmentID
        self.supersetGroupID = supersetGroupID
        self.restSeconds = restSeconds
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.sets = sets
    }
}

/// Opeenvolgende oefeningen met dezelfde superset-groep vormen één blok. Een blok met één oefening is gewoon een oefening.
struct ExerciseBlock: Identifiable, Hashable {
    let id: UUID
    var exercises: [SessionExercise]
    var isSuperset: Bool { exercises.count > 1 }
}

/// Een lopende of afgeronde workout. Afgeronde workouts hebben `endedAt`.
struct ActiveWorkoutSession: Identifiable, Codable, Hashable {
    var id: UUID
    var templateID: UUID?
    var name: String
    var gymID: UUID?
    var startedAt: Date
    var endedAt: Date?
    var exercises: [SessionExercise]

    init(id: UUID = UUID(),
         templateID: UUID? = nil,
         name: String,
         gymID: UUID? = nil,
         startedAt: Date = Date(),
         endedAt: Date? = nil,
         exercises: [SessionExercise] = []) {
        self.id = id
        self.templateID = templateID
        self.name = name
        self.gymID = gymID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.exercises = exercises
    }

    // MARK: - Opbouwen

    static func make(from template: WorkoutTemplate?,
                     gym: GymProfile?,
                     library: ExerciseLibrary,
                     now: Date = Date()) -> ActiveWorkoutSession {
        var exercises: [SessionExercise] = []
        for item in template?.items ?? [] {
            guard let exercise = library[item.exerciseID] else { continue }
            let equipment = gym?.equipment(forTypeID: exercise.equipmentTypeID).first
            var sets: [WorkoutSet] = []
            if item.hasWarmupSet {
                sets.append(WorkoutSet(exerciseID: exercise.id, kind: .warmup))
            }
            for _ in 0..<max(1, item.targetSets) {
                sets.append(WorkoutSet(exerciseID: exercise.id))
            }
            exercises.append(SessionExercise(plannedExerciseID: exercise.id,
                                             exerciseID: exercise.id,
                                             gymEquipmentID: equipment?.id,
                                             supersetGroupID: item.supersetGroupID,
                                             restSeconds: item.restSeconds,
                                             targetRepsMin: item.minReps,
                                             targetRepsMax: item.maxReps,
                                             sets: sets))
        }

        return ActiveWorkoutSession(templateID: template?.id,
                                    name: template?.name ?? "Vrije training",
                                    gymID: gym?.id,
                                    startedAt: now,
                                    exercises: exercises)
    }

    // MARK: - Opvragen

    func elapsed(at now: Date = Date()) -> TimeInterval {
        max(0, (endedAt ?? now).timeIntervalSince(startedAt))
    }

    var blocks: [ExerciseBlock] {
        var result: [ExerciseBlock] = []
        for exercise in exercises {
            if let group = exercise.supersetGroupID,
               let last = result.last,
               last.exercises.last?.supersetGroupID == group {
                result[result.count - 1].exercises.append(exercise)
            } else {
                result.append(ExerciseBlock(id: exercise.id, exercises: [exercise]))
            }
        }
        return result
    }

    func location(ofSet setID: UUID) -> (exercise: Int, set: Int)? {
        for (e, exercise) in exercises.enumerated() {
            if let s = exercise.sets.firstIndex(where: { $0.id == setID }) {
                return (e, s)
            }
        }
        return nil
    }

    var completedWorkingSetCount: Int {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.isCompleted && $0.kind.countsTowardWork }.count
        }
    }

    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { !$0.isWarmup }.reduce(0) { $0 + $1.volume }
        }
    }

    // MARK: - Superset-logica

    private func blockRange(around index: Int) -> Range<Int> {
        guard let group = exercises[index].supersetGroupID else { return index..<(index + 1) }
        var low = index
        var high = index
        while low > 0, exercises[low - 1].supersetGroupID == group { low -= 1 }
        while high + 1 < exercises.count, exercises[high + 1].supersetGroupID == group { high += 1 }
        return low..<(high + 1)
    }

    /// Positie van een werkset binnen zijn oefening (0 = eerste werkset). `nil` voor warm-up sets.
    func workingSetPosition(exercise e: Int, set s: Int) -> Int? {
        guard !exercises[e].sets[s].isWarmup else { return nil }
        return exercises[e].sets[..<s].filter { !$0.isWarmup }.count
    }

    /// De volgende oefening in dezelfde superset die in deze ronde nog een open set heeft.
    func nextSupersetTarget(afterCompleting setID: UUID) -> (exerciseID: UUID, setID: UUID)? {
        guard let loc = location(ofSet: setID),
              let round = workingSetPosition(exercise: loc.exercise, set: loc.set) else { return nil }
        let range = blockRange(around: loc.exercise)
        guard range.count > 1 else { return nil }
        for e in (loc.exercise + 1)..<range.upperBound {
            let working = exercises[e].sets.filter { !$0.isWarmup }
            if round < working.count, !working[round].isCompleted {
                return (exercises[e].id, working[round].id)
            }
        }
        return nil
    }

    /// Rusttimer start na de láátste oefening van een superset-ronde, niet na elke oefening.
    func shouldStartRest(afterCompleting setID: UUID) -> Bool {
        guard let loc = location(ofSet: setID) else { return false }
        if exercises[loc.exercise].sets[loc.set].isWarmup { return true }
        return nextSupersetTarget(afterCompleting: setID) == nil
    }

    // MARK: - Wijzigen

    mutating func addSet(toExercise sessionExerciseID: UUID, kind: SetKind = .working) {
        guard let i = exercises.firstIndex(where: { $0.id == sessionExerciseID }) else { return }
        let newSet = WorkoutSet(exerciseID: exercises[i].exerciseID, kind: kind)
        if kind == .warmup {
            let position = (exercises[i].sets.lastIndex(where: { $0.isWarmup }) ?? -1) + 1
            exercises[i].sets.insert(newSet, at: position)
        } else {
            exercises[i].sets.append(newSet)
        }
    }

    mutating func removeSet(_ setID: UUID) {
        guard let loc = location(ofSet: setID) else { return }
        exercises[loc.exercise].sets.remove(at: loc.set)
    }

    mutating func addExercise(_ exercise: Exercise, gymEquipmentID: UUID?, restSeconds: Int, sets: Int = 3) {
        var newSets: [WorkoutSet] = []
        for _ in 0..<max(1, sets) {
            newSets.append(WorkoutSet(exerciseID: exercise.id))
        }
        exercises.append(SessionExercise(plannedExerciseID: exercise.id,
                                         exerciseID: exercise.id,
                                         gymEquipmentID: gymEquipmentID,
                                         restSeconds: restSeconds,
                                         sets: newSets))
    }

    mutating func removeExercise(_ sessionExerciseID: UUID) {
        exercises.removeAll { $0.id == sessionExerciseID }
    }

    /// "Machine bezet": vervangt de oefening zonder ingevulde sets te verliezen.
    /// - Afgeronde sets blijven bij hun oorspronkelijke oefening staan (`WorkoutSet.exerciseID`).
    /// - Open sets gaan naar de nieuwe oefening. Een al ingetypt gewicht blijft staan, afgerond op
    ///   de gewichtsstappen van het nieuwe apparaat.
    mutating func swapExercise(_ sessionExerciseID: UUID, to newExercise: Exercise, gym: GymProfile?) {
        guard let i = exercises.firstIndex(where: { $0.id == sessionExerciseID }) else { return }
        guard exercises[i].exerciseID != newExercise.id else { return }

        let equipment = gym?.equipment(forTypeID: newExercise.equipmentTypeID).first
        exercises[i].exerciseID = newExercise.id
        exercises[i].gymEquipmentID = equipment?.id

        for s in exercises[i].sets.indices where !exercises[i].sets[s].isCompleted {
            exercises[i].sets[s].exerciseID = newExercise.id
            if let weight = exercises[i].sets[s].weight, let scale = equipment?.scale {
                exercises[i].sets[s].weight = scale.snap(weight)
            }
        }
    }

    mutating func linkWithPrevious(_ sessionExerciseID: UUID) {
        guard let i = exercises.firstIndex(where: { $0.id == sessionExerciseID }), i > 0 else { return }
        let group = exercises[i - 1].supersetGroupID ?? UUID()
        exercises[i - 1].supersetGroupID = group
        exercises[i].supersetGroupID = group
    }

    mutating func unlinkSuperset(_ sessionExerciseID: UUID) {
        guard let i = exercises.firstIndex(where: { $0.id == sessionExerciseID }) else { return }
        exercises[i].supersetGroupID = nil
    }
}
