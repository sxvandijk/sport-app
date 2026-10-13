import Foundation

/// De zes kleuren die je als accent kunt kiezen (DESIGN.md 2.1).
enum AccentID: String, Codable, CaseIterable, Hashable, Identifiable {
    case olive, viola, lime, mint, ice, pink

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .olive: return "Olijf"
        case .viola: return "Viola"
        case .lime: return "Limoen"
        case .mint: return "Mint"
        case .ice: return "IJsblauw"
        case .pink: return "Roze"
        }
    }

    var hex: UInt32 {
        switch self {
        case .olive: return 0x556B2F
        case .viola: return 0x5A2D82
        case .lime: return 0xC6F25A
        case .mint: return 0x5EE6B0
        case .ice: return 0x7CC4FF
        case .pink: return 0xFF9AC8
        }
    }
}

/// Profiel › Weergave › Modus.
enum AppearanceMode: String, Codable, CaseIterable, Hashable, Identifiable {
    case system, dark, light

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "Systeem"
        case .dark: return "Donker"
        case .light: return "Licht"
        }
    }
}

struct CreatineReminder: Codable, Hashable {
    var isOn: Bool
    var hour: Int
    var minute: Int

    init(isOn: Bool = false, hour: Int = 9, minute: Int = 0) {
        self.isOn = isOn
        self.hour = hour
        self.minute = minute
    }
}

struct UserSettings: Codable, Hashable {
    var accentID: AccentID
    var appearance: AppearanceMode
    var defaultRestSeconds: Int
    /// Warming-up in superset: de warming-upsets van een oefening en haar eerste werkset vormen samen ronde 0.
    var warmupFirstInSuperset: Bool
    var creatineReminder: CreatineReminder
    var currentGymID: UUID?
    var currentProgramID: UUID?

    init(accentID: AccentID = .olive,
         appearance: AppearanceMode = .system,
         defaultRestSeconds: Int = 90,
         warmupFirstInSuperset: Bool = true,
         creatineReminder: CreatineReminder = CreatineReminder(),
         currentGymID: UUID? = nil,
         currentProgramID: UUID? = nil) {
        self.accentID = accentID
        self.appearance = appearance
        self.defaultRestSeconds = defaultRestSeconds
        self.warmupFirstInSuperset = warmupFirstInSuperset
        self.creatineReminder = creatineReminder
        self.currentGymID = currentGymID
        self.currentProgramID = currentProgramID
    }

    /// Stappen van de rusttimer in Profiel: per 15 seconden, van 0:30 tot 5:00.
    static let restRange: ClosedRange<Int> = 30...300
    static let restStep = 15
}
