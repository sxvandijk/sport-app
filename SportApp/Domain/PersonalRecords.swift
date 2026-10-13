import Foundation

/// Geschatte 1RM.
enum E1RM {
    /// Boven dit aantal herhalingen wordt de formule te onnauwkeurig om een PR op te baseren.
    static let maxReliableReps = 10

    /// Epley: gewicht × (1 + reps / 30). Eén herhaling is gewoon het gewicht zelf.
    static func epley(weight: Double, reps: Int) -> Double? {
        guard weight > 0, reps >= 1, reps <= maxReliableReps else { return nil }
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30)
    }
}

struct RecordEntry: Codable, Hashable {
    var weight: Double
    var reps: Int
    var date: Date
    var e1RM: Double?
}

struct ExerciseRecord: Codable, Hashable {
    var exerciseID: UUID
    /// Zwaarste gewicht ooit (bij gelijk gewicht: de meeste herhalingen).
    var heaviest: RecordEntry?
    /// Hoogste geschatte 1RM.
    var bestE1RM: RecordEntry?

    init(exerciseID: UUID, heaviest: RecordEntry? = nil, bestE1RM: RecordEntry? = nil) {
        self.exerciseID = exerciseID
        self.heaviest = heaviest
        self.bestE1RM = bestE1RM
    }
}

enum PRKind: String, Hashable {
    case heaviestWeight
    case estimated1RM
}

enum PRService {
    private static let tolerance = 0.0001

    /// Bouwt de records op uit afgeronde sets (warm-ups tellen niet mee).
    static func records(from sessions: [ActiveWorkoutSession]) -> [UUID: ExerciseRecord] {
        var records: [UUID: ExerciseRecord] = [:]
        for session in sessions.sorted(by: { $0.startedAt < $1.startedAt }) {
            for exercise in session.exercises {
                for set in exercise.sets {
                    absorb(set, into: &records)
                }
            }
        }
        return records
    }

    /// Verwerkt één set in de records.
    static func absorb(_ set: WorkoutSet, into records: inout [UUID: ExerciseRecord]) {
        guard set.isCompleted, !set.isWarmup,
              let weight = set.weight, let reps = set.reps,
              weight > 0, reps > 0, let date = set.timestamp else { return }

        var record = records[set.exerciseID] ?? ExerciseRecord(exerciseID: set.exerciseID)
        let candidate = RecordEntry(weight: weight, reps: reps, date: date, e1RM: E1RM.epley(weight: weight, reps: reps))

        if let current = record.heaviest {
            let heavier = candidate.weight > current.weight + tolerance
            let sameWeightMoreReps = abs(candidate.weight - current.weight) <= tolerance && candidate.reps > current.reps
            if heavier || sameWeightMoreReps { record.heaviest = candidate }
        } else {
            record.heaviest = candidate
        }

        if let estimate = candidate.e1RM {
            let currentBest = record.bestE1RM?.e1RM ?? 0
            if estimate > currentBest + tolerance { record.bestE1RM = candidate }
        }
        records[set.exerciseID] = record
    }

    /// Welke records zou deze set breken? Aanroepen vóórdat de set in `records` is opgenomen.
    /// De allereerste keer dat je een oefening doet is geen "PR": dan is er nog niets om te verbeteren.
    static func newRecords(for set: WorkoutSet, against records: [UUID: ExerciseRecord]) -> [PRKind] {
        guard set.isCompleted, !set.isWarmup,
              let weight = set.weight, let reps = set.reps,
              weight > 0, reps > 0,
              let existing = records[set.exerciseID] else { return [] }

        var kinds: [PRKind] = []
        if let heaviest = existing.heaviest, weight > heaviest.weight + tolerance {
            kinds.append(.heaviestWeight)
        }
        if let estimate = E1RM.epley(weight: weight, reps: reps),
           let best = existing.bestE1RM?.e1RM,
           estimate > best + tolerance {
            kinds.append(.estimated1RM)
        }
        return kinds
    }
}
