import Foundation

/// Bedenkt alternatieven voor "machine bezet". Alleen oefeningen die in de gym kunnen.
struct AlternativeSuggester {
    let library: ExerciseLibrary
    let gym: GymProfile?

    enum Reason: String, Hashable {
        case curated, sameMovement, sameMuscle

        var label: String {
            switch self {
            case .curated: return "Vast alternatief"
            case .sameMovement: return "Zelfde beweging"
            case .sameMuscle: return "Zelfde spiergroep"
            }
        }
    }

    struct Suggestion: Identifiable, Hashable {
        let exercise: Exercise
        let reason: Reason
        let score: Int
        let equipmentName: String?
        var id: UUID { exercise.id }
    }

    func isAvailable(_ exercise: Exercise) -> Bool {
        gym?.supports(exercise) ?? true
    }

    /// Gerangschikt op score. `excluding` = oefeningen die al in de workout zitten.
    func suggestions(for current: Exercise, excluding: Set<UUID> = [], limit: Int = 5) -> [Suggestion] {
        var result: [Suggestion] = []
        for candidate in library.all where candidate.id != current.id && !excluding.contains(candidate.id) {
            guard isAvailable(candidate) else { continue }

            let isCurated = current.defaultAlternativeIDs.contains(candidate.id)
                || current.preferredAlternativeID == candidate.id
            let sameMuscle = candidate.primaryMuscle == current.primaryMuscle
            guard isCurated || sameMuscle else { continue }

            let sameMovement = candidate.movement == current.movement && candidate.movement != .other

            var score = 0
            if isCurated { score += 50 }
            if sameMuscle { score += 20 }
            if sameMovement { score += 30 }
            score += 5 * Set(candidate.secondaryMuscles).intersection(current.secondaryMuscles).count
            // Het draait om een ándere machine: hetzelfde type apparaat is minder interessant.
            if candidate.equipmentTypeID == current.equipmentTypeID { score -= 15 }

            let reason: Reason = isCurated ? .curated : (sameMovement ? .sameMovement : .sameMuscle)
            let equipmentName = gym?.equipment(forTypeID: candidate.equipmentTypeID).first?.name
                ?? EquipmentType.type(withID: candidate.equipmentTypeID)?.name
            result.append(Suggestion(exercise: candidate, reason: reason, score: score, equipmentName: equipmentName))
        }

        result.sort { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.exercise.name.localizedCaseInsensitiveCompare(rhs.exercise.name) == .orderedAscending
        }
        return Array(result.prefix(limit))
    }

    /// Het alternatief dat de gebruiker zelf heeft ingesteld.
    func preferred(for current: Exercise, excluding: Set<UUID> = []) -> (exercise: Exercise, isAvailable: Bool)? {
        guard let id = current.preferredAlternativeID,
              !excluding.contains(id),
              let exercise = library[id] else { return nil }
        return (exercise, isAvailable(exercise))
    }
}
