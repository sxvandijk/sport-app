import Foundation

/// Een apparaat uit de ingebouwde lijst (merk + type) met standaardwaarden voor de gewichtsstappen.
/// De waarden zijn typische standaarden; ze kloppen niet voor elke sportschool en zijn per apparaat aan te passen.
struct MachineModel: Identifiable, Hashable {
    let brand: String
    let series: String
    let name: String
    /// "Machine", "Kabel" of "Dumbbells": bepaalt welke oefeningen je eraan kunt koppelen.
    let family: String
    let kind: WeightScale.Kind
    let exercises: [String]
    let min: Double
    let max: Double
    let step: Double
    let addOn: Double?

    var id: String { brand + "|" + name }
}

enum MachineDB {
    private struct Template {
        let name: String
        let family: String
        let kind: WeightScale.Kind
        let exercises: [String]
        let min: Double
        let max: Double
        let step: Double
    }

    private static let cableExercises = [
        "Cable fly", "Triceps pushdown", "Overhead triceps extension", "Face pull", "Cable curl", "Cable crunch",
        "Seated cable row", "Seated Cable Rows", "Rope Straight Arm Pulldown", "Overhead Tricep Cable Extension",
        "Cable Iron Cross", "Cable One Arm Tricep Extension", "Cable lateral raise"
    ]

    private static let dumbbellExercises = [
        "Incline dumbbell press", "Dumbbell bench press", "Dumbbell Bench Press", "Dumbbell shoulder press",
        "Dumbbell Shoulder Press", "Dumbbell curl", "Dumbbell Shrug"
    ]

    private static let t: [String: Template] = [
        "chest": Template(name: "Chest press", family: "Machine", kind: .stack, exercises: ["Chest press machine"], min: 5, max: 100, step: 5),
        "fly": Template(name: "Pec fly / Butterfly", family: "Machine", kind: .stack, exercises: ["Pec deck", "Butterfly"], min: 5, max: 100, step: 5),
        "rear": Template(name: "Rear delt fly", family: "Machine", kind: .stack, exercises: ["Single-Arm Machine Rear Delt Fly"], min: 5, max: 80, step: 5),
        "shoulder": Template(name: "Shoulder press", family: "Machine", kind: .stack, exercises: ["Shoulder press machine"], min: 5, max: 80, step: 5),
        "lat": Template(name: "Lat pulldown", family: "Machine", kind: .stack, exercises: ["Lat pulldown"], min: 5, max: 100, step: 5),
        "row": Template(name: "Seated row", family: "Machine", kind: .stack, exercises: ["Chest-supported row", "Seated cable row", "Seated Cable Rows"], min: 5, max: 100, step: 5),
        "legpress": Template(name: "Leg press", family: "Machine", kind: .stack, exercises: ["Leg press", "Leg Press"], min: 10, max: 200, step: 10),
        "ext": Template(name: "Leg extension", family: "Machine", kind: .stack, exercises: ["Leg extension", "Leg Extensions"], min: 5, max: 100, step: 5),
        "curl": Template(name: "Seated leg curl", family: "Machine", kind: .stack, exercises: ["Leg curl", "Seated Leg Curl"], min: 5, max: 100, step: 5),
        "calf": Template(name: "Calf raise", family: "Machine", kind: .stack, exercises: ["Calf raise machine", "Calf Press"], min: 10, max: 150, step: 10),
        "crunch": Template(name: "Ab crunch", family: "Machine", kind: .stack, exercises: ["Ab Crunch Machine"], min: 5, max: 80, step: 5),
        "abd": Template(name: "Abductor", family: "Machine", kind: .stack, exercises: ["Abductor"], min: 5, max: 100, step: 5),
        "add": Template(name: "Adductor", family: "Machine", kind: .stack, exercises: ["Adductor"], min: 5, max: 100, step: 5),
        "cable": Template(name: "Kabelstation", family: "Kabel", kind: .stack, exercises: cableExercises, min: 2.5, max: 90, step: 2.5),
        "dumb": Template(name: "Dumbbells (stap 2,5)", family: "Dumbbells", kind: .dumbbells, exercises: dumbbellExercises, min: 2.5, max: 50, step: 2.5),
        "incline": Template(name: "Incline chest press", family: "Machine", kind: .stack, exercises: ["Incline chest press machine"], min: 5, max: 100, step: 5),
        "biceps": Template(name: "Biceps curl", family: "Machine", kind: .stack, exercises: ["Biceps curl machine"], min: 5, max: 80, step: 5),
        "triceps": Template(name: "Triceps extension", family: "Machine", kind: .stack, exercises: ["Triceps extension machine"], min: 5, max: 80, step: 5),
        "lateral": Template(name: "Lateral raise", family: "Machine", kind: .stack, exercises: ["Lateral raise machine"], min: 5, max: 60, step: 5),
        "assist": Template(name: "Assisted pull-up / dip", family: "Machine", kind: .stack, exercises: ["Assisted pull-up machine"], min: 5, max: 100, step: 5),
        "backext": Template(name: "Back extension", family: "Machine", kind: .stack, exercises: ["Back extension machine"], min: 5, max: 100, step: 5),
        "torso": Template(name: "Rotary torso", family: "Machine", kind: .stack, exercises: ["Rotary torso machine"], min: 5, max: 80, step: 5),
        "glute": Template(name: "Glute kickback", family: "Machine", kind: .stack, exercises: ["Glute kickback machine"], min: 5, max: 80, step: 5),
        "prone": Template(name: "Prone leg curl", family: "Machine", kind: .stack, exercises: ["Prone leg curl"], min: 5, max: 100, step: 5),
        "pullover": Template(name: "Pullover", family: "Machine", kind: .stack, exercises: ["Pullover machine"], min: 5, max: 100, step: 5),
        "hack": Template(name: "Hack squat", family: "Machine", kind: .plateLoaded, exercises: ["Hack squat machine"], min: 0, max: 300, step: 10),
        "smith": Template(name: "Smith machine", family: "Smith machine", kind: .barbell, exercises: ["Smith machine squat", "Smith machine bench press"], min: 0, max: 200, step: 2.5),
        // Plate-loaded: de stap is een plaatje per kant.
        "p_chest": Template(name: "Chest press (plate-loaded)", family: "Machine", kind: .plateLoaded, exercises: ["Chest press machine"], min: 0, max: 200, step: 5),
        "p_shoulder": Template(name: "Shoulder press (plate-loaded)", family: "Machine", kind: .plateLoaded, exercises: ["Shoulder press machine"], min: 0, max: 150, step: 5),
        "p_lat": Template(name: "Lat pulldown (plate-loaded)", family: "Machine", kind: .plateLoaded, exercises: ["Lat pulldown"], min: 0, max: 150, step: 5),
        "p_row": Template(name: "Row (plate-loaded)", family: "Machine", kind: .plateLoaded, exercises: ["Chest-supported row"], min: 0, max: 150, step: 5),
        "p_legpress": Template(name: "Leg press (plate-loaded)", family: "Machine", kind: .plateLoaded, exercises: ["Leg press", "Leg Press"], min: 0, max: 400, step: 10),
        "p_calf": Template(name: "Calf raise (plate-loaded)", family: "Machine", kind: .plateLoaded, exercises: ["Calf raise machine", "Calf Press"], min: 0, max: 300, step: 10)
    ]

    private static let selectorized = ["chest", "incline", "fly", "rear", "shoulder", "lateral", "lat", "row", "pullover", "biceps", "triceps",
                                       "assist", "legpress", "ext", "curl", "prone", "calf", "abd", "add", "glute", "crunch", "torso", "backext", "cable", "smith"]

    private static let lines: [(brand: String, series: String, keys: [String])] = [
        ("Technogym", "Selection / Pure", selectorized),
        ("Matrix", "Ultra / Versa / Aura", selectorized),
        ("Basic-Fit", "Standaard (controleer in je club)", selectorized + ["dumb"]),
        ("Life Fitness", "Signature / Insignia", selectorized),
        ("Gym80", "Pure Kraft / Sygnum", selectorized),
        ("Hammer Strength", "Plate-loaded", ["p_chest", "p_shoulder", "p_lat", "p_row", "p_legpress", "p_calf", "hack"]),
        ("Algemeen", "Geen merk", ["cable", "dumb"])
    ]

    static let brands: [String] = lines.map { $0.brand }

    static let all: [MachineModel] = lines.flatMap { line in
        line.keys.compactMap { key -> MachineModel? in
            guard let x = t[key] else { return nil }
            return MachineModel(brand: line.brand, series: line.series, name: x.name, family: x.family, kind: x.kind,
                                exercises: x.exercises, min: x.min, max: x.max, step: x.step, addOn: nil)
        }
    }

    /// Oefeningen die aan een apparaat van deze soort te koppelen zijn.
    static func candidates(family: String) -> [String] {
        Catalog.all.filter { $0.info.equipment == family }.map { $0.name } +
            Catalog.custom.filter { $0.value.equipment == family }.map { $0.key }.sorted()
    }
}
