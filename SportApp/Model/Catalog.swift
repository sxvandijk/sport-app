import Foundation

/// Soort oefening: met gewicht, lichaamsgewicht (gewicht = extra kg, vaak 0) of cardio (w = kilometer, r = minuten).
enum ExerciseKind: String, Codable, CaseIterable {
    case weights, bodyweight, cardio, timed

    var title: String {
        switch self {
        case .weights: return "Met gewicht"
        case .bodyweight: return "Lichaamsgewicht"
        case .cardio: return "Cardio"
        case .timed: return "Op tijd"
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
    /// Oefeningen waarbij je het gewicht van één arm of been invult (dumbbells, one-arm, bayesian).
    /// Eén arm of been tegelijk (one arm, single leg, bayesian, concentration): die doe je altijd links én rechts.
    static func isOneArm(_ name: String) -> Bool {
        let n = name.lowercased()
        return ["one arm", "one-arm", "single arm", "single-arm", "one leg", "single leg", "bayesian", "concentration"].contains { n.contains($0) }
    }

    static func isOneSided(_ name: String) -> Bool {
        if info(name).equipment == "Dumbbells" { return true }
        let n = name.lowercased()
        return ["one arm", "one-arm", "single arm", "single-arm", "one leg", "single leg", "bayesian", "concentration"].contains { n.contains($0) }
    }

    /// Telt het volume automatisch dubbel? Ja bij twee dumbbells en bij twee losse handgrepen tegelijk (kabel met "Losse handgreep").
    /// Eén handvat met twee handen, een machine of een stang telt één keer. Links en rechts apart (na elkaar) regelt de app zelf via de reps.
    static func autoTwoSides(_ name: String, acc: String?) -> Bool {
        if isOneArm(name) { return false }
        let e = info(name).equipment
        if e == "Kabel" { return acc == "Losse handgreep" }
        return e == "Dumbbells"
    }

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
        // Warming-up
        ("Rotator cuff external rotation", ExerciseInfo("Schouders", "Kabel", step: 0.5, d: 2.5)),
        ("Rotator cuff internal rotation", ExerciseInfo("Schouders", "Kabel", step: 0.5, d: 2.5)),
        ("Band pull-apart", ExerciseInfo("Schouders", "Band", step: 2.5, d: 0, kind: .bodyweight)),
        ("Shoulder dislocates (band)", ExerciseInfo("Schouders", "Band", step: 2.5, d: 0, kind: .bodyweight)),
        ("Arm circles", ExerciseInfo("Schouders", "Vrij", step: 1, d: 0, kind: .timed)),
        ("Fietsen", ExerciseInfo("Cardio", "Hometrainer", step: 1, d: 0, kind: .timed)),
        ("Roeimachine", ExerciseInfo("Cardio", "Roeier", step: 1, d: 0, kind: .timed)),
        ("Crosstrainer", ExerciseInfo("Cardio", "Crosstrainer", step: 1, d: 0, kind: .timed)),
        ("Touwtje springen", ExerciseInfo("Cardio", "Touw", step: 1, d: 0, kind: .timed)),
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
        ("Dumbbell Shoulder Press", ExerciseInfo("Schouders", "Dumbbells", step: 2.5, d: 17.5)),
        ("Dumbbell Bench Press", ExerciseInfo("Borst", "Dumbbells", step: 2.5, d: 22.5)),
        ("Butterfly", ExerciseInfo("Borst", "Machine", step: 5, d: 50)),
        ("Cable Deltoid Side Raise", ExerciseInfo("Schouders", "Kabel", step: 0.5, d: 5)),
        ("Overhead Tricep Cable Extension", ExerciseInfo("Triceps", "Kabel", step: 2.5, d: 15)),
        ("Dumbbell Shrug", ExerciseInfo("Traps", "Dumbbells", step: 2.5, d: 20)),
        ("Cable Iron Cross", ExerciseInfo("Borst", "Kabel", step: 2.5, d: 10)),
        ("Cable One Arm Tricep Extension", ExerciseInfo("Triceps", "Kabel", step: 2.5, d: 10)),
        ("Bayesian Bicep Cable Curl", ExerciseInfo("Biceps", "Kabel", step: 0.5, d: 10)),
        // Veelvoorkomende oefeningen (aangevuld)
        ("Incline barbell bench press", ExerciseInfo("Borst", "Stang", step: 2.5, d: 50)),
        ("Dumbbell fly", ExerciseInfo("Borst", "Dumbbells", step: 1, d: 10)),
        ("Incline dumbbell fly", ExerciseInfo("Borst", "Dumbbells", step: 1, d: 10)),
        ("Push-up", ExerciseInfo("Borst", "Vrij", step: 2.5, d: 0, kind: .bodyweight)),
        ("Chest dips", ExerciseInfo("Borst", "Dipstation", step: 2.5, d: 0, kind: .bodyweight)),
        ("Low cable crossover", ExerciseInfo("Borst", "Kabel", step: 2.5, d: 7.5)),
        ("Incline cable fly", ExerciseInfo("Borst", "Kabel", step: 2.5, d: 7.5)),
        ("Barbell overhead press", ExerciseInfo("Schouders", "Stang", step: 2.5, d: 40)),
        ("Seated barbell shoulder press", ExerciseInfo("Schouders", "Stang", step: 2.5, d: 40)),
        ("Arnold press", ExerciseInfo("Schouders", "Dumbbells", step: 2, d: 14)),
        ("Dumbbell front raise", ExerciseInfo("Schouders", "Dumbbells", step: 1, d: 8)),
        ("Cable front raise", ExerciseInfo("Schouders", "Kabel", step: 2.5, d: 7.5)),
        ("Reverse pec deck", ExerciseInfo("Schouders", "Machine", step: 5, d: 25)),
        ("Dumbbell rear delt fly", ExerciseInfo("Schouders", "Dumbbells", step: 1, d: 6)),
        ("Cable rear delt fly", ExerciseInfo("Schouders", "Kabel", step: 2.5, d: 5)),
        ("Upright row", ExerciseInfo("Schouders", "Stang", step: 2.5, d: 30)),
        ("Skullcrusher", ExerciseInfo("Triceps", "Stang", step: 2.5, d: 25)),
        ("Close-grip bench press", ExerciseInfo("Triceps", "Stang", step: 2.5, d: 50)),
        ("Dumbbell overhead triceps extension", ExerciseInfo("Triceps", "Dumbbells", step: 2, d: 16)),
        ("Triceps dips", ExerciseInfo("Triceps", "Dipstation", step: 2.5, d: 0, kind: .bodyweight)),
        ("Bench dips", ExerciseInfo("Triceps", "Vrij", step: 2.5, d: 0, kind: .bodyweight)),
        ("Dumbbell triceps kickback", ExerciseInfo("Triceps", "Dumbbells", step: 1, d: 6)),
        ("Chin-ups", ExerciseInfo("Lats", "Rekstok", step: 2.5, d: 0, kind: .bodyweight)),
        ("Close-grip lat pulldown", ExerciseInfo("Lats", "Machine", step: 5, d: 45)),
        ("One arm lat pulldown", ExerciseInfo("Lats", "Kabel", step: 2.5, d: 20)),
        ("Barbell row", ExerciseInfo("Bovenrug", "Stang", step: 2.5, d: 50)),
        ("One arm dumbbell row", ExerciseInfo("Bovenrug", "Dumbbells", step: 2, d: 24)),
        ("T-bar row", ExerciseInfo("Bovenrug", "Stang", step: 2.5, d: 30)),
        ("Inverted row", ExerciseInfo("Bovenrug", "Vrij", step: 2.5, d: 0, kind: .bodyweight)),
        ("Deadlift", ExerciseInfo("Onderrug", "Stang", step: 2.5, d: 80)),
        ("Sumo deadlift", ExerciseInfo("Billen", "Stang", step: 2.5, d: 80)),
        ("Rack pull", ExerciseInfo("Onderrug", "Stang", step: 2.5, d: 100)),
        ("Good morning", ExerciseInfo("Onderrug", "Stang", step: 2.5, d: 40)),
        ("Hyperextension", ExerciseInfo("Onderrug", "Vrij", step: 2.5, d: 0, kind: .bodyweight)),
        ("Barbell shrug", ExerciseInfo("Traps", "Stang", step: 2.5, d: 60)),
        ("Barbell curl", ExerciseInfo("Biceps", "Stang", step: 2.5, d: 30)),
        ("EZ-bar curl", ExerciseInfo("Biceps", "Stang", step: 2.5, d: 25)),
        ("Hammer curl", ExerciseInfo("Biceps", "Dumbbells", step: 1, d: 12)),
        ("Incline dumbbell curl", ExerciseInfo("Biceps", "Dumbbells", step: 1, d: 10)),
        ("Preacher curl", ExerciseInfo("Biceps", "Stang", step: 2.5, d: 20)),
        ("Concentration curl", ExerciseInfo("Biceps", "Dumbbells", step: 1, d: 10)),
        ("Cable hammer curl", ExerciseInfo("Biceps", "Kabel", step: 2.5, d: 15)),
        ("Reverse curl", ExerciseInfo("Onderarmen", "Stang", step: 2.5, d: 20)),
        ("Front squat", ExerciseInfo("Quadriceps", "Stang", step: 2.5, d: 50)),
        ("Goblet squat", ExerciseInfo("Quadriceps", "Kettlebell", step: 2, d: 20)),
        ("Bulgarian split squat", ExerciseInfo("Quadriceps", "Dumbbells", step: 2, d: 12)),
        ("Walking lunge", ExerciseInfo("Quadriceps", "Dumbbells", step: 2, d: 12)),
        ("Dumbbell lunge", ExerciseInfo("Quadriceps", "Dumbbells", step: 2, d: 12)),
        ("Dumbbell step-up", ExerciseInfo("Quadriceps", "Dumbbells", step: 2, d: 12)),
        ("Stiff-leg deadlift", ExerciseInfo("Hamstrings", "Stang", step: 2.5, d: 60)),
        ("Dumbbell Romanian deadlift", ExerciseInfo("Hamstrings", "Dumbbells", step: 2, d: 20)),
        ("Glute bridge", ExerciseInfo("Billen", "Vrij", step: 2.5, d: 0, kind: .bodyweight)),
        ("Cable pull-through", ExerciseInfo("Billen", "Kabel", step: 2.5, d: 20)),
        ("Cable glute kickback", ExerciseInfo("Billen", "Kabel", step: 2.5, d: 10)),
        ("Seated calf raise", ExerciseInfo("Kuiten", "Machine", step: 5, d: 40)),
        ("Smith machine calf raise", ExerciseInfo("Kuiten", "Smith machine", step: 2.5, d: 40)),
        ("Standing calf raise", ExerciseInfo("Kuiten", "Vrij", step: 2.5, d: 0, kind: .bodyweight)),
        ("Plank", ExerciseInfo("Core", "Vrij", step: 1, d: 0, kind: .timed)),
        ("Side plank", ExerciseInfo("Core", "Vrij", step: 1, d: 0, kind: .timed)),
        ("Crunch", ExerciseInfo("Core", "Vrij", step: 2.5, d: 0, kind: .bodyweight)),
        ("Sit-up", ExerciseInfo("Core", "Vrij", step: 2.5, d: 0, kind: .bodyweight)),
        ("Russian twist", ExerciseInfo("Core", "Vrij", step: 2.5, d: 0, kind: .bodyweight)),
        ("Lying leg raise", ExerciseInfo("Core", "Vrij", step: 2.5, d: 0, kind: .bodyweight)),
        ("Hanging knee raise", ExerciseInfo("Core", "Rekstok", step: 2.5, d: 0, kind: .bodyweight)),
        ("Ab wheel", ExerciseInfo("Core", "Vrij", step: 2.5, d: 0, kind: .bodyweight)),
        ("Cable woodchopper", ExerciseInfo("Core", "Kabel", step: 2.5, d: 10)),
        ("Pallof press", ExerciseInfo("Core", "Kabel", step: 2.5, d: 10)),
        ("Wandelen op de loopband", ExerciseInfo("Cardio", "Loopband", step: 0.1, d: 2, kind: .cardio)),
        ("Stairmaster", ExerciseInfo("Cardio", "Stairmaster", step: 1, d: 0, kind: .timed)),
        // Extra machines
        ("Incline chest press machine", ExerciseInfo("Borst", "Machine", step: 5, d: 40)),
        ("Biceps curl machine", ExerciseInfo("Biceps", "Machine", step: 5, d: 30)),
        ("Triceps extension machine", ExerciseInfo("Triceps", "Machine", step: 5, d: 30)),
        ("Lateral raise machine", ExerciseInfo("Schouders", "Machine", step: 5, d: 20)),
        ("Assisted pull-up machine", ExerciseInfo("Lats", "Machine", step: 5, d: 40)),
        ("Back extension machine", ExerciseInfo("Onderrug", "Machine", step: 5, d: 40)),
        ("Rotary torso machine", ExerciseInfo("Core", "Machine", step: 5, d: 30)),
        ("Glute kickback machine", ExerciseInfo("Billen", "Machine", step: 5, d: 30)),
        ("Prone leg curl", ExerciseInfo("Hamstrings", "Machine", step: 5, d: 35)),
        ("Pullover machine", ExerciseInfo("Lats", "Machine", step: 5, d: 30)),
        ("Hack squat machine", ExerciseInfo("Quadriceps", "Machine", step: 5, d: 60)),
        ("Smith machine squat", ExerciseInfo("Quadriceps", "Smith machine", step: 2.5, d: 40)),
        ("Smith machine bench press", ExerciseInfo("Borst", "Smith machine", step: 2.5, d: 40))
    ]

    /// Voorstellen voor het warming-upblok.
    static let warmupNames: [String] = ["Rotator cuff external rotation", "Rotator cuff internal rotation", "Band pull-apart",
                                        "Shoulder dislocates (band)", "Arm circles", "Fietsen", "Roeimachine", "Crosstrainer", "Touwtje springen"]

    /// Spiergroepen zoals ze in de catalogus voorkomen (voor het filter).
    static var muscleGroups: [String] {
        var out: [String] = []
        for item in all where !out.contains(item.info.muscle) { out.append(item.info.muscle) }
        for (_, info) in custom.sorted(by: { $0.key < $1.key }) where !out.contains(info.muscle) { out.append(info.muscle) }
        return out
    }

    /// Stappen van de apparaten in de gekozen gym, per oefening (door `AppModel` gevuld).
    static var gymScales: [String: WeightScale] = [:]
    /// Merk en type van het apparaat in de gekozen gym, per oefening (bv. "Matrix Ab crunch").
    static var gymLabels: [String: String] = [:]

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
        return i.muscle + " · " + (gymLabels[name] ?? i.equipment)
    }

    /// Eén stap omhoog (`dir` = 1) of omlaag (`dir` = -1) op het gewicht, volgens de stappen van het apparaat.
    /// Opzetstukken per oefening (afgeleid van de gym en je keuzes), zie `AppModel.applyGym`.
    static var exAccessories: [String: [GymAccessory]] = [:]
    /// Alle opzetstukken van de gym: die gelden standaard bij kabeloefeningen.
    static var defaultAccessories: [GymAccessory] = []
    static func accessories(for name: String) -> [GymAccessory] {
        if let list = exAccessories[name] { return list }
        return info(name).equipment == "Kabel" ? defaultAccessories : []
    }

    /// Oefeningen waarbij het niet vaststaat of je met één of twee armen/benen traint (kabels en dumbbells).
    static func sidesAmbiguous(_ name: String) -> Bool {
        guard kind(name) == .weights else { return false }
        let e = info(name).equipment
        return e == "Kabel" || e == "Dumbbells" || isOneSided(name)
    }

    static func step(_ name: String, weight: Double, dir: Int, fixed: Double? = nil) -> Double {
        if let f = fixed, f > 0 {
            let n = ((weight + Double(dir) * f) * 100).rounded() / 100
            return n < 0 ? 0 : n
        }
        if let scale = gymScales[name] {
            let n = scale.step(from: weight, up: dir > 0)
            return n < 0 ? 0 : n
        }
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
