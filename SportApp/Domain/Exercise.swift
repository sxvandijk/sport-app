import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var primaryMuscle: MuscleGroup
    var secondaryMuscles: [MuscleGroup]
    /// Welk type apparaat nodig is (verwijst naar `EquipmentType.id`).
    var equipmentTypeID: String
    var movement: MovementPattern
    /// Vaste alternatieven, bedoeld voor "machine bezet".
    var defaultAlternativeIDs: [UUID]
    /// Het alternatief dat de gebruiker zelf vooraf heeft ingesteld.
    var preferredAlternativeID: UUID?
    var defaultRestSeconds: Int
    /// Eigen YouTube- of TikTok-link voor de uitleg van deze oefening. Geldt ook voor volgende trainingen.
    var customVideoURL: URL?

    init(id: UUID = UUID(),
         name: String,
         primaryMuscle: MuscleGroup,
         secondaryMuscles: [MuscleGroup] = [],
         equipmentTypeID: String,
         movement: MovementPattern = .other,
         defaultAlternativeIDs: [UUID] = [],
         preferredAlternativeID: UUID? = nil,
         defaultRestSeconds: Int = 90,
         customVideoURL: URL? = nil) {
        self.id = id
        self.name = name
        self.primaryMuscle = primaryMuscle
        self.secondaryMuscles = secondaryMuscles
        self.equipmentTypeID = equipmentTypeID
        self.movement = movement
        self.defaultAlternativeIDs = defaultAlternativeIDs
        self.preferredAlternativeID = preferredAlternativeID
        self.defaultRestSeconds = defaultRestSeconds
        self.customVideoURL = customVideoURL
    }

    var equipmentName: String {
        EquipmentType.type(withID: equipmentTypeID)?.name ?? equipmentTypeID
    }
}

/// Snelle opzoeklijst van alle oefeningen.
struct ExerciseLibrary {
    let all: [Exercise]
    private let index: [UUID: Exercise]

    init(_ exercises: [Exercise]) {
        self.all = exercises.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        self.index = Dictionary(exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    subscript(id: UUID) -> Exercise? {
        index[id]
    }

    /// Zoekt op naam, spiergroep en apparaatnaam. Hoofdletter- en accentongevoelig.
    func search(_ query: String) -> [Exercise] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return all }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        return all.filter { exercise in
            exercise.name.range(of: trimmed, options: options) != nil
                || exercise.primaryMuscle.displayName.range(of: trimmed, options: options) != nil
                || exercise.equipmentName.range(of: trimmed, options: options) != nil
        }
    }
}
