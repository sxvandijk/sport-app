import Foundation

/// Soort set. Alleen een warming-up telt niet mee voor "sets te gaan" en volume.
enum SetType: String, Codable, CaseIterable, Hashable {
    case warmup = "w"
    case work = "s"
    case drop = "d"
    case failure = "f"

    var letter: String {
        switch self {
        case .warmup: return "W"
        case .work: return "1"
        case .drop: return "D"
        case .failure: return "F"
        }
    }

    var name: String {
        switch self {
        case .warmup: return "Warming-up"
        case .work: return "Werkset"
        case .drop: return "Dropset"
        case .failure: return "Tot falen"
        }
    }

    var detail: String {
        switch self {
        case .warmup: return "Lichtere opwarmset, telt mee"
        case .work: return "Normale set, telt mee"
        case .drop: return "Direct na de vorige set, lichter, zonder rust"
        case .failure: return "Werkset tot je geen rep meer kunt"
        }
    }
}

struct LiveSet: Identifiable, Codable, Hashable {
    var id = UUID()
    var type: SetType
    var w: Double
    var r: Int
    /// Vorige keer (voor "Vorige keer 26 kg × 8"). `nil` = nog geen vorige keer.
    var pw: Double?
    var pr: Int?
    var done = false
    /// Bovengrens van het herhalingsbereik (alleen om te laten zien).
    var rmax: Int? = nil
    var rmin: Int? = nil
    /// Rechterarm/-been als je los traint (dan is `r` de linkerkant). `nil` = beide kanten samen.
    var r2: Int? = nil

    var totalReps: Int { r + (r2 ?? 0) }
    /// Reps voor het volume: links + rechts, of bij gewicht per arm/been het aantal keer twee.
    func volumeReps(twoSides: Bool) -> Int { r2 != nil ? r + (r2 ?? 0) : (twoSides ? 2 * r : r) }
    /// Volume van deze set: links + rechts los (elke kant verplaatst het gewicht), of gewicht \u{00D7} reps (dubbel bij twee handgrepen tegelijk).
    func volume(twoSides: Bool) -> Double { w * Double(volumeReps(twoSides: twoSides)) }
    var repsText: String { r2 == nil ? String(r) : "\(r)/\(r2 ?? 0)" }
}

/// Hoe je het gewicht en de reps van een oefening invult.
enum SideMode { case single, perSide, separate }

struct LiveExercise: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var group: Int
    /// Naam van de oefening die hiermee is vervangen ("Machine bezet").
    var from: String?
    var sets: [LiveSet]
    /// Na een wissel: het aantal rondes dat de vorige oefening al had gedaan, zodat de rondes in een superset kloppen.
    var roundOffset: Int? = nil
    /// Armen/benen los invullen (links en rechts apart).
    var uni: Bool? = nil
    /// Gewicht per arm of been (twee losse armen met hetzelfde aantal): het volume telt dubbel.
    var two: Bool? = nil
    /// Gekozen opzetstuk (touw, rechte stang...) en de eigen stap daarvan.
    var acc: String? = nil
    var accStep: Double? = nil
    /// 1 = warming-upblok, 2 = cooling-downblok (die tellen mee voor sets en volume).
    var blk: Int? = nil

    var workSets: [LiveSet] { sets.filter { $0.type != .warmup } }

    /// Telt het volume dubbel? Dat gaat automatisch: twee dumbbells of twee losse handgrepen tegelijk, niet bij links en rechts apart (dan telt elke kant zelf).
    var doubles: Bool { uni != true && Catalog.autoTwoSides(name, acc: acc) }

    var sideMode: SideMode { uni == true ? .separate : (doubles ? .perSide : .single) }
}

struct QueueItem: Hashable {
    var exID: UUID
    var setID: UUID
    var block: Int
    var round: Int
}

struct SessionSummary: Equatable {
    var title: String
    var note: String
    var time: String
    var sets: String
    var volume: String
    var lines: [SummaryLine]
}

struct SummaryLine: Equatable, Identifiable {
    var id = UUID()
    var name: String
    var summary: String
}

struct RemovedSet {
    var exID: UUID
    var index: Int
    var set: LiveSet
}

struct CompletionResult {
    var nextFocus: UUID?
    /// Rusttijd in seconden, of `nil` als er geen rust hoort (binnen een superset-ronde, voor een dropset, aan het einde).
    var restSeconds: Int?
}

/// Een lopende workout en alle regels eromheen (DESIGN.md hoofdstuk 7). Geen UI, zodat het testbaar is.
struct LiveSession: Codable, Hashable {
    var name: String
    var startAt: Date
    var exercises: [LiveExercise]
    var nextGroup: Int
    /// Laatste keer dat je een set afvinkte (voor de 'vergeten workout'-melding).
    var lastActivity: Date? = nil
    /// Lopende cardiotimer: welke set en sinds wanneer.
    var cardioSet: UUID? = nil
    var cardioAt: Date? = nil

    mutating func setReps(set id: UUID, to r: Int) {
        for e in exercises.indices {
            if let s = exercises[e].sets.firstIndex(where: { $0.id == id }) { exercises[e].sets[s].r = r; return }
        }
    }

    // MARK: Opbouwen

    /// Laatste keer dat je deze oefening echt deed (nieuwste training eerst).
    static func lastLogged(_ name: String, in history: [HistoryEntry]) -> LoggedExercise? {
        let sorted = history.sorted { $0.date > $1.date }
        for h in sorted {
            if let e = h.exercises?.first(where: { $0.name == name && $0.sets.contains(where: { $0.type != .warmup }) }) {
                return e
            }
        }
        return nil
    }

    /// Laatste keer dat je deze oefening met dit opzetstuk deed.
    static func lastLogged(_ name: String, acc: String, in history: [HistoryEntry]) -> LoggedExercise? {
        for h in history.sorted(by: { $0.date > $1.date }) {
            if let e = h.exercises?.first(where: { $0.name == name && $0.acc == acc && $0.sets.contains(where: { $0.type != .warmup }) }) { return e }
        }
        return nil
    }

    /// Laatste keer dat deze oefening als warming-upblok is gedaan.
    static func lastLoggedWarmup(_ name: String, in history: [HistoryEntry]) -> LoggedExercise? {
        for h in history.sorted(by: { $0.date > $1.date }) {
            if let e = h.exercises?.first(where: { $0.name == name && $0.sets.contains(where: { $0.type == .warmup }) }) { return e }
        }
        return nil
    }

    static func makeExercise(name: String, group: Int, plan: PlanItem?, last: LoggedExercise? = nil) -> LiveExercise {
        var sets: [LiveSet] = []
        let isWarmupBlock = plan?.isWarmup == true || plan?.isCooldown == true
        let blk: Int? = plan?.isWarmup == true ? 1 : (plan?.isCooldown == true ? 2 : nil)
        let lastWork = (last?.sets ?? []).filter { isWarmupBlock ? $0.type == .warmup : $0.type != .warmup }
        let kind = Catalog.kind(name)
        let workType: SetType = isWarmupBlock ? .warmup : .work
        if !isWarmupBlock, let warm = plan?.warm {
            let n = max(1, plan?.warmCount ?? 1)
            for k in 0..<n {
                // Bij meerdere warming-upsets loopt het gewicht op naar je werkgewicht.
                let w = n == 1 ? warm.w : ((warm.w * 2 * Double(k + 1) / Double(n + 1)) * 2).rounded() / 2
                sets.append(LiveSet(type: .warmup, w: w, r: warm.r, pw: nil, pr: nil))
            }
        }
        let planned = plan?.sets ?? []
        let count: Int
        if !planned.isEmpty { count = planned.count } else if !lastWork.isEmpty { count = lastWork.count } else { count = kind == .cardio ? 1 : 3 }
        for i in 0..<count {
            let base: PlanSet? = planned.isEmpty ? nil : planned[i]
            let prev: LoggedSet? = lastWork.isEmpty ? nil : lastWork[min(i, lastWork.count - 1)]
            let w = prev?.w ?? base?.w ?? Catalog.info(name).defaultWeight
            let r = prev?.r ?? base?.r ?? (kind == .cardio ? 10 : 10)
            sets.append(LiveSet(type: workType, w: w, r: r, pw: prev?.w, pr: prev?.r, rmax: base?.rmax, rmin: base?.r))
        }
        var ex = LiveExercise(name: name, group: group, from: nil, sets: sets)
        ex.blk = blk
        if !isWarmupBlock {
            let accs = Catalog.accessories(for: name)
            if let a = accs.first(where: { $0.name == last?.acc }) ?? accs.first {
                ex.acc = a.name
                ex.accStep = a.step > 0 ? a.step : nil
            }
        }
        if !isWarmupBlock, kind == .weights {
        }
        // One-arm oefeningen staan standaard op links en rechts apart: je doet nooit alleen één kant.
        if (last?.uni == true || (Catalog.isOneArm(name) && kind == .weights)) && !isWarmupBlock {
            ex.uni = true
            for i in ex.sets.indices where ex.sets[i].type != .warmup { ex.sets[i].r2 = ex.sets[i].r2 ?? ex.sets[i].r }
        }
        return ex
    }

    static func make(name: String, startAt: Date, templates: [String: [PlanItem]], history: [HistoryEntry] = []) -> LiveSession {
        let plans = templates[name] ?? []
        var list: [LiveExercise] = []
        for item in plans {
            let last = (item.isWarmup == true || item.isCooldown == true) ? lastLoggedWarmup(item.name, in: history) : lastLogged(item.name, in: history)
            list.append(makeExercise(name: item.name, group: item.group, plan: item, last: last))
        }
        return LiveSession(name: name.isEmpty ? "Vrije training" : name, startAt: startAt, exercises: list, nextGroup: 100)
    }

    // MARK: Opvragen

    func exercise(_ id: UUID?) -> LiveExercise? {
        guard let id = id else { return nil }
        return exercises.first(where: { $0.id == id })
    }

    func index(of id: UUID) -> Int? {
        exercises.firstIndex(where: { $0.id == id })
    }

    func findSet(_ id: UUID) -> LiveSet? {
        for e in exercises {
            if let s = e.sets.first(where: { $0.id == id }) { return s }
        }
        return nil
    }

    /// Opeenvolgende oefeningen met hetzelfde groepsnummer.
    var blocks: [[LiveExercise]] {
        var out: [[LiveExercise]] = []
        var i = 0
        while i < exercises.count {
            let g = exercises[i].group
            var members: [LiveExercise] = []
            while i < exercises.count && exercises[i].group == g {
                members.append(exercises[i])
                i += 1
            }
            out.append(members)
        }
        return out
    }

    /// De wachtrij: sets in de volgorde waarin je ze doet. Een superset gaat per ronde langs alle oefeningen.
    func queue(warmFirst: Bool) -> [QueueItem] {
        var q: [QueueItem] = []
        let all = blocks
        for (bi, members) in all.enumerated() {
            let merge = warmFirst && members.count > 1
            var slotsPer: [[[LiveSet]]] = []
            for e in members {
                let warm = e.sets.filter { $0.type == .warmup }
                let work = e.sets.filter { $0.type != .warmup }
                var slots: [[LiveSet]] = Array(repeating: [], count: e.roundOffset ?? 0)
                if merge && !work.isEmpty {
                    slots.append(warm + [work[0]])
                    for s in work.dropFirst() { slots.append([s]) }
                } else {
                    for s in warm + work { slots.append([s]) }
                }
                slotsPer.append(slots)
            }
            var maxRounds = 0
            for s in slotsPer where s.count > maxRounds { maxRounds = s.count }
            if maxRounds == 0 { continue }
            for k in 0..<maxRounds {
                for (mi, e) in members.enumerated() {
                    if k < slotsPer[mi].count {
                        for s in slotsPer[mi][k] {
                            q.append(QueueItem(exID: e.id, setID: s.id, block: bi, round: k))
                        }
                    }
                }
            }
        }
        return q
    }

    func isDone(_ item: QueueItem) -> Bool {
        findSet(item.setID)?.done ?? true
    }

    /// De set waar je nu mee bezig bent (of de set van de aangetikte oefening).
    func current(focus: UUID?, focusSet: UUID? = nil, warmFirst: Bool) -> (queue: [QueueItem], cur: QueueItem?) {
        let q = queue(warmFirst: warmFirst)
        let undone = q.filter { !isDone($0) }
        var cur: QueueItem?
        if let fs = focusSet {
            cur = q.first(where: { $0.setID == fs })
        }
        if cur == nil, let focus = focus {
            cur = undone.first(where: { $0.exID == focus })
        }
        if cur == nil { cur = undone.first }
        return (q, cur)
    }

    var workSetCounts: (total: Int, done: Int, warmLeft: Int) {
        var total = 0
        var done = 0
        var warmLeft = 0
        for e in exercises {
            for s in e.sets {
                if s.type == .warmup {
                    if !s.done { warmLeft += 1 }
                } else {
                    total += 1
                    if s.done { done += 1 }
                }
            }
        }
        return (total, done, warmLeft)
    }

    var openWorkSets: Int {
        let c = workSetCounts
        return c.total - c.done
    }

    /// Geschatte resterende minuten: 2,25 min per open werkset en 1 min per open warming-up (minimaal 1).
    var estimatedMinutesLeft: Int {
        let c = workSetCounts
        let left = c.total - c.done
        if left == 0 && c.warmLeft == 0 { return 0 }
        let value = (Double(left) * 2.25 + Double(c.warmLeft)).rounded()
        return max(1, Int(value))
    }

    var progressFraction: Double {
        let c = workSetCounts
        return c.total == 0 ? 0 : Double(c.done) / Double(c.total)
    }

    // MARK: Acties

    mutating func stepWeight(set setID: UUID, exID: UUID, dir: Int) {
        guard let e = index(of: exID), let s = exercises[e].sets.firstIndex(where: { $0.id == setID }) else { return }
        exercises[e].sets[s].w = Catalog.step(exercises[e].name, weight: exercises[e].sets[s].w, dir: dir, fixed: exercises[e].accStep)
    }

    mutating func setValues(set setID: UUID, exID: UUID, w: Double?, r: Int?, r2: Int? = nil) {
        guard let e = index(of: exID), let s = exercises[e].sets.firstIndex(where: { $0.id == setID }) else { return }
        if let w = w { exercises[e].sets[s].w = max(0, (w * 100).rounded() / 100) }
        if let r = r { exercises[e].sets[s].r = max(0, r) }
        if let r2 = r2 { exercises[e].sets[s].r2 = max(0, r2) }
    }

    /// Zet het vinkje van een set weer terug (ongedaan maken van `uncomplete`).
    mutating func redoComplete(set setID: UUID, exID: UUID) {
        guard let e = index(of: exID), let s = exercises[e].sets.firstIndex(where: { $0.id == setID }) else { return }
        exercises[e].sets[s].done = true
    }

    /// Haalt het vinkje van een gedane set weg.
    mutating func uncomplete(set setID: UUID, exID: UUID) {
        guard let e = index(of: exID), let s = exercises[e].sets.firstIndex(where: { $0.id == setID }) else { return }
        exercises[e].sets[s].done = false
    }

    mutating func stepReps(set setID: UUID, exID: UUID, dir: Int, second: Bool = false, both: Bool = false) {
        guard let e = index(of: exID), let s = exercises[e].sets.firstIndex(where: { $0.id == setID }) else { return }
        if both, exercises[e].sets[s].r2 != nil {
            exercises[e].sets[s].r = max(1, exercises[e].sets[s].r + dir)
            exercises[e].sets[s].r2 = max(1, (exercises[e].sets[s].r2 ?? exercises[e].sets[s].r) + dir)
            return
        }
        if second {
            exercises[e].sets[s].r2 = max(1, (exercises[e].sets[s].r2 ?? exercises[e].sets[s].r) + dir)
            return
        }
        exercises[e].sets[s].r = max(1, exercises[e].sets[s].r + dir)
    }

    /// Rondt de huidige set af en zegt wat er daarna gebeurt.
    mutating func complete(focus: UUID?, focusSet: UUID? = nil, warmFirst: Bool, restDefault: Int) -> CompletionResult? {
        let info = current(focus: focus, focusSet: focusSet, warmFirst: warmFirst)
        guard let c = info.cur,
              let e = index(of: c.exID),
              let s = exercises[e].sets.firstIndex(where: { $0.id == c.setID }) else { return nil }
        if exercises[e].sets[s].done { return nil }
        let explicit = focusSet != nil && focusSet == c.setID
        let completedType = exercises[e].sets[s].type
        exercises[e].sets[s].done = true

        let q = info.queue
        var next: QueueItem?
        if explicit {
            // Je koos zelf een set: daarna ga je terug naar waar je gebleven was.
            next = q.first(where: { !isDone($0) })
        } else if let pos = q.firstIndex(of: c) {
            var i = pos + 1
            while i < q.count {
                if !isDone(q[i]) { next = q[i]; break }
                i += 1
            }
        }
        if next == nil { next = q.first(where: { !isDone($0) }) }

        var result = CompletionResult(nextFocus: next?.exID, restSeconds: nil)
        if let n = next {
            let sameRound = n.block == c.block && n.round == c.round
            let dropNext = n.exID == c.exID && (findSet(n.setID)?.type == .drop)
            if !sameRound && !dropNext {
                result.restSeconds = completedType == .warmup ? 45 : restDefault
            }
        }
        return result
    }

    /// Links en rechts apart invullen aan of uit. Aan: de rechterkant start gelijk aan links.
    /// Wisselt van opzetstuk. Sets die nog open staan krijgen het gewicht dat je er de vorige keer mee deed.
    mutating func setAccessory(_ exID: UUID, to acc: GymAccessory, history: [HistoryEntry]) {
        guard let e = exercises.firstIndex(where: { $0.id == exID }) else { return }
        exercises[e].acc = acc.name
        exercises[e].accStep = acc.step > 0 ? acc.step : nil
        let lastWork = (LiveSession.lastLogged(exercises[e].name, acc: acc.name, in: history)?.sets ?? []).filter { $0.type != .warmup }
        guard !lastWork.isEmpty else { return }
        var i = 0
        for s in exercises[e].sets.indices where exercises[e].sets[s].type != .warmup {
            if !exercises[e].sets[s].done {
                let prev = lastWork[min(i, lastWork.count - 1)]
                exercises[e].sets[s].w = prev.w
                exercises[e].sets[s].pw = prev.w
                exercises[e].sets[s].pr = prev.r
            }
            i += 1
        }
    }

    mutating func toggleUnilateral(_ exID: UUID) {
        guard let e = index(of: exID) else { return }
        let on = exercises[e].uni != true
        exercises[e].uni = on ? true : nil
        for i in exercises[e].sets.indices where exercises[e].sets[i].type != .warmup {
            exercises[e].sets[i].r2 = on ? (exercises[e].sets[i].r2 ?? exercises[e].sets[i].r) : nil
        }
    }

    mutating func addSet(to exID: UUID) {
        guard let e = index(of: exID) else { return }
        let last = exercises[e].sets.last
        let w = last?.w ?? Catalog.info(exercises[e].name).defaultWeight
        let r = last?.r ?? 10
        let r2 = exercises[e].uni == true ? (last?.r2 ?? r) : nil
        let onlyWarmups = !exercises[e].sets.isEmpty && exercises[e].sets.allSatisfy { $0.type == .warmup }
        exercises[e].sets.append(LiveSet(type: onlyWarmups ? .warmup : .work, w: w, r: r, r2: onlyWarmups ? nil : r2))
    }

    /// Nieuwe warming-up: ongeveer de helft van je eerste werkset, 12 herhalingen, na de laatste bestaande warming-up.
    mutating func addWarmup(to exID: UUID) {
        guard let e = index(of: exID) else { return }
        let first = exercises[e].sets.first(where: { $0.type != .warmup })
        let base = first?.w ?? Catalog.info(exercises[e].name).defaultWeight
        let half = max(0, (base * 0.5).rounded())
        let w = Catalog.step(exercises[e].name, weight: half + 0.001, dir: -1)
        var lastWarm = -1
        for (i, s) in exercises[e].sets.enumerated() where s.type == .warmup { lastWarm = i }
        exercises[e].sets.insert(LiveSet(type: .warmup, w: w, r: 12), at: lastWarm + 1)
    }

    /// Warming-ups staan altijd vooraan, de rest houdt zijn volgorde.
    mutating func setType(exID: UUID, setID: UUID, to type: SetType) {
        guard let e = index(of: exID), let s = exercises[e].sets.firstIndex(where: { $0.id == setID }) else { return }
        exercises[e].sets[s].type = type
        let warm = exercises[e].sets.filter { $0.type == .warmup }
        let rest = exercises[e].sets.filter { $0.type != .warmup }
        exercises[e].sets = warm + rest
    }

    mutating func deleteSet(exID: UUID, setID: UUID) -> RemovedSet? {
        guard let e = index(of: exID), let s = exercises[e].sets.firstIndex(where: { $0.id == setID }) else { return nil }
        let removed = exercises[e].sets.remove(at: s)
        return RemovedSet(exID: exID, index: s, set: removed)
    }

    mutating func restore(_ removed: RemovedSet) {
        guard let e = index(of: removed.exID) else { return }
        let at = min(removed.index, exercises[e].sets.count)
        exercises[e].sets.insert(removed.set, at: at)
    }

    mutating func addExercise(_ name: String, history: [HistoryEntry] = []) {
        nextGroup += 1
        exercises.append(LiveSession.makeExercise(name: name, group: nextGroup, plan: nil,
                                                  last: LiveSession.lastLogged(name, in: history)))
    }

    /// Voegt een cooling-down-oefening toe aan het eind van de training (blauw blok, telt mee voor sets en volume).
    mutating func addCooldown(_ name: String, history: [HistoryEntry] = []) {
        nextGroup += 1
        let kind = Catalog.kind(name)
        let strength = kind == .weights || kind == .bodyweight
        let set = PlanSet(w: Catalog.info(name).defaultWeight, r: strength ? 15 : 5)
        var plan = PlanItem(name: name, group: nextGroup, sets: Array(repeating: set, count: strength ? 2 : 1))
        plan.isCooldown = true
        exercises.append(LiveSession.makeExercise(name: name, group: nextGroup, plan: plan,
                                                  last: LiveSession.lastLoggedWarmup(name, in: history)))
    }

    /// Alle keren dat je een oefening deed, nieuwste eerst (voor de geschiedenis in de workout).
    static func performances(of name: String, in history: [HistoryEntry], limit: Int = 8) -> [(date: Date, workout: String, exercise: LoggedExercise)] {
        var out: [(date: Date, workout: String, exercise: LoggedExercise)] = []
        for h in history.sorted(by: { $0.date > $1.date }) {
            guard let e = h.exercises?.first(where: { $0.name == name && !$0.sets.isEmpty }) else { continue }
            out.append((date: h.date, workout: h.name, exercise: e))
            if out.count >= limit { break }
        }
        return out
    }

    /// "Machine bezet": de open sets gaan naar de nieuwe oefening, gedane sets blijven staan.
    /// Wisselt een oefening. Gedane sets blijven bij de oude oefening; de open sets gaan naar de nieuwe.
    /// Geeft het id van de oefening terug waar je nu mee verder gaat.
    @discardableResult
    mutating func swap(exID: UUID, to name: String, history: [HistoryEntry] = []) -> UUID? {
        guard let e = index(of: exID) else { return nil }
        let old = exercises[e]
        let d = Catalog.info(name).defaultWeight
        let lastWork = (LiveSession.lastLogged(name, in: history)?.sets ?? []).filter { $0.type != .warmup }
        func refresh(_ sets: [LiveSet]) -> [LiveSet] {
            var out = sets
            for i in out.indices where !out[i].done {
                let prev: LoggedSet? = lastWork.isEmpty ? nil : lastWork[min(i, lastWork.count - 1)]
                out[i].w = prev?.w ?? d
                out[i].pw = prev?.w
                out[i].pr = prev?.r
                out[i].rmax = nil
            }
            return out
        }
        let doneSets = old.sets.filter { $0.done }
        let openSets = old.sets.filter { !$0.done }
        if openSets.isEmpty { return exID }
        let original = old.from ?? old.name
        if doneSets.isEmpty {
            exercises[e].from = (name == original) ? nil : original
            exercises[e].name = name
            exercises[e].sets = refresh(old.sets)
            return exID
        }
        exercises[e].sets = doneSets
        let doneWork = doneSets.filter { $0.type != .warmup }.count
        let replacement = LiveExercise(name: name, group: old.group, from: (name == original) ? nil : original,
                                       sets: refresh(openSets), roundOffset: (old.roundOffset ?? 0) + doneWork)
        exercises.insert(replacement, at: e + 1)
        return replacement.id
    }

    /// Slaat een oefening over voor vandaag: open sets verdwijnen, gedane sets blijven bewaard.
    mutating func skipExercise(_ exID: UUID) {
        guard let e = index(of: exID) else { return }
        let done = exercises[e].sets.filter { $0.done }
        if done.isEmpty {
            exercises.remove(at: e)
        } else {
            exercises[e].sets = done
        }
    }

    /// Koppelt bestaande oefeningen (`existing`) en nieuwe (`newNames`) aan de basisoefening tot één superset.
    mutating func link(base exID: UUID, existing: [UUID], newNames: [String], history: [HistoryEntry] = []) {
        guard let baseIndex = index(of: exID) else { return }
        if existing.isEmpty && newNames.isEmpty { return }
        let g = exercises[baseIndex].group
        var moving = exercises.filter { existing.contains($0.id) }
        exercises.removeAll { existing.contains($0.id) }
        for i in moving.indices { moving[i].group = g }
        for n in newNames { moving.append(LiveSession.makeExercise(name: n, group: g, plan: nil, last: LiveSession.lastLogged(n, in: history))) }
        var lastIdx = -1
        for (i, e) in exercises.enumerated() where e.group == g { lastIdx = i }
        exercises.insert(contentsOf: moving, at: lastIdx + 1)
    }

    mutating func unlink(exID: UUID) {
        guard let i = index(of: exID) else { return }
        var e = exercises.remove(at: i)
        let g = e.group
        var lastIdx = -1
        for (k, x) in exercises.enumerated() where x.group == g { lastIdx = k }
        nextGroup += 1
        e.group = nextGroup
        exercises.insert(e, at: lastIdx + 1)
    }

    func summary(of e: LiveExercise) -> String {
        LiveSession.summary(of: e.sets, kind: Catalog.kind(e.name))
    }

    // MARK: Samenvattingen

    /// "3 × 26 kg · 8, 8, 7 reps", "2 van 3 gedaan · 55 kg × 9" of "3 sets · 55 kg × 10".
    static func summary(of sets: [LiveSet], kind: ExerciseKind = .weights) -> String {
        let nonWarm = sets.filter { $0.type != .warmup }
        let work = nonWarm.isEmpty ? sets : nonWarm
        let done = work.filter { $0.done }
        if work.isEmpty { return "Geen sets" }
        if kind == .timed {
            return done.isEmpty ? Format.setText(kind, 0, work.first?.r ?? 0) : "Klaar"
        }
        if kind == .cardio {
            let km = done.reduce(0) { $0 + $1.w }
            let min = done.reduce(0) { $0 + $1.r }
            if done.isEmpty { return "\(Format.setText(kind, work[0].w, work[0].r))" }
            return "\(Format.km(km)) km · \(min) min"
        }
        if done.count == work.count {
            let weights = done.map { $0.w }
            let mn = weights.min() ?? 0
            let mx = weights.max() ?? 0
            let reps = done.map { $0.repsText }.joined(separator: ", ")
            if kind == .bodyweight && mx == 0 { return "\(done.count) × \(reps) reps" }
            let pre = kind == .bodyweight ? "+" : ""
            let wt = mn == mx ? pre + Format.weight(mn) + " kg" : pre + Format.weight(mn) + "–" + Format.weight(mx) + " kg"
            return "\(done.count) × \(wt) · \(reps) reps"
        }
        let next = work.first(where: { !$0.done }) ?? work[0]
        if !done.isEmpty {
            return "\(done.count) van \(work.count) gedaan · \(Format.setText(kind, next.w, next.r))"
        }
        return "\(work.count) sets · \(Format.setText(kind, next.w, next.r))"
    }

    func finishSummary(now: Date, note: String?) -> (summary: SessionSummary, workSets: Int) {
        var workDone = 0
        var volume = 0.0
        for e in exercises {
            for s in e.sets where s.done {
                workDone += 1
                if Catalog.kind(e.name) != .cardio { volume += s.volume(twoSides: e.doubles) }
            }
        }
        var lines: [SummaryLine] = []
        for e in exercises where e.sets.contains(where: { $0.done }) {
            lines.append(SummaryLine(name: e.name, summary: LiveSession.summary(of: e.sets.filter { $0.done }, kind: Catalog.kind(e.name))))
        }
        let seconds = Int(now.timeIntervalSince(startAt))
        let summary = SessionSummary(title: name + " afgerond",
                                     note: note ?? "Goed gedaan. Alles is opgeslagen.",
                                     time: Format.clock(seconds: seconds),
                                     sets: String(workDone),
                                     volume: Format.thousands(volume),
                                     lines: lines)
        return (summary, workDone)
    }
}

/// Opmaak van getallen en tijden zoals in het prototype.
enum Format {
    /// "55 kg × 9", "9 reps", "+10 kg × 9" of "2,37 km · 3 min"
    static func setText(_ kind: ExerciseKind, _ w: Double, _ r: Int) -> String {
        switch kind {
        case .weights: return weight(w) + " kg × " + String(r)
        case .bodyweight: return w == 0 ? String(r) + " reps" : "+" + weight(w) + " kg × " + String(r)
        case .cardio: return km(w) + " km · " + String(r) + " min"
        case .timed: return String(r) + " min"
        }
    }

    /// "8–12" of "12"
    static func reps(_ r: Int, _ rmax: Int?) -> String {
        if let m = rmax, m > r { return "\(r)–\(m)" }
        return String(r)
    }

    /// Kilometers met maximaal twee decimalen: 2.37 → "2,37", 2.5 → "2,5"
    static func km(_ v: Double) -> String {
        let r = (v * 100).rounded() / 100
        if r == r.rounded() { return String(Int(r)) }
        var t = String(format: "%.2f", r)
        if t.hasSuffix("0") { t.removeLast() }
        return t.replacingOccurrences(of: ".", with: ",")
    }

    /// 7.5 → "7,5", 55 → "55"
    static func weight(_ w: Double) -> String {
        let rounded = (w * 10).rounded() / 10
        if rounded == rounded.rounded() { return String(Int(rounded)) }
        return String(rounded).replacingOccurrences(of: ".", with: ",")
    }

    /// 1394 s → "23:14", 3725 s → "1:02:05"
    static func clock(seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%d:%02d", m, sec)
    }

    /// 48230 → "48.230"
    static func thousands(_ value: Double) -> String {
        let n = Int(value.rounded())
        let digits = String(abs(n))
        var out = ""
        for (i, ch) in digits.reversed().enumerated() {
            if i > 0 && i % 3 == 0 { out.append(".") }
            out.append(ch)
        }
        return (n < 0 ? "-" : "") + String(out.reversed())
    }

    static func hhmm(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }
}
