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
        case .warmup: return "Telt niet mee voor je sets en volume"
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
}

struct LiveExercise: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var group: Int
    /// Naam van de oefening die hiermee is vervangen ("Machine bezet").
    var from: String?
    var sets: [LiveSet]

    var workSets: [LiveSet] { sets.filter { $0.type != .warmup } }
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

    // MARK: Opbouwen

    static func makeExercise(name: String, group: Int, plan: PlanItem?) -> LiveExercise {
        var sets: [LiveSet] = []
        if let plan = plan {
            if let warm = plan.warm {
                sets.append(LiveSet(type: .warmup, w: warm.w, r: warm.r, pw: warm.w, pr: warm.r))
            }
            for s in plan.sets {
                sets.append(LiveSet(type: .work, w: s.w, r: s.r, pw: s.w, pr: s.r))
            }
        } else {
            let d = Catalog.info(name).defaultWeight
            for _ in 0..<3 {
                sets.append(LiveSet(type: .work, w: d, r: 10, pw: nil, pr: nil))
            }
        }
        return LiveExercise(name: name, group: group, from: nil, sets: sets)
    }

    static func make(name: String, startAt: Date, templates: [String: [PlanItem]]) -> LiveSession {
        let plans = templates[name] ?? []
        var list: [LiveExercise] = []
        for item in plans {
            list.append(makeExercise(name: item.name, group: item.group, plan: item))
        }
        return LiveSession(name: name.isEmpty ? "Lege training" : name, startAt: startAt, exercises: list, nextGroup: 100)
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
                var slots: [[LiveSet]] = []
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
    func current(focus: UUID?, warmFirst: Bool) -> (queue: [QueueItem], cur: QueueItem?) {
        let q = queue(warmFirst: warmFirst)
        let undone = q.filter { !isDone($0) }
        var cur: QueueItem?
        if let focus = focus {
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
        exercises[e].sets[s].w = Catalog.step(exercises[e].name, weight: exercises[e].sets[s].w, dir: dir)
    }

    mutating func stepReps(set setID: UUID, exID: UUID, dir: Int) {
        guard let e = index(of: exID), let s = exercises[e].sets.firstIndex(where: { $0.id == setID }) else { return }
        exercises[e].sets[s].r = max(1, exercises[e].sets[s].r + dir)
    }

    /// Rondt de huidige set af en zegt wat er daarna gebeurt.
    mutating func complete(focus: UUID?, warmFirst: Bool, restDefault: Int) -> CompletionResult? {
        let info = current(focus: focus, warmFirst: warmFirst)
        guard let c = info.cur,
              let e = index(of: c.exID),
              let s = exercises[e].sets.firstIndex(where: { $0.id == c.setID }) else { return nil }
        let completedType = exercises[e].sets[s].type
        exercises[e].sets[s].done = true

        let q = info.queue
        var next: QueueItem?
        if let pos = q.firstIndex(of: c) {
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

    mutating func addSet(to exID: UUID) {
        guard let e = index(of: exID) else { return }
        let last = exercises[e].sets.last
        let w = last?.w ?? Catalog.info(exercises[e].name).defaultWeight
        let r = last?.r ?? 10
        exercises[e].sets.append(LiveSet(type: .work, w: w, r: r))
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

    mutating func addExercise(_ name: String) {
        nextGroup += 1
        exercises.append(LiveSession.makeExercise(name: name, group: nextGroup, plan: nil))
    }

    /// "Machine bezet": de open sets gaan naar de nieuwe oefening, gedane sets blijven staan.
    mutating func swap(exID: UUID, to name: String) {
        guard let e = index(of: exID) else { return }
        let old = exercises[e].name
        if exercises[e].from == nil { exercises[e].from = old }
        exercises[e].name = name
        let d = Catalog.info(name).defaultWeight
        for i in exercises[e].sets.indices where !exercises[e].sets[i].done {
            exercises[e].sets[i].w = d
            exercises[e].sets[i].pw = nil
            exercises[e].sets[i].pr = nil
        }
    }

    /// Koppelt bestaande oefeningen (`existing`) en nieuwe (`newNames`) aan de basisoefening tot één superset.
    mutating func link(base exID: UUID, existing: [UUID], newNames: [String]) {
        guard let baseIndex = index(of: exID) else { return }
        if existing.isEmpty && newNames.isEmpty { return }
        let g = exercises[baseIndex].group
        var moving = exercises.filter { existing.contains($0.id) }
        exercises.removeAll { existing.contains($0.id) }
        for i in moving.indices { moving[i].group = g }
        for n in newNames { moving.append(LiveSession.makeExercise(name: n, group: g, plan: nil)) }
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
        LiveSession.summary(of: e.sets)
    }

    // MARK: Samenvattingen

    /// "3 × 26 kg · 8, 8, 7 reps", "2 van 3 gedaan · 55 kg × 9" of "3 sets · 55 kg × 10".
    static func summary(of sets: [LiveSet]) -> String {
        let work = sets.filter { $0.type != .warmup }
        let done = work.filter { $0.done }
        if work.isEmpty { return "Geen sets" }
        if done.count == work.count {
            let weights = done.map { $0.w }
            let mn = weights.min() ?? 0
            let mx = weights.max() ?? 0
            let wt = mn == mx ? Format.weight(mn) + " kg" : Format.weight(mn) + "–" + Format.weight(mx) + " kg"
            let reps = done.map { String($0.r) }.joined(separator: ", ")
            return "\(done.count) × \(wt) · \(reps) reps"
        }
        let next = work.first(where: { !$0.done }) ?? work[0]
        if !done.isEmpty {
            return "\(done.count) van \(work.count) gedaan · \(Format.weight(next.w)) kg × \(next.r)"
        }
        return "\(work.count) sets · \(Format.weight(next.w)) kg × \(next.r)"
    }

    func finishSummary(now: Date, note: String?) -> (summary: SessionSummary, workSets: Int) {
        var workDone = 0
        var volume = 0.0
        for e in exercises {
            for s in e.sets where s.type != .warmup && s.done {
                workDone += 1
                volume += s.w * Double(s.r)
            }
        }
        var lines: [SummaryLine] = []
        for e in exercises where e.sets.contains(where: { $0.done && $0.type != .warmup }) {
            lines.append(SummaryLine(name: e.name, summary: LiveSession.summary(of: e.sets.filter { $0.done })))
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
