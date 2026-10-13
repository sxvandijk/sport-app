import Foundation

/// Afgeronde workouts, voor de grijze placeholders ("vorige keer") tijdens het trainen.
struct WorkoutHistory {
    private let ordered: [ActiveWorkoutSession]

    init(sessions: [ActiveWorkoutSession]) {
        self.ordered = sessions.sorted { $0.startedAt > $1.startedAt }
    }

    /// De afgeronde sets van de laatste keer dat je deze oefening deed.
    /// Eerst op hetzelfde apparaat (gewichten zijn alleen vergelijkbaar op dezelfde machine),
    /// anders op elk apparaat.
    func lastPerformance(of exerciseID: UUID, onEquipment equipmentID: UUID?) -> [WorkoutSet] {
        if let equipmentID = equipmentID,
           let sets = find(exerciseID: exerciseID, equipmentID: equipmentID) {
            return sets
        }
        return find(exerciseID: exerciseID, equipmentID: nil) ?? []
    }

    private func find(exerciseID: UUID, equipmentID: UUID?) -> [WorkoutSet]? {
        for session in ordered {
            for exercise in session.exercises {
                if let equipmentID = equipmentID, exercise.gymEquipmentID != equipmentID { continue }
                let sets = exercise.sets.filter { $0.exerciseID == exerciseID && $0.isCompleted }
                if !sets.isEmpty { return sets }
            }
        }
        return nil
    }
}
