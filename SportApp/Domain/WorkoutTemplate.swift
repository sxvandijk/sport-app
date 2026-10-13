import Foundation

struct TemplateItem: Identifiable, Codable, Hashable {
    var id: UUID
    var exerciseID: UUID
    var targetSets: Int
    var minReps: Int
    var maxReps: Int
    var restSeconds: Int
    /// Of deze oefening begint met een warming-upset (schakelaar "Warming-upset" in de schema-editor).
    var hasWarmupSet: Bool
    /// Items die direct na elkaar staan en dezelfde groep hebben, vormen samen één superset.
    var supersetGroupID: UUID?

    init(id: UUID = UUID(),
         exerciseID: UUID,
         targetSets: Int = 3,
         minReps: Int = 8,
         maxReps: Int = 12,
         restSeconds: Int = 90,
         hasWarmupSet: Bool = false,
         supersetGroupID: UUID? = nil) {
        self.id = id
        self.exerciseID = exerciseID
        self.targetSets = targetSets
        self.minReps = minReps
        self.maxReps = maxReps
        self.restSeconds = restSeconds
        self.hasWarmupSet = hasWarmupSet
        self.supersetGroupID = supersetGroupID
    }
}

/// Eén training ("Push A"). Een training kan in meerdere schema's staan.
struct WorkoutTemplate: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var items: [TemplateItem]

    init(id: UUID = UUID(), name: String, items: [TemplateItem] = []) {
        self.id = id
        self.name = name
        self.items = items
    }
}
