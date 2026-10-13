import Foundation

/// Soort oefening: met gewicht, lichaamsgewicht (gewicht = extra kg, vaak 0) of cardio (w = kilometer, r = minuten).
enum ExerciseKind: String, Codable, CaseIterable {
    case weights, bodyweight, cardio

    var title: String {
        switch self {
        case .weights: return "Met gewicht"
        case .bodyweight: return "Lichaamsgewicht"
        case .cardio: return "Cardio"
        }
    }
}

/// Gegevens per oefening: spiergroep, soort apparaat, gewichtsstap en standaardgewicht.
struct ExerciseInfo {
    let muscle: String
    let equipment: String
    /// Vaste stap van de plus/min-knop. Bij een `list` (apparaat met onregelmatige stapel) telt de lijst.
    let step: Double
    let list: [Double]?
    let defaultWeight: Double
    let kind: ExerciseKind

    init(_ muscle: String, _ equipment: String, step: Double = 2.5, list: [Double]? = nil, d: Double,
         kind: ExerciseKind = .weights) {
        self.kind = kind
        self.muscle = muscle
        self.equipment = equipment
        self.step = step
        self.list = list
        self.defaultWeight = d
    }
}

/// De oefeningenbibliotheek (Engelse namen, zoals in de sportschool). De volgorde is de volgorde in zoekresultaten.
enum Catalog {
    static let all: [(name: String, info: ExerciseInfo)] = [
        ("Incline dumbbell press", ExerciseInfo("Borst", "Dumbbells", step: 2, d: 20)),
        ("Dumbbell bench press", ExerciseInfo("Borst", "Dumbbells", step: 2, d: 24)),
        ("Barbell bench press", ExerciseInfo("Borst", "Stang", step: 2.5, d: 60)),
        ("Chest press machine", ExerciseInfo("Borst", "Machine", list: [25, 35, 45, 55, 65, 75, 85], d: 45)),
        ("Pec deck", ExerciseInfo("Borst", "Machine", step: 5, d: 40)),
        ("Cable fly", ExerciseInfo("Borst", "Kabel", step: 2.5, d: 12.5)),
        ("Dumbbell shoulder press", ExerciseInfo("Schouders", "Dumbbells", step: 2, d: 16)),
        ("Shoulder press machine", ExerciseInfo("Schouders", "Machine", step: 5, d: 30)),
        ("Cable lateral raise", ExerciseInfo("Schouders", "Kabel", step: 2.5, d: 5)),
        ("Dumbbell lateral raise", ExerciseInfo("Schouders", "Dumbbells", step: 1, d: 8)),
        ("Triceps pushdown", ExerciseInfo("Triceps", "Kabel", step: 2.5, d: 20)),
        ("Overhead triceps extension", ExerciseInfo("Triceps", "Kabel", step: 2.5, d: 15)),
        ("Lat pulldown", ExerciseInfo("Lats", "Machine", step: 5, d: 45)),
        ("Seated cable row", ExerciseInfo("Bovenrug", "Kabel", step: 5, d: 45)),
        ("Chest-supported row", ExerciseInfo("Bovenrug", "Machine", step: 5, d: 40)),
        ("Face pull", ExerciseInfo("Bovenrug", "Kabel", step: 2.5, d: 15)),
        ("Dumbbell curl", ExerciseInfo("Biceps", "Dumbbells", step: 2, d: 10)),
        ("Cable curl", ExerciseInfo("Biceps", "Kabel", step: 2.5, d: 15)),
        ("Leg press", ExerciseInfo("Quadriceps", "Machine", step: 10, d: 100)),
        ("Leg extension", ExerciseInfo("Quadriceps", "Machine", step: 5, d: 40)),
        ("Barbell squat", ExerciseInfo("Quadriceps", "Stang", step: 2.5, d: 60)),
        ("Leg curl", ExerciseInfo("Hamstrings", "Machine", step: 5, d: 35)),
        ("Romanian deadlift", ExerciseInfo("Hamstrings", "Stang", step: 2.5, d: 60)),
        ("Hip thrust", ExerciseInfo("Billen", "Stang", step: 5, d: 60)),
        ("Calf raise machine", ExerciseInfo("Kuiten", "Machine", step: 5, d: 50)),
        ("Cable crunch", ExerciseInfo("Core", "Kabel", step: 2.5, d: 30)),
        // Jouw schema's
        ("Pullups", ExerciseInfo("Lats", "Rekstok", step: 2.5, d: 0, kind: .bodyweight)),
        ("Muscle Up", ExerciseInfo("Lats", "Rekstok", step: 2.5, d: 0, kind: .bodyweight)),
        ("Hanging Leg Raise", ExerciseInfo("Core", "Rekstok", step: 2.5, d: 0, kind: .bodyweight)),
        ("Seated Cable Rows", ExerciseInfo("Bovenrug", "Kabel", step: 2.5, d: 45)),
        ("Rope Straight Arm Pulldown", ExerciseInfo("Lats", "Kabel", step: 2.5, d: 25)),
        ("Single-Arm Machine Rear Delt Fly", ExerciseInfo("Schouders", "Machine", step: 2.5, d: 10)),
        ("One Arm Dumbbell Preacher Curl", ExerciseInfo("Biceps", "Dumbbells", step: 0.5, d: 12)),
        ("Palms-Down Dumbbell Wrist Curl", ExerciseInfo("Onderarmen", "Dumbbells", step: 0.5, d: 20)),
        ("Seated Palms-Down Barbell Wrist Curl", ExerciseInfo("Onderarmen", "Stang", step: 0.5, d: 20)),
        ("Hardlopen op de loopband", ExerciseInfo("Cardio", "Loopband", step: 0.1, d: 2, kind: .cardio)),
        ("Leg Press", ExerciseInfo("Quadriceps", "Machine", step: 5, d: 80)),
        ("Calf Press", ExerciseInfo("Kuiten", "Machine", step: 5, d: 80)),
        ("Leg Extensions", ExerciseInfo("Quadriceps", "Machine", step: 5, d: 40)),
        ("Seated Leg Curl", ExerciseInfo("Hamstrings", "Machine", step: 5, d: 40)),
        ("Ab Crunch Machine", ExerciseInfo("Core", "Machine", step: 5, d: 40)),
        ("Abductor", ExerciseInfo("Billen", "Machine", step: 5, d: 40)),
        ("Adductor", ExerciseInfo("Billen", "Machine", step: 5, d: 40)),
        ("Dumbbell Bench Press", ExerciseInfo("Borst", "Dumbbells", step: 2.5, d: 22.5)),
        ("Butterfly", ExerciseInfo("Borst", "Machine", step: 5, d: 50)),
        ("Cable Deltoid Side Raise", ExerciseInfo("Schouders", "Kabel", step: 0.5, d: 5)),
        ("Overhead Tricep Cable Extension", ExerciseInfo("Triceps", "Kabel", step: 2.5, d: 15)),
        ("Dumbbell Shrug", ExerciseInfo("Traps", "Dumbbells", step: 2.5, d: 20)),
        ("Cable Iron Cross", ExerciseInfo("Borst", "Kabel", step: 2.5, d: 10)),
        ("Cable One Arm Tricep Extension", ExerciseInfo("Triceps", "Kabel", step: 2.5, d: 10)),
        ("Bayesian Bicep Cable Curl", ExerciseInfo("Biceps", "Kabel", step: 0.5, d: 10))
    ]

    /// Zelf toegevoegde oefeningen (door `AppModel` gevuld).
    static var custom: [String: ExerciseInfo] = [:]

    static func setCustom(_ list: [CustomExercise]) {
        var d: [String: ExerciseInfo] = [:]
        for c in list {
            d[c.name] = ExerciseInfo(c.muscle, c.equipment, step: c.kind == .cardio ? 0.1 : 2.5, d: c.kind == .weights ? 20 : (c.kind == .cardio ? 2 : 0), kind: c.kind)
        }
        custom = d
    }

    static var allNames: [String] { names + custom.keys.sorted() }

    static func kind(_ name: String) -> ExerciseKind { info(name).kind }

    static let names: [String] = all.map { $0.name }

    /// Onbekende oefening (bijvoorbeeld zelf toegevoegd): een neutrale standaard.
    static func info(_ name: String) -> ExerciseInfo {
        if let c = custom[name] { return c }
        return all.first(where: { $0.name == name })?.info ?? ExerciseInfo("Overig", "Vrij", step: 2.5, d: 20)
    }

    static func meta(_ name: String) -> String {
        let i = info(name)
        return i.muscle + " · " + i.equipment
    }

    /// Eén stap omhoog (`dir` = 1) of omlaag (`dir` = -1) op het gewicht, volgens de stappen van het apparaat.
    static func step(_ name: String, weight: Double, dir: Int) -> Double {
        let i = info(name)
        if let list = i.list {
            if dir > 0 {
                return list.first(where: { $0 > weight + 0.001 }) ?? (list.last ?? weight)
            }
            return list.last(where: { $0 < weight - 0.001 }) ?? (list.first ?? weight)
        }
        let n = ((weight + Double(dir) * i.step) * 100).rounded() / 100
        return n < 0 ? 0 : n
    }

    /// De app-suggestie bij "Machine bezet": zelfde spiergroep, liefst ander soort apparaat.
    static func suggestion(for name: String, excluding: [String]) -> String {
        let l = info(name)
        var best: String?
        for item in all {
            if item.name == name || excluding.contains(item.name) || item.info.muscle != l.muscle { continue }
            if item.info.equipment != l.equipment { return item.name }
            if best == nil { best = item.name }
        }
        return best ?? all[0].name
    }
}
