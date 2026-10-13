import Foundation

/// Gegevens per oefening: spiergroep, soort apparaat, gewichtsstap en standaardgewicht.
struct ExerciseInfo {
    let muscle: String
    let equipment: String
    /// Vaste stap van de plus/min-knop. Bij een `list` (apparaat met onregelmatige stapel) telt de lijst.
    let step: Double
    let list: [Double]?
    let defaultWeight: Double

    init(_ muscle: String, _ equipment: String, step: Double = 2.5, list: [Double]? = nil, d: Double) {
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
        ("Cable crunch", ExerciseInfo("Core", "Kabel", step: 2.5, d: 30))
    ]

    static let names: [String] = all.map { $0.name }

    /// Onbekende oefening (bijvoorbeeld zelf toegevoegd): een neutrale standaard.
    static func info(_ name: String) -> ExerciseInfo {
        all.first(where: { $0.name == name })?.info ?? ExerciseInfo("Overig", "Vrij", step: 2.5, d: 20)
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
        let n = ((weight + Double(dir) * i.step) * 10).rounded() / 10
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
