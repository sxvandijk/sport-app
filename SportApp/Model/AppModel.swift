import Foundation
import SwiftUI
import UserNotifications

enum Screen: String, Codable { case home, workout, overview, editor, summary }
enum HomeTab: Int, CaseIterable, Identifiable {
    case training, progress, gym, profile
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .training: return "Training"
        case .progress: return "Progressie"
        case .gym: return "Gym"
        case .profile: return "Profiel"
        }
    }
}

enum SheetKind: String {
    case menu, stop, start, explain, swap, superset, add, settype, gym, program, tplmenu
}

struct DraftItem: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var warm: Bool
    var warmW: Double?
    var sets: Int
    var reps: Int
    var repsMax: Int? = nil
    var w: Double
    var link: Bool
}

struct Draft: Hashable {
    var orig: String?
    var name: String
    var items: [DraftItem]

    init(name: String?, plans: [PlanItem]) {
        orig = name
        self.name = name ?? ""
        var list: [DraftItem] = []
        for (i, p) in plans.enumerated() {
            let linked = i > 0 && plans[i - 1].group == p.group
            list.append(DraftItem(name: p.name, warm: p.warm != nil, warmW: p.warm?.w,
                                  sets: p.sets.count, reps: p.sets.first?.r ?? 10, repsMax: p.sets.first?.rmax,
                                  w: p.sets.first?.w ?? 20, link: linked))
        }
        items = list
    }

    func toPlans() -> [PlanItem] {
        var g = 0
        var out: [PlanItem] = []
        for (i, it) in items.enumerated() {
            if !(i > 0 && it.link) { g += 1 }
            var sets: [PlanSet] = []
            for _ in 0..<it.sets { sets.append(PlanSet(w: it.w, r: it.reps, rmax: it.repsMax)) }
            var plan = PlanItem(name: it.name, group: g, sets: sets)
            if it.warm {
                plan.warm = PlanSet(w: it.warmW ?? (it.w / 2).rounded(), r: 12)
            }
            out.append(plan)
        }
        return out
    }
}

struct Toast: Equatable {
    var text: String
    var removed: RemovedSetBox
    var until: Date
}

/// Maakt `RemovedSet` vergelijkbaar voor `Toast`.
struct RemovedSetBox: Equatable {
    var value: RemovedSet
    static func == (a: RemovedSetBox, b: RemovedSetBox) -> Bool { a.value.set.id == b.value.set.id }
}

/// Alles wat bewaard wordt.
struct PersistedState: Codable {
    var templates: [String: [PlanItem]]
    var programs: [PlanProgram]
    var progID: String
    var gyms: [GymSetup]
    var gymID: String
    var history: [HistoryEntry]
    var session: LiveSession?
    var accent: AccentID
    var themeMode: AppearanceMode
    var restDefault: Int
    var warmFirst: Bool
    var crea: Bool
    var links: [String: String]
    var prefs: [String: String]
    /// Nieuwere velden zijn optioneel, zodat een oud opslagbestand nog te lezen is.
    var customExercises: [CustomExercise]? = nil
    var dataVersion: Int? = nil
}

/// De toestand van de hele app. De regels staan in `LiveSession`; dit is de laag die schermen en opslag verbindt.
final class AppModel: ObservableObject {
    // Navigatie
    @Published var screen: Screen = .home
    @Published var tab: HomeTab = .training
    @Published var sheet: SheetKind?
    @Published var sheetEx: UUID?
    @Published var sheetSet: UUID?

    // Gegevens
    @Published var templates: [String: [PlanItem]]
    @Published var programs: [PlanProgram]
    @Published var progID: String
    @Published var gyms: [GymSetup]
    @Published var gymID: String
    @Published var history: [HistoryEntry]
    @Published var session: LiveSession?

    // Instellingen
    @Published var accent: AccentID
    @Published var themeMode: AppearanceMode
    @Published var restDefault: Int
    @Published var warmFirst: Bool
    @Published var crea: Bool
    @Published var links: [String: String]
    @Published var prefs: [String: String]
    @Published var customExercises: [CustomExercise]

    // Werkscherm
    @Published var focusID: UUID?
    @Published var restEnd: Date?
    @Published var restTotal: Int = 90
    @Published var toast: Toast?
    @Published var summary: SessionSummary?

    // Sheets en schermen
    @Published var pending: String?
    @Published var query = ""
    @Published var selected: [UUID] = []
    @Published var selectedNew: [String] = []
    @Published var linkDraft = ""
    @Published var savePref = false
    @Published var ovName: String?
    @Published var tmName: String?
    @Published var edReturn: Screen = .home
    @Published var draft: Draft?
    @Published var addToDraft = false

    // Kalender
    @Published var calOpen = false
    @Published var calSel: Int?
    @Published var calInfo = ""

    private let fileURL: URL?
    private var toastWork: DispatchWorkItem?

    init(fileURL: URL?, seed: PersistedState? = nil, now: Date = Date()) {
        self.fileURL = fileURL
        let state = seed ?? AppModel.load(fileURL) ?? AppModel.defaultState(now: now)
        templates = state.templates
        programs = state.programs
        progID = state.progID
        gyms = state.gyms
        gymID = state.gymID
        history = state.history
        session = state.session
        accent = state.accent
        themeMode = state.themeMode
        restDefault = state.restDefault
        warmFirst = state.warmFirst
        crea = state.crea
        links = state.links
        prefs = state.prefs
        customExercises = state.customExercises ?? []
        Catalog.setCustom(customExercises)
    }

    static let dataVersion = 2

    static func defaultState(now: Date) -> PersistedState {
        PersistedState(templates: SeedData.templates, programs: SeedData.programs, progID: "p1",
                       gyms: SeedData.gyms, gymID: "g1", history: [], session: nil,
                       accent: .olive, themeMode: .system, restDefault: 90, warmFirst: true, crea: true,
                       links: [:], prefs: [:], customExercises: [], dataVersion: AppModel.dataVersion)
    }

    // MARK: Opslag

    static func defaultFileURL() -> URL? {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("sport-app.json")
    }

    private static func load(_ url: URL?) -> PersistedState? {
        guard let url = url, FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        if let state = try? JSONDecoder().decode(PersistedState.self, from: data) {
            if (state.dataVersion ?? 1) >= AppModel.dataVersion { return state }
            // Opslag uit de testversie met voorbeeldgegevens: bewaren onder andere naam en schoon beginnen.
            let old = url.deletingLastPathComponent().appendingPathComponent("sport-app.voorbeeld-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.moveItem(at: url, to: old)
            return nil
        }
        // Onleesbaar bestand: bewaar het onder een andere naam in plaats van het te overschrijven.
        let stamp = Int(Date().timeIntervalSince1970)
        let broken = url.deletingLastPathComponent().appendingPathComponent("sport-app.broken-\(stamp).json")
        try? FileManager.default.moveItem(at: url, to: broken)
        return nil
    }

    var state: PersistedState {
        PersistedState(templates: templates, programs: programs, progID: progID, gyms: gyms, gymID: gymID,
                       history: history, session: session, accent: accent, themeMode: themeMode,
                       restDefault: restDefault, warmFirst: warmFirst, crea: crea, links: links, prefs: prefs,
                       customExercises: customExercises, dataVersion: AppModel.dataVersion)
    }

    func save() {
        guard let url = fileURL else { return }
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: Afgeleid

    var program: PlanProgram {
        programs.first(where: { $0.id == progID }) ?? programs.first ?? PlanProgram(id: "p0", name: "Schema", workouts: [])
    }

    var gym: GymSetup {
        gyms.first(where: { $0.id == gymID }) ?? gyms.first ?? GymSetup(id: "g0", name: "Gym", equipment: [])
    }

    func planSummary(_ name: String) -> (sub: String, muscles: String, items: [PlanItem]) {
        let items = templates[name] ?? []
        var work = 0
        var warm = 0
        var muscles: [String] = []
        for x in items {
            work += x.sets.count
            if x.warm != nil { warm += 1 }
            let m = Catalog.info(x.name).muscle
            if !muscles.contains(m) { muscles.append(m) }
        }
        let minutes = Int((Double(work) * 2.25 + Double(warm)).rounded())
        let count = items.count
        let sub = "\(count) \(count == 1 ? "oefening" : "oefeningen") · \(work) sets · ~\(minutes) min"
        return (sub, muscles.isEmpty ? "Nog leeg" : muscles.joined(separator: " · "), items)
    }

    /// Aantal dagen geleden (0 = vandaag) van een moment.
    func dayOffset(_ date: Date, now: Date = Date()) -> Int {
        let cal = Calendar.current
        let a = cal.startOfDay(for: date)
        let b = cal.startOfDay(for: now)
        return cal.dateComponents([.day], from: a, to: b).day ?? 0
    }

    func training(atOffset off: Int, now: Date = Date()) -> HistoryEntry? {
        history.first(where: { dayOffset($0.date, now: now) == off })
    }

    /// Welke training volgt in de rotatie van het gekozen schema.
    func nextWorkoutName(now: Date = Date()) -> String? {
        let names = program.workouts
        if names.isEmpty { return nil }
        let sorted = history.sorted { $0.date > $1.date }
        if let last = sorted.first(where: { names.contains($0.name) }), let i = names.firstIndex(of: last.name) {
            return names[(i + 1) % names.count]
        }
        return names[0]
    }

    // MARK: Start, stoppen, afronden

    func askStart(_ name: String) {
        if session != nil {
            pending = name
            openSheet(.start)
        } else {
            doStart(name)
        }
    }

    func doStart(_ name: String) {
        session = LiveSession.make(name: name, startAt: Date(), templates: templates, history: history)
        screen = .workout
        focusID = nil
        restEnd = nil
        sheet = nil
        toast = nil
        Notifier.requestAuthorizationIfNeeded()
        save()
    }

    func finish(note: String? = nil) {
        guard let s = session else { return }
        let now = Date()
        let result = s.finishSummary(now: now, note: note)
        if result.workSets > 0 {
            let minutes = max(1, Int((now.timeIntervalSince(s.startAt) / 60).rounded()))
            var logged: [LoggedExercise] = []
            for e in s.exercises {
                let done = e.sets.filter { $0.done }.map { LoggedSet(w: $0.w, r: $0.r, type: $0.type) }
                if done.contains(where: { $0.type != .warmup }) { logged.append(LoggedExercise(name: e.name, sets: done)) }
            }
            history.insert(HistoryEntry(date: now, name: s.name, minutes: minutes, exercises: logged), at: 0)
        }
        summary = result.summary
        session = nil
        screen = .summary
        sheet = nil
        restEnd = nil
        focusID = nil
        toast = nil
        Notifier.cancelRest()
        save()
    }

    func discardWorkout() {
        session = nil
        sheet = nil
        screen = .home
        restEnd = nil
        Notifier.cancelRest()
        save()
    }

    func goHome() {
        screen = .home
        summary = nil
    }

    // MARK: Sets

    func current() -> (queue: [QueueItem], cur: QueueItem?) {
        guard let s = session else { return ([], nil) }
        return s.current(focus: focusID, warmFirst: warmFirst)
    }

    func stepWeight(_ dir: Int) {
        guard var s = session, let c = current().cur else { return }
        s.stepWeight(set: c.setID, exID: c.exID, dir: dir)
        session = s
        save()
    }

    func stepReps(_ dir: Int) {
        guard var s = session, let c = current().cur else { return }
        s.stepReps(set: c.setID, exID: c.exID, dir: dir)
        session = s
        save()
    }

    func complete() {
        guard var s = session else { return }
        guard let result = s.complete(focus: focusID, warmFirst: warmFirst, restDefault: restDefault) else { return }
        session = s
        focusID = result.nextFocus
        toast = nil
        Haptics.success()
        if let seconds = result.restSeconds {
            restTotal = seconds
            restEnd = Date().addingTimeInterval(TimeInterval(seconds))
            Notifier.scheduleRest(seconds: seconds)
        } else {
            restEnd = nil
            Notifier.cancelRest()
        }
        save()
    }

    func addSet(_ exID: UUID) {
        guard var s = session else { return }
        s.addSet(to: exID)
        session = s
        Haptics.light()
        save()
    }

    func addWarmup(_ exID: UUID) {
        guard var s = session else { return }
        s.addWarmup(to: exID)
        session = s
        Haptics.light()
        save()
    }

    func setType(exID: UUID, setID: UUID, to type: SetType) {
        guard var s = session else { return }
        s.setType(exID: exID, setID: setID, to: type)
        session = s
        sheet = nil
        save()
    }

    func deleteSet(exID: UUID, setID: UUID) {
        guard var s = session else { return }
        guard let removed = s.deleteSet(exID: exID, setID: setID) else { return }
        session = s
        let until = Date().addingTimeInterval(5)
        toast = Toast(text: "Set verwijderd", removed: RemovedSetBox(value: removed), until: until)
        toastWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if let t = self.toast, t.until <= Date().addingTimeInterval(0.2) { self.toast = nil }
        }
        toastWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.1, execute: work)
        save()
    }

    func undo() {
        guard let t = toast, var s = session else { return }
        s.restore(t.removed.value)
        session = s
        toast = nil
        save()
    }

    func swapExercise(to name: String, manual: Bool) {
        guard var s = session, let ex = sheetEx, let current = s.exercise(ex) else { return }
        let old = current.name
        s.swap(exID: ex, to: name, history: history)
        session = s
        if manual && savePref { prefs[old] = name }
        sheet = nil
        save()
    }

    func addExercise(_ name: String) {
        guard var s = session else { return }
        s.addExercise(name, history: history)
        session = s
        sheet = nil
        save()
    }

    func linkSelected() {
        guard var s = session, let ex = sheetEx else { return }
        s.link(base: ex, existing: selected, newNames: selectedNew, history: history)
        session = s
        sheet = nil
        save()
    }

    func unlinkSheetExercise() {
        guard var s = session, let ex = sheetEx else { return }
        s.unlink(exID: ex)
        session = s
        sheet = nil
        save()
    }

    // MARK: Rust

    func adjustRest(_ delta: Int) {
        guard let end = restEnd else { return }
        if delta < 0 {
            restEnd = max(Date().addingTimeInterval(1), end.addingTimeInterval(TimeInterval(delta)))
        } else {
            restEnd = end.addingTimeInterval(TimeInterval(delta))
            restTotal += delta
        }
        if let e = restEnd { Notifier.scheduleRest(seconds: max(1, Int(e.timeIntervalSinceNow))) }
    }

    func skipRest() {
        restEnd = nil
        Notifier.cancelRest()
    }

    // MARK: Sheets

    func openSheet(_ kind: SheetKind, exID: UUID? = nil, setID: UUID? = nil) {
        sheet = kind
        sheetEx = exID
        sheetSet = setID
        query = ""
        selected = []
        selectedNew = []
        savePref = false
        addToDraft = false
        if kind == .explain { linkDraft = "" }
    }

    func closeSheet() { sheet = nil }

    // MARK: Schema's en trainingen

    func newTemplate() {
        draft = Draft(name: nil, plans: [])
        edReturn = .home
        screen = .editor
    }

    func editTemplate(_ name: String) {
        draft = Draft(name: name, plans: templates[name] ?? [])
        edReturn = screen == .overview ? .overview : .home
        sheet = nil
        screen = .editor
    }

    func duplicateTemplate(_ name: String) {
        var k = 2
        while templates[name + " (\(k))"] != nil { k += 1 }
        let copy = name + " (\(k))"
        var plans = templates[name] ?? []
        for i in plans.indices { plans[i].id = UUID() }
        templates[copy] = plans
        if let pi = programs.firstIndex(where: { $0.id == progID }), let wi = programs[pi].workouts.firstIndex(of: name) {
            programs[pi].workouts.insert(copy, at: wi + 1)
        }
        sheet = nil
        save()
    }

    func removeTemplateFromProgram(_ name: String) {
        if let pi = programs.firstIndex(where: { $0.id == progID }) {
            programs[pi].workouts.removeAll { $0 == name }
        }
        sheet = nil
        screen = .home
        ovName = nil
        save()
    }

    func saveDraft() {
        guard let d = draft else { return }
        let name = d.name.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return }
        if let orig = d.orig, orig != name {
            templates[orig] = nil
            for i in programs.indices {
                programs[i].workouts = programs[i].workouts.map { $0 == orig ? name : $0 }
            }
        }
        templates[name] = d.toPlans()
        if d.orig == nil, let pi = programs.firstIndex(where: { $0.id == progID }), !programs[pi].workouts.contains(name) {
            programs[pi].workouts.append(name)
        }
        let back: Screen = edReturn == .overview ? .overview : .home
        ovName = back == .overview ? name : nil
        screen = back
        draft = nil
        save()
    }

    func cancelDraft() {
        screen = edReturn == .overview ? .overview : .home
        draft = nil
    }

    func deleteDraftTemplate() {
        guard let orig = draft?.orig else { return }
        templates[orig] = nil
        for i in programs.indices { programs[i].workouts.removeAll { $0 == orig } }
        screen = .home
        ovName = nil
        draft = nil
        save()
    }

    func newProgram() {
        let id = "p\(Int(Date().timeIntervalSince1970))"
        programs.append(PlanProgram(id: id, name: "Nieuw schema \(programs.count)", workouts: []))
        progID = id
        sheet = nil
        save()
    }

    func chooseProgram(_ id: String) {
        progID = id
        sheet = nil
        save()
    }

    func chooseGym(_ id: String) {
        gymID = id
        sheet = nil
        save()
    }

    func toggleMachine(_ index: Int) {
        guard let gi = gyms.firstIndex(where: { $0.id == gym.id }), gyms[gi].equipment.indices.contains(index) else { return }
        gyms[gi].equipment[index].on.toggle()
        save()
    }

    // MARK: Eigen oefeningen

    func addCustomExercise(name: String, muscle: String, equipment: String, kind: ExerciseKind) -> String? {
        let n = name.trimmingCharacters(in: .whitespaces)
        if n.isEmpty { return nil }
        if Catalog.allNames.contains(where: { $0.lowercased() == n.lowercased() }) {
            return Catalog.allNames.first(where: { $0.lowercased() == n.lowercased() })
        }
        customExercises.append(CustomExercise(name: n, muscle: muscle, equipment: equipment, kind: kind))
        Catalog.setCustom(customExercises)
        save()
        return n
    }

    // MARK: Uitleg-links

    func saveLink(for exercise: String) {
        var u = linkDraft.trimmingCharacters(in: .whitespaces)
        if u.isEmpty { return }
        if !(u.lowercased().hasPrefix("http://") || u.lowercased().hasPrefix("https://")) { u = "https://" + u }
        links[exercise] = u
        linkDraft = ""
        save()
    }

    func clearLink(for exercise: String) {
        links[exercise] = nil
        save()
    }

    // MARK: Instellingen

    func setRestDefault(_ value: Int) {
        restDefault = min(300, max(30, value))
        save()
    }

    func setCreatine(_ on: Bool) {
        crea = on
        if on { Notifier.requestAuthorizationIfNeeded() }
        Notifier.updateCreatine(on: on)
        save()
    }
}

/// Lichte trilling bij belangrijke momenten.
enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

/// Lokale meldingen: einde van de rusttijd en de dagelijkse creatine-herinnering.
enum Notifier {
    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func scheduleRest(seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rust voorbij"
        content.body = "Tijd voor je volgende set."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, seconds)), repeats: false)
        let request = UNNotificationRequest(identifier: "rest", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelRest() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest"])
    }

    static func updateCreatine(on: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["creatine"])
        guard on else { return }
        let content = UNMutableNotificationContent()
        content.title = "Creatine"
        content.body = "Tijd voor je creatine."
        content.sound = .default
        var parts = DateComponents()
        parts.hour = 9
        parts.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        center.add(UNNotificationRequest(identifier: "creatine", content: content, trigger: trigger))
    }
}
