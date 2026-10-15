import Foundation

struct PersonalRecord: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let kind: ExerciseKind
    let weight: Double
    let reps: Int
    /// Geschat 1RM (Epley); 0 bij lichaamsgewicht zonder extra gewicht.
    let oneRM: Double
    let date: Date
}

/// Alle cijfers voor het Progressie-tabblad, berekend uit wat je echt gedaan hebt.
struct ProgressStats {
    var trainings = 0
    var volume = 0.0
    var newRecords = 0
    /// Volume per week in 1.000 kg, oudste eerst (8 weken, laatste = deze week).
    var weekVolumes: [Double] = []
    var weekLabels: [String] = []
    var muscleSets: [(muscle: String, sets: Int)] = []
    var records: [PersonalRecord] = []

    static func make(history: [HistoryEntry], now: Date, calendar: Calendar = .current) -> ProgressStats {
        var cal = calendar
        cal.firstWeekday = 2
        var out = ProgressStats()
        let today = cal.startOfDay(for: now)
        let monthAgo = cal.date(byAdding: .day, value: -28, to: today) ?? today
        let weekStart = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today

        var weekVol = Array(repeating: 0.0, count: 8)
        var muscles: [String: Int] = [:]
        var best: [String: PersonalRecord] = [:]

        for h in history.sorted(by: { $0.date < $1.date }) {
            let inMonth = h.date >= monthAgo
            if inMonth { out.trainings += 1 }
            let hWeekStart = cal.dateInterval(of: .weekOfYear, for: h.date)?.start ?? h.date
            let weeksAgo = cal.dateComponents([.day], from: hWeekStart, to: weekStart).day.map { $0 / 7 } ?? 99
            for e in h.exercises ?? [] {
                let kind = Catalog.kind(e.name)
                for s in e.sets where s.type != .warmup {
                    if kind == .cardio || kind == .timed { continue }
                    let vol = s.w * Double(s.totalReps)
                    if inMonth { out.volume += vol }
                    if weeksAgo >= 0 && weeksAgo < 8 { weekVol[7 - weeksAgo] += vol }
                    if h.date >= weekStart { muscles[Catalog.info(e.name).muscle, default: 0] += 1 }

                    let one = s.w > 0 ? s.w * (1 + Double(s.r) / 30) : 0
                    let cur = best[e.name]
                    let better: Bool
                    if let c = cur {
                        better = s.w > 0 || c.weight > 0 ? one > c.oneRM + 0.001 : s.r > c.reps
                    } else {
                        better = true
                    }
                    if better {
                        best[e.name] = PersonalRecord(name: e.name, kind: kind, weight: s.w, reps: s.r, oneRM: one, date: h.date)
                    }
                }
            }
        }
        out.weekVolumes = weekVol.map { $0 / 1000 }
        out.weekLabels = (0..<8).map { i in
            let d = cal.date(byAdding: .weekOfYear, value: -(7 - i), to: weekStart) ?? weekStart
            return "W\(cal.component(.weekOfYear, from: d))"
        }
        out.muscleSets = muscles.map { (muscle: $0.key, sets: $0.value) }
            .sorted { $0.sets != $1.sets ? $0.sets > $1.sets : $0.muscle < $1.muscle }
        out.records = best.values.sorted { $0.date != $1.date ? $0.date > $1.date : $0.name < $1.name }
        // Alleen een "nieuw" record als je er daarvoor al eerder trainingen met die oefening had.
        out.newRecords = out.records.filter { $0.date >= monthAgo && ProgressStats.hadEarlier($0, history: history) }.count
        return out
    }

    /// De afgeronde trainingen in een van de 8 weken (index 0 = oudste, 7 = deze week), nieuwste eerst.
    static func workouts(inWeek index: Int, history: [HistoryEntry], now: Date, calendar: Calendar = .current) -> [HistoryEntry] {
        var cal = calendar
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: now)
        let thisWeek = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        guard let start = cal.date(byAdding: .weekOfYear, value: -(7 - index), to: thisWeek),
              let end = cal.date(byAdding: .day, value: 7, to: start) else { return [] }
        return history.filter { $0.date >= start && $0.date < end }.sorted { $0.date > $1.date }
    }

    /// Volume van een training in kg (zonder warming-ups, cardio en tijdsoefeningen).
    static func volume(of entry: HistoryEntry) -> Double {
        var total = 0.0
        for e in entry.exercises ?? [] {
            let kind = Catalog.kind(e.name)
            if kind == .cardio || kind == .timed { continue }
            for s in e.sets where s.type != .warmup { total += s.w * Double(s.totalReps) }
        }
        return total
    }

    private static func hadEarlier(_ r: PersonalRecord, history: [HistoryEntry]) -> Bool {
        history.contains { h in
            h.date < r.date && (h.exercises ?? []).contains(where: { $0.name == r.name })
        }
    }
}
