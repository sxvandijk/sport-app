import Foundation

struct PlanSet: Codable, Hashable {
    var w: Double
    var r: Int
}

/// Eén oefening in een trainingsschema. Oefeningen met hetzelfde `group`-nummer achter elkaar vormen een superset.
struct PlanItem: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var group: Int
    var warm: PlanSet?
    var sets: [PlanSet]

    init(name: String, group: Int, warm: PlanSet? = nil, sets: [PlanSet]) {
        self.name = name
        self.group = group
        self.warm = warm
        self.sets = sets
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
        "\(equipment.filter { $0.on }.count) van \(equipment.count) apparaten"
    }
}

struct HistoryEntry: Codable, Hashable, Identifiable {
    var id = UUID()
    var date: Date
    var name: String
    var minutes: Int
}

/// Voorbeeldgegevens waarmee de app voor het eerst start (zelfde als in het prototype).
enum SeedData {
    static func p(_ w: Double, _ r: Int) -> PlanSet { PlanSet(w: w, r: r) }

    static var templates: [String: [PlanItem]] {
        [
            "Push A": [
                PlanItem(name: "Incline dumbbell press", group: 1, warm: p(12, 12), sets: [p(26, 8), p(26, 8), p(26, 7)]),
                PlanItem(name: "Chest press machine", group: 2, warm: p(35, 12), sets: [p(55, 10), p(55, 9), p(55, 9)]),
                PlanItem(name: "Cable lateral raise", group: 2, sets: [p(7.5, 12), p(7.5, 12), p(7.5, 11)]),
                PlanItem(name: "Dumbbell shoulder press", group: 3, sets: [p(20, 10), p(20, 9), p(18, 10)]),
                PlanItem(name: "Triceps pushdown", group: 4, sets: [p(25, 12), p(25, 12), p(25, 10)])
            ],
            "Pull A": [
                PlanItem(name: "Lat pulldown", group: 1, warm: p(35, 12), sets: [p(55, 10), p(55, 10), p(55, 8)]),
                PlanItem(name: "Seated cable row", group: 2, sets: [p(50, 10), p(50, 10), p(50, 9)]),
                PlanItem(name: "Dumbbell curl", group: 3, sets: [p(12, 10), p(12, 10), p(12, 9)]),
                PlanItem(name: "Face pull", group: 3, sets: [p(20, 15), p(20, 15), p(20, 14)])
            ],
            "Full body A": [
                PlanItem(name: "Barbell squat", group: 1, warm: p(40, 10), sets: [p(60, 8), p(60, 8), p(60, 8)]),
                PlanItem(name: "Barbell bench press", group: 2, warm: p(30, 10), sets: [p(50, 8), p(50, 8), p(50, 7)]),
                PlanItem(name: "Seated cable row", group: 3, sets: [p(45, 10), p(45, 10), p(45, 10)]),
                PlanItem(name: "Cable crunch", group: 4, sets: [p(30, 12), p(30, 12), p(30, 12)])
            ],
            "Full body B": [
                PlanItem(name: "Romanian deadlift", group: 1, warm: p(40, 10), sets: [p(60, 10), p(60, 10), p(60, 9)]),
                PlanItem(name: "Dumbbell shoulder press", group: 2, sets: [p(18, 10), p(18, 10), p(18, 9)]),
                PlanItem(name: "Lat pulldown", group: 3, sets: [p(50, 10), p(50, 10), p(50, 9)]),
                PlanItem(name: "Leg curl", group: 3, sets: [p(35, 12), p(35, 12), p(35, 11)])
            ],
            "Benen": [
                PlanItem(name: "Leg press", group: 1, warm: p(60, 12), sets: [p(120, 10), p(120, 10), p(120, 9)]),
                PlanItem(name: "Leg extension", group: 2, sets: [p(45, 12), p(45, 12), p(45, 11)]),
                PlanItem(name: "Leg curl", group: 2, sets: [p(40, 12), p(40, 12), p(40, 10)]),
                PlanItem(name: "Calf raise machine", group: 3, sets: [p(60, 15), p(60, 15), p(60, 14)])
            ]
        ]
    }

    static let programs: [PlanProgram] = [
        PlanProgram(id: "p1", name: "Push Pull Legs", workouts: ["Push A", "Pull A", "Benen"]),
        PlanProgram(id: "p2", name: "Full body 2×", workouts: ["Full body A", "Full body B"])
    ]

    private static func equipment(off: [String]) -> [GymMachine] {
        let all: [(String, String)] = [
            ("Barbell + plates", "20 kg stang · schijven 1,25–20 kg"),
            ("Dumbbells", "2–40 kg · stappen van 2 kg"),
            ("Cable station", "2,5–50 kg · stappen van 2,5 kg"),
            ("Chest press machine", "25–85 kg · stappen van 10 kg"),
            ("Pec deck", "10–80 kg · stappen van 5 kg"),
            ("Shoulder press machine", "10–70 kg · stappen van 5 kg"),
            ("Lat pulldown", "10–100 kg · stappen van 5 kg"),
            ("Seated row machine", "10–100 kg · stappen van 5 kg"),
            ("Leg press", "40–300 kg · stappen van 10 kg"),
            ("Leg extension", "5–100 kg · stappen van 5 kg"),
            ("Leg curl", "5–100 kg · stappen van 5 kg"),
            ("Calf raise machine", "10–150 kg · stappen van 5 kg")
        ]
        return all.map { GymMachine(name: $0.0, steps: $0.1, on: !off.contains($0.0)) }
    }

    static var gyms: [GymSetup] {
        [
            GymSetup(id: "g1", name: "Mijn gym", equipment: equipment(off: ["Shoulder press machine"])),
            GymSetup(id: "g2", name: "Gym bij werk",
                     equipment: equipment(off: ["Chest press machine", "Pec deck", "Leg extension", "Calf raise machine"]))
        ]
    }

    /// Eerdere trainingen: dagen geleden → (schema, minuten).
    static let historyDaysAgo: [(Int, String, Int)] = [
        (4, "Push A", 54), (6, "Benen", 47), (8, "Pull A", 51), (11, "Push A", 56), (13, "Benen", 45),
        (15, "Pull A", 49), (18, "Push A", 52), (20, "Benen", 48), (22, "Pull A", 50), (25, "Push A", 55),
        (27, "Benen", 44), (29, "Pull A", 53), (32, "Push A", 51)
    ]

    static func history(now: Date, calendar: Calendar = .current) -> [HistoryEntry] {
        let start = calendar.startOfDay(for: now)
        return historyDaysAgo.map { days, name, minutes in
            let day = calendar.date(byAdding: .day, value: -days, to: start) ?? start
            let date = calendar.date(byAdding: .hour, value: 18, to: day) ?? day
            return HistoryEntry(date: date, name: name, minutes: minutes)
        }
    }
}
