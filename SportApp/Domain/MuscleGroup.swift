import Foundation

/// Spiergroepen voor volume-verdeling, oefening-metadata en alternatieven.
enum MuscleGroup: String, Codable, CaseIterable, Hashable, Identifiable {
    case chest, upperBack, lats, shoulders, biceps, triceps, forearms
    case quads, hamstrings, glutes, calves, core

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Borst"
        case .upperBack: return "Bovenrug"
        case .lats: return "Lats"
        case .shoulders: return "Schouders"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .forearms: return "Onderarmen"
        case .quads: return "Quadriceps"
        case .hamstrings: return "Hamstrings"
        case .glutes: return "Billen"
        case .calves: return "Kuiten"
        case .core: return "Core"
        }
    }
}

/// Grove bewegingsfamilie. Gebruikt om bij "machine bezet" een écht vergelijkbare oefening te kiezen.
enum MovementPattern: String, Codable, CaseIterable, Hashable {
    case horizontalPush, verticalPush, horizontalPull, verticalPull
    case squat, hinge, isolation, core, other
}
