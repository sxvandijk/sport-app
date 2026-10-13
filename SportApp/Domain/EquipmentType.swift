import Foundation

/// Een soort apparaat (bv. "chest press machine"), los van een specifieke gym.
/// `GymEquipment` is het fysieke exemplaar in jouw gym, met eigen gewichtsstappen.
struct EquipmentType: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var defaultKind: WeightScale.Kind

    /// Lichaamsgewicht-oefeningen hebben geen apparaat nodig in de gym.
    var isAlwaysAvailable: Bool { defaultKind == .bodyweight }
}

extension EquipmentType {
    static let barbell = EquipmentType(id: "barbell", name: "Stang", defaultKind: .barbell)
    static let dumbbell = EquipmentType(id: "dumbbell", name: "Dumbbells", defaultKind: .dumbbells)
    static let cable = EquipmentType(id: "cable_station", name: "Cable station", defaultKind: .stack)
    static let chestPress = EquipmentType(id: "chest_press_machine", name: "Chest press machine", defaultKind: .stack)
    static let pecDeck = EquipmentType(id: "pec_deck", name: "Pec deck", defaultKind: .stack)
    static let shoulderPress = EquipmentType(id: "shoulder_press_machine", name: "Shoulder press machine", defaultKind: .stack)
    static let latPulldown = EquipmentType(id: "lat_pulldown", name: "Lat pulldown", defaultKind: .stack)
    static let seatedRow = EquipmentType(id: "seated_row", name: "Seated row", defaultKind: .stack)
    static let rowMachine = EquipmentType(id: "row_machine", name: "Row machine", defaultKind: .plateLoaded)
    static let legPress = EquipmentType(id: "leg_press", name: "Leg press", defaultKind: .plateLoaded)
    static let legExtension = EquipmentType(id: "leg_extension", name: "Leg extension", defaultKind: .stack)
    static let legCurl = EquipmentType(id: "leg_curl", name: "Leg curl", defaultKind: .stack)
    static let calfMachine = EquipmentType(id: "calf_machine", name: "Calf raise machine", defaultKind: .stack)
    static let bodyweight = EquipmentType(id: "bodyweight", name: "Lichaamsgewicht", defaultKind: .bodyweight)

    static let catalog: [EquipmentType] = [
        .barbell, .dumbbell, .cable, .chestPress, .pecDeck, .shoulderPress, .latPulldown,
        .seatedRow, .rowMachine, .legPress, .legExtension, .legCurl, .calfMachine, .bodyweight
    ]

    static func type(withID id: String) -> EquipmentType? {
        catalog.first { $0.id == id }
    }
}
