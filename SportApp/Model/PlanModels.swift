import Foundation

struct PlanSet: Codable, Hashable {
    var w: Double
    var r: Int
    /// Bovengrens van het herhalingsbereik (bijvoorbeeld 12 bij "8–12"). `nil` = vast aantal.
    var rmax: Int? = nil
}

/// Eén oefening in een trainingsschema. Oefeningen met hetzelfde `group`-nummer achter elkaar vormen een superset.
struct PlanItem: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var group: Int
    var warm: PlanSet?
    var sets: [PlanSet]
    /// Hoort bij het warming-upblok vooraan in de training (bijv. rotator cuff of fietsen).
    var isWarmup: Bool?

    init(name: String, group: Int, warm: PlanSet? = nil, sets: [PlanSet], isWarmup: Bool? = nil) {
        self.name = name
        self.group = group
        self.warm = warm
        self.sets = sets
        self.isWarmup = isWarmup
    }
}

struct PlanProgram: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var workouts: [String]
}

struct GymMachine: Codable, Hashable {
    var name: String
    var steps: String
    var on: Bool
}

struct GymSetup: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var equipment: [GymMachine]

    var summary: String {
        equipment.isEmpty ? "Nog geen apparaten" : "\(equipment.filter { $0.on }.count) van \(equipment.count) apparaten"
    }
}

struct LoggedSet: Codable, Hashable {
    var w: Double
    var r: Int
    var type: SetType
}

struct LoggedExercise: Codable, Hashable {
    var name: String
    var sets: [LoggedSet]
}

struct HistoryEntry: Codable, Hashable, Identifiable {
    var id = UUID()
    var date: Date
    var name: String
    var minutes: Int
    /// Wat je echt gedaan hebt (alleen afgeronde sets). Oudere gegevens hebben dit niet.
    var exercises: [LoggedExercise]? = nil
}

/// Zelf toegevoegde oefening.
struct CustomExercise: Codable, Hashable {
    var name: String
    var muscle: String
    var equipment: String
    var kind: ExerciseKind
}

/// Beginstand: jouw vier schema's, geen nepgegevens.
enum SeedData {
    static func p(_ w: Double, _ r: Int, _ rmax: Int? = nil) -> PlanSet { PlanSet(w: w, r: r, rmax: rmax) }

    private static func rep(_ n: Int, _ w: Double, _ r: Int, _ rmax: Int? = nil) -> [PlanSet] {
        Array(repeating: p(w, r, rmax), count: n)
    }

    private static let treadmill = "Hardlopen op de loopband"

    static var templates: [String: [PlanItem]] {
        [
            "Push": [
                PlanItem(name: "Dumbbell Bench Press", group: 1, sets: rep(3, 22.5, 8, 12)),
                PlanItem(name: "Butterfly", group: 2, sets: rep(3, 70, 8, 12)),
                PlanItem(name: "Cable Deltoid Side Raise", group: 3, sets: rep(3, 7.5, 12, 15)),
                PlanItem(name: "Overhead Tricep Cable Extension", group: 4, sets: rep(3, 17.5, 8, 12)),
                PlanItem(name: "Dumbbell Shoulder Press", group: 5, sets: rep(3, 17.5, 12)),
                PlanItem(name: "Dumbbell Shrug", group: 5, sets: rep(3, 25, 30)),
                PlanItem(name: "Cable Iron Cross", group: 6, sets: rep(3, 10, 15)),
                PlanItem(name: "Cable One Arm Tricep Extension", group: 7, sets: rep(3, 10, 8, 12)),
                PlanItem(name: "Hanging Leg Raise", group: 8, sets: rep(3, 0, 15))
            ],
            "Pull": [
                PlanItem(name: "Pullups", group: 1, sets: rep(3, 10, 9, 12)),
                PlanItem(name: "Seated Cable Rows", group: 2, sets: rep(3, 48, 8, 12)),
                PlanItem(name: "Rope Straight Arm Pulldown", group: 2, sets: rep(3, 27.5, 8, 12)),
                PlanItem(name: "Single-Arm Machine Rear Delt Fly", group: 3, sets: rep(3, 10, 12)),
                PlanItem(name: "One Arm Dumbbell Preacher Curl", group: 4, sets: rep(4, 15, 8, 12)),
                PlanItem(name: "Palms-Down Dumbbell Wrist Curl", group: 5, sets: rep(3, 38.5, 15)),
                PlanItem(name: "Seated Palms-Down Barbell Wrist Curl", group: 5, sets: rep(3, 24.5, 15)),
                PlanItem(name: treadmill, group: 6, sets: [p(2.37, 3)])
            ],
            "Legs": [
                PlanItem(name: "Leg Press", group: 1, sets: rep(3, 80, 12)),
                PlanItem(name: "Calf Press", group: 2, sets: rep(3, 100, 15)),
                PlanItem(name: "Leg Extensions", group: 3, sets: rep(3, 50, 12)),
                PlanItem(name: "Seated Leg Curl", group: 4, sets: rep(3, 65, 12)),
                PlanItem(name: "Ab Crunch Machine", group: 5, sets: rep(3, 86, 15)),
                PlanItem(name: "Abductor", group: 6, sets: rep(3, 60, 20)),
                PlanItem(name: "Adductor", group: 7, sets: rep(3, 60, 20)),
                PlanItem(name: "Hanging Leg Raise", group: 8, sets: rep(3, 0, 15)),
                PlanItem(name: treadmill, group: 9, sets: [p(2.37, 3)])
            ],
            "Upper": [
                PlanItem(name: "Muscle Up", group: 1, sets: rep(2, 0, 1)),
                PlanItem(name: "Seated Cable Rows", group: 2, sets: rep(3, 48, 8, 12)),
                PlanItem(name: "Rope Straight Arm Pulldown", group: 2, sets: rep(3, 27.5, 8, 12)),
                PlanItem(name: "Butterfly", group: 3, sets: rep(3, 70, 8, 12)),
                PlanItem(name: "Cable Iron Cross", group: 4, sets: rep(4, 10, 12)),
                PlanItem(name: "Cable Deltoid Side Raise", group: 5, sets: rep(3, 7.5, 12, 15)),
                PlanItem(name: "Bayesian Bicep Cable Curl", group: 6, sets: rep(4, 13.5, 12)),
                PlanItem(name: "Cable One Arm Tricep Extension", group: 6, sets: rep(4, 10, 7, 10)),
                PlanItem(name: "Palms-Down Dumbbell Wrist Curl", group: 7, sets: rep(3, 38.5, 15)),
                PlanItem(name: "Seated Palms-Down Barbell Wrist Curl", group: 7, sets: rep(3, 24.5, 12, 15)),
                PlanItem(name: "Hanging Leg Raise", group: 8, sets: rep(3, 0, 15))
            ]
        ]
    }

    static let programs: [PlanProgram] = [
        PlanProgram(id: "p1", name: "Push Pull Legs Upper", workouts: ["Push", "Pull", "Legs", "Upper"])
    ]

    static var gyms: [GymSetup] {
        [GymSetup(id: "g1", name: "Mijn gym", equipment: [])]
    }
}
