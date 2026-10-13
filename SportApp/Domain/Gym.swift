import Foundation

/// Alles wat een (toekomstige) foto-scan oplevert, naast de definitieve, door de gebruiker bevestigde waarden.
/// Zo kun je later opnieuw scannen met een beter model of een scan achteraf corrigeren.
struct ScanMetadata: Codable, Hashable {
    enum Source: String, Codable, Hashable {
        case manual, ocr, vision
    }

    var source: Source
    /// Ruwe OCR-tekst, onbewerkt.
    var rawScannedText: String?
    /// Getallen die de scan op de stapel vond (vóór correctie door de gebruiker).
    var detectedIncrements: [Double]
    /// Door Vision-AI herkend apparaattype/merk, bv. "Technogym Selection chest press".
    var detectedEquipmentLabel: String?
    /// 0...1, indien beschikbaar.
    var confidence: Double?
    /// Bestandsnaam van de bewaarde foto (in Application Support), niet de foto zelf.
    var photoFileName: String?
    var scannedAt: Date
    var userCorrected: Bool

    init(source: Source,
         rawScannedText: String? = nil,
         detectedIncrements: [Double] = [],
         detectedEquipmentLabel: String? = nil,
         confidence: Double? = nil,
         photoFileName: String? = nil,
         scannedAt: Date = Date(),
         userCorrected: Bool = false) {
        self.source = source
        self.rawScannedText = rawScannedText
        self.detectedIncrements = detectedIncrements
        self.detectedEquipmentLabel = detectedEquipmentLabel
        self.confidence = confidence
        self.photoFileName = photoFileName
        self.scannedAt = scannedAt
        self.userCorrected = userCorrected
    }
}

/// Eén fysiek apparaat in een gym, met zijn eigen gewichtsstappen.
struct GymEquipment: Identifiable, Codable, Hashable {
    var id: UUID
    var equipmentTypeID: String
    var name: String
    var scale: WeightScale
    var scan: ScanMetadata?

    init(id: UUID = UUID(), equipmentTypeID: String, name: String, scale: WeightScale, scan: ScanMetadata? = nil) {
        self.id = id
        self.equipmentTypeID = equipmentTypeID
        self.name = name
        self.scale = scale
        self.scan = scan
    }
}

/// Een gym met de apparaten die jij daar hebt aangevinkt.
struct GymProfile: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var equipment: [GymEquipment]

    init(id: UUID = UUID(), name: String, equipment: [GymEquipment] = []) {
        self.id = id
        self.name = name
        self.equipment = equipment
    }

    func equipment(forTypeID typeID: String) -> [GymEquipment] {
        equipment.filter { $0.equipmentTypeID == typeID }
    }

    func equipment(withID id: UUID) -> GymEquipment? {
        equipment.first { $0.id == id }
    }

    /// Kan je deze oefening in deze gym doen?
    func supports(_ exercise: Exercise) -> Bool {
        if EquipmentType.type(withID: exercise.equipmentTypeID)?.isAlwaysAvailable == true { return true }
        return equipment.contains { $0.equipmentTypeID == exercise.equipmentTypeID }
    }
}
