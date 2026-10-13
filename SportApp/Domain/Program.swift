import Foundation

/// Een schema ("Push Pull Legs"): een geordende lijst trainingen. De trainingen zelf staan in `AppData.templates`.
struct Program: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var workoutIDs: [UUID]

    init(id: UUID = UUID(), name: String, workoutIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.workoutIDs = workoutIDs
    }

    /// De volgende training in de rotatie (DESIGN.md 6.1): de training na de laatst gedane training uit dit schema,
    /// na de laatste weer de eerste. Is er nog niets gedaan, dan is de eerste training de volgende.
    /// - Parameter doneTemplateIDs: afgeronde trainingen, nieuwste eerst.
    func nextWorkoutID(afterDone doneTemplateIDs: [UUID]) -> UUID? {
        guard !workoutIDs.isEmpty else { return nil }
        guard let lastDone = doneTemplateIDs.first(where: { workoutIDs.contains($0) }),
              let index = workoutIDs.firstIndex(of: lastDone) else {
            return workoutIDs[0]
        }
        return workoutIDs[(index + 1) % workoutIDs.count]
    }
}
