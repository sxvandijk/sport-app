import Foundation
import SwiftUI
import UserNotifications
import AudioToolbox
import Combine

enum Screen: String, Codable { case home, workout, overview, editor, summary, records, allWorkouts, creatine, workoutDetail }
enum HomeTab: Int, CaseIterable, Identifiable {
    case gym, progress, start, training, profile
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .start: return "Start"
        case .training: return "Training"
        case .progress: return "Progressie"
        case .gym: return "Gym"
        case .profile: return "Profiel"
        }
    }
}

enum SheetKind: String {
    case menu, stop, start, explain, swap, change, pref, superset, add, settype, gym, program, tplmenu, exmenu, swapscope, machineadd, machineedit, draftswap, accedit, accpick, accuse, sidemode, weekplan
}

enum SwapScope { case now, schema, prefOnly }
enum EditField { case weight, reps, reps2 }

struct DraftItem: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var warmSets: Int
    var warmW: Double?
    var sets: Int
    var reps: Int
    var repsMax: Int? = nil
    var w: Double
    var link: Bool
    var isWarmup = false
    var isCooldown = false
    /// 0 = warming-up, 1 = oefening, 2 = cooling-down.
    var blockKind: Int { isWarmup ? 0 : (isCooldown ? 2 : 1) }
}

extension DraftItem {
    mutating func repsUp() {
        reps += 1
        if let m = repsMax, m <= reps { repsMax = nil }
    }

    mutating func maxUp() {
        repsMax = (repsMax ?? reps) + 1
    }

    mutating func maxDown() {
        if let m = repsMax { repsMax = m - 1 <= reps ? nil : m - 1 }
    }
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
            let isWarm = p.isWarmup == true
            let isCool = p.isCooldown == true
            let linked = !isWarm && !isCool && i > 0 && plans[i - 1].group == p.group && plans[i - 1].blockKind == 1
            var item = DraftItem(name: p.name, warmSets: p.warm == nil ? 0 : (p.warmCount ?? 1), warmW: p.warm?.w,
                                 sets: p.sets.count, reps: p.sets.first?.r ?? 10, repsMax: p.sets.first?.rmax,
                                 w: p.sets.first?.w ?? 20, link: linked)
            item.isWarmup = isWarm
            item.isCooldown = isCool
            list.append(item)
        }
        items = list
    }

    func toPlans() -> [PlanItem] {
        var g = 0
        var out: [PlanItem] = []
        let ordered = items.filter { $0.blockKind == 0 } + items.filter { $0.blockKind == 1 } + items.filter { $0.blockKind == 2 }
        for (i, it) in ordered.enumerated() {
            if !(i > 0 && it.link && it.blockKind == 1 && ordered[i - 1].blockKind == 1) { g += 1 }
            var sets: [PlanSet] = []
            for _ in 0..<it.sets { sets.append(PlanSet(w: it.w, r: it.reps, rmax: it.repsMax)) }
            var plan = PlanItem(name: it.name, group: g, sets: sets)
            if it.isWarmup { plan.isWarmup = true }
            if it.isCooldown { plan.isCooldown = true }
            if it.warmSets > 0 && it.blockKind == 1 {
                plan.warm = PlanSet(w: it.warmW ?? (it.w / 2).rounded(), r: 12)
                plan.warmCount = it.warmSets
            }
            out.append(plan)
        }
        return out
    }
}

/// Een notitie bij een oefening, met de dag waarop je hem schreef.
struct NoteEdit: Equatable {
    var exercise: String
    var entryID: UUID?
    var text: String
}

struct NameEdit {
    var title: String
    var subtitle: String = ""
    var placeholder: String
    var text: String
    var confirmTitle: String
    var action: (String) -> Void
}

struct ConfirmRequest {
    var title: String
    var message: String
    var confirmTitle: String
    var action: () -> Void
}

struct NoteEntry: Codable, Hashable, Identifiable {
    var id = UUID()
    var date: Date
    var text: String
}

struct Toast: Equatable {
    var text: String
    var removed: RemovedSetBox?
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
    var restMigrated: Bool? = nil
    var creaTime: Int? = nil          // minuten sinds middernacht
    var creaLateOn: Bool? = nil
    var creaLateTime: Int? = nil
    var creaDone: [String]? = nil     // dagen (yyyy-MM-dd) waarop je hem hebt afgevinkt
    var creaDayOff: [Int]? = nil      // weekdagen (1 = zondag ... 7 = zaterdag) zonder herinnering
    var creaDayTime: [String: Int]? = nil  // eigen tijd per weekdag (minuten sinds middernacht)
    var creaDayLate: [String: Int]? = nil  // eigen tijd van de tweede herinnering per weekdag
    var creaDayLateOff: [Int]? = nil       // weekdagen zonder tweede herinnering
    var exAcc: [String: [String]]? = nil   // per oefening: namen van de opzetstukken die je gebruikt
    var weekReset: Bool? = nil             // nieuwe week: schema begint weer bij de eerste training
    var staleReminder: Bool? = nil         // melding bij vergeten workout (standaard aan)
    var weekPlan: [String: String]? = nil  // weekdag (1 = zondag ... 7 = zaterdag) -> naam van de training
    var dataVersion: Int? = nil
    var notes: [String: String]? = nil          // oude opslag, alleen nog om te lezen
    var noteLog: [String: [NoteEntry]]? = nil
}

/// De toestand van de hele app. De regels staan in `LiveSession`; dit is de laag die schermen en opslag verbindt.
final class AppModel: ObservableObject {
    // Navigatie
    @Published var screen: Screen = .home
    /// Ready, Set, Go bij het openen van de app.
    @Published var launchSplash = false
    @Published var tab: HomeTab = .start
    @Published var sheet: SheetKind?
    @Published var sheetEx: UUID?
    @Published var sheetSet: UUID?

    // Gegevens
    @Published var templates: [String: [PlanItem]]
    @Published var programs: [PlanProgram]
    @Published var progID: String
    @Published var gyms: [GymSetup]
    @Published var gymID: String
    /// Apparaat dat in de bewerk-sheet openstaat.
    @Published var machineEditID: String?
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
    @Published var creaTime: Int
    @Published var creaLateOn: Bool
    @Published var creaLateTime: Int
    @Published var creaDone: [String]
    @Published var creaDayOff: [Int]
    @Published var creaDayTime: [String: Int]
    @Published var creaDayLate: [String: Int]
    @Published var creaDayLateOff: [Int]
    @Published var exAcc: [String: [String]]
    @Published var weekReset: Bool
    @Published var staleReminder: Bool
    @Published var weekPlan: [String: String]
    @Published var accEditID: String?
    @Published var noteLog: [String: [NoteEntry]]

    // Werkscherm
    @Published var focusID: UUID?
    @Published var focusSetID: UUID?
    @Published var editField: EditField?
    @Published var restEnd: Date?
    @Published var lastSetAt: Date?
    /// Moment waarop de rust voorbij was of werd overgeslagen.
    @Published var restOverAt: Date?
    @Published var restTotal: Int = 90
    @Published var toast: Toast?
    @Published var noteEdit: NoteEdit?
    @Published var scrollTick = 0
    @Published var confirm: ConfirmRequest?
    @Published var nameEdit: NameEdit?
    /// Oefening in het schema-bewerkscherm die gewisseld wordt.
    @Published var draftSwapID: UUID?
    @Published var summary: SessionSummary?
    /// Training die je net hebt afgerond, als een vrije training die nog een naam kan krijgen.
    @Published var summaryFreeID: UUID?
    @Published var detailID: UUID?

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
    @Published var addToDraftWarmup = false
    @Published var addToDraftCooldown = false
    @Published var swapScope = SwapScope.now

    // Kalender
    @Published var calOpen = false
    @Published var calOpenProgress = false
    @Published var calSel: Int?
    @Published var calInfo = ""

    private let fileURL: URL?
    private var toastWork: DispatchWorkItem?
    private var restAlarm: DispatchWorkItem?

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
        creaTime = state.creaTime ?? 9 * 60
        creaLateOn = state.creaLateOn ?? true
        creaLateTime = state.creaLateTime ?? 18 * 60
        creaDone = state.creaDone ?? []
        creaDayOff = state.creaDayOff ?? []
        creaDayTime = state.creaDayTime ?? [:]
        creaDayLate = state.creaDayLate ?? [:]
        creaDayLateOff = state.creaDayLateOff ?? []
        exAcc = state.exAcc ?? [:]
        weekReset = state.weekReset ?? false
        staleReminder = state.staleReminder ?? true
        weekPlan = state.weekPlan ?? [:]
        var log = state.noteLog ?? [:]
        for (name, text) in state.notes ?? [:] where log[name] == nil && !text.isEmpty {
            log[name] = [NoteEntry(date: now, text: text)]
        }
        noteLog = log
        // Eerdere versies hadden 1:30 als standaard rusttijd; de nieuwe standaard is 3:00.
        if state.restMigrated != true && state.restDefault == 90 { restDefault = 180 }
        Catalog.setCustom(customExercises)
        applyGym()
        // Live Activity (vergrendelscherm / Dynamic Island) volgt de lopende training. Niet bij screenshots en tests.
        if fileURL != nil { startLiveActivityLink() }
    }

    func startLiveActivityLink() {
        liveActivityLink = Publishers.CombineLatest($session, $restEnd)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in self?.syncLiveActivity() }
    }

    private var liveActivityLink: AnyCancellable?

    /// De huidige toestand voor de Live Activity.
    func liveState() -> WorkoutLiveState? {
        guard let s = session else { return nil }
        let works = s.exercises.flatMap { $0.workSets }
        let done = works.filter { $0.done }.count
        var exercise = "Alle sets gedaan"
        var setText = "Rond je workout af"
        if let c = current().cur, let ex = s.exercise(c.exID) {
            exercise = ex.name
            let sets = ex.workSets
            if let i = sets.firstIndex(where: { $0.id == c.setID }) {
                setText = "Set \(i + 1) van \(sets.count)"
            } else {
                setText = "Opwarmen"
            }
        }
        return WorkoutLiveState(exercise: exercise, setText: setText, done: done, total: works.count,
                                restEnd: restEnd, accent: Int(accent.hex))
    }

    func syncLiveActivity() {
        LiveActivityManager.sync(name: session?.name, startAt: session?.startAt, state: liveState())
    }

    static let dataVersion = 2

    static func defaultState(now: Date) -> PersistedState {
        PersistedState(templates: SeedData.templates, programs: SeedData.programs, progID: "p1",
                       gyms: SeedData.gyms, gymID: "g1", history: [], session: nil,
                       accent: .olive, themeMode: .system, restDefault: 180, warmFirst: true, crea: true,
                       links: [:], prefs: [:], customExercises: [], restMigrated: true, dataVersion: AppModel.dataVersion)
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
                       customExercises: customExercises, restMigrated: true, creaTime: creaTime, creaLateOn: creaLateOn, creaLateTime: creaLateTime,
                       creaDone: creaDone, creaDayOff: creaDayOff, creaDayTime: creaDayTime, creaDayLate: creaDayLate, creaDayLateOff: creaDayLateOff, exAcc: exAcc, weekReset: weekReset, staleReminder: staleReminder, weekPlan: weekPlan, dataVersion: AppModel.dataVersion, notes: nil, noteLog: noteLog)
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
        for x in items where x.blockKind == 1 {
            work += x.sets.count
            if x.warm != nil { warm += x.warmCount ?? 1 }
            let m = Catalog.info(x.name).muscle
            if !muscles.contains(m) { muscles.append(m) }
        }
        let minutes = Int((Double(work) * 2.25 + Double(warm)).rounded())
        let count = items.filter { $0.blockKind == 1 }.count
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

    /// De training die je voor vandaag in de weekplanning hebt gezet (als die in je schema zit).
    func plannedWorkout(now: Date = Date()) -> String? {
        let day = String(Calendar.current.component(.weekday, from: now))
        guard let name = weekPlan[day], program.workouts.contains(name) else { return nil }
        return name
    }

    func setPlan(weekday: Int, to name: String?) {
        if let n = name { weekPlan[String(weekday)] = n } else { weekPlan[String(weekday)] = nil }
        save()
    }

    /// Welke training volgt in de rotatie van het gekozen schema.
    func nextWorkoutName(now: Date = Date()) -> String? {
        let names = program.workouts
        if names.isEmpty { return nil }
        if let planned = plannedWorkout(now: now) { return planned }
        let sorted = history.sorted { $0.date > $1.date }
        if let last = sorted.first(where: { names.contains($0.name) }), let i = names.firstIndex(of: last.name) {
            if weekReset {
                var cal = Calendar.current
                cal.firstWeekday = 2
                if !cal.isDate(last.date, equalTo: now, toGranularity: .weekOfYear) { return names[0] }
            }
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
        lastSetAt = nil
        restOverAt = nil
        sheet = nil
        toast = nil
        Notifier.requestAuthorizationIfNeeded()
        if staleReminder { Notifier.scheduleStale(after: Self.staleAfter) }
        save()
    }

    /// Na zoveel stilstand vragen we of je de workout wilt sluiten.
    static let staleAfter: TimeInterval = 1.5 * 3600
    private var staleAskedAt: Date?

    /// Bij openen van de app: staat er een workout die al uren stilstaat, vraag dan of hij dicht mag.
    func checkStaleWorkout() {
        guard staleReminder, let s = session, confirm == nil else { return }
        let last = s.lastActivity ?? s.startAt
        let now = Date()
        guard now.timeIntervalSince(last) > Self.staleAfter else { return }
        if let asked = staleAskedAt, now.timeIntervalSince(asked) < 1800 { return }
        staleAskedAt = now
        let hours = Int(now.timeIntervalSince(last) / 3600)
        confirm = ConfirmRequest(title: "Workout sluiten?",
                                 message: "Je laatste set was \(hours) uur geleden. Wil je de workout afsluiten en opslaan zoals hij toen stond? Met Annuleer ga je gewoon door.",
                                 confirmTitle: "Sluit workout af") { [weak self] in
            self?.finish(at: last)
        }
    }

    func finish(note: String? = nil, at end: Date = Date()) {
        guard let s = session else { return }
        let now = end
        Notifier.cancelStale()
        let result = s.finishSummary(now: now, note: note)
        if result.workSets > 0 {
            let minutes = max(1, Int((now.timeIntervalSince(s.startAt) / 60).rounded()))
            var logged: [LoggedExercise] = []
            for e in s.exercises {
                let done = e.sets.filter { $0.done }.map { LoggedSet(w: $0.w, r: $0.r, type: $0.type, r2: $0.r2, m: e.two == true && $0.type != .warmup ? 2 : nil) }
                if !done.isEmpty { logged.append(LoggedExercise(name: e.name, sets: done, uni: e.uni, two: e.two, acc: e.acc)) }
            }
            let entry = HistoryEntry(date: now, name: s.name, minutes: minutes, exercises: logged)
            history.insert(entry, at: 0)
            summaryFreeID = s.name == "Lege training" ? entry.id : nil
        } else {
            summaryFreeID = nil
        }
        summary = result.summary
        session = nil
        screen = .summary
        sheet = nil
        restEnd = nil
        lastSetAt = nil
        restOverAt = nil
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
        Notifier.cancelStale()
        save()
    }

    func goHome() {
        screen = .home
        summary = nil
        summaryFreeID = nil
    }

    func renameHistory(_ id: UUID, to name: String) {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty, let i = history.firstIndex(where: { $0.id == id }) else { return }
        history[i].name = n
        if summaryFreeID == id { summary?.title = n + " afgerond" }
        save()
    }

    // MARK: Sets

    func current() -> (queue: [QueueItem], cur: QueueItem?) {
        guard let s = session else { return ([], nil) }
        return s.current(focus: focusID, focusSet: focusSetID, warmFirst: warmFirst)
    }

    func stepWeight(_ dir: Int) {
        guard var s = session, let c = current().cur else { return }
        s.stepWeight(set: c.setID, exID: c.exID, dir: dir)
        session = s
        save()
    }

    func toggleTwoSides(_ exID: UUID) {
        guard var s = session else { return }
        s.toggleTwoSides(exID)
        session = s
        Haptics.light()
        save()
    }

    func toggleUnilateral(_ exID: UUID) {
        guard var s = session else { return }
        s.toggleUnilateral(exID)
        session = s
        editField = nil
        Haptics.light()
        save()
    }

    func stepReps(_ dir: Int, second: Bool = false) {
        guard var s = session, let c = current().cur else { return }
        s.stepReps(set: c.setID, exID: c.exID, dir: dir, second: second)
        session = s
        save()
    }

    func focus(_ exID: UUID) {
        focusID = exID
        focusSetID = nil
        editField = nil
    }

    /// Kies zelf een set (ook een al gedane, om aan te passen). Daarna ga je weer verder waar je was.
    func selectSet(exID: UUID, setID: UUID) {
        // Alleen de huidige set of een al gedane set (om aan te passen); een set die nog niet aan de beurt is blijft dicht.
        let isCurrent = current().cur?.setID == setID
        let isDone = session?.findSet(setID)?.done == true
        guard isCurrent || isDone else { return }
        focusID = exID
        focusSetID = setID
        let timed = session?.exercise(exID).map { Catalog.kind($0.name) == .timed } ?? false
        editField = timed ? .reps : .weight
        Haptics.light()
    }

    /// Vinkje van een gedane set weghalen.
    func uncompleteSet(exID: UUID, setID: UUID) {
        guard var s = session else { return }
        s.uncomplete(set: setID, exID: exID)
        session = s
        focusSetID = nil
        focusID = exID
        restEnd = nil
        Haptics.light()
        save()
    }

    /// Cijfers die je met het toetsenbord intikt voor de huidige set.
    func setCurrentValues(w: Double?, r: Int?, r2: Int? = nil) {
        guard var s = session, let c = current().cur else { return }
        s.setValues(set: c.setID, exID: c.exID, w: w, r: r, r2: r2)
        session = s
        save()
    }

    func addNote(_ text: String, for exercise: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        noteLog[exercise, default: []].insert(NoteEntry(date: Date(), text: t), at: 0)
        Haptics.light()
        save()
    }

    func saveNoteEdit() {
        guard let e = noteEdit else { return }
        noteEdit = nil
        // Eerst het venster en het toetsenbord weg, dan pas opslaan: voorkomt een hapering.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let id = e.entryID { self.updateNote(id, text: e.text, for: e.exercise) } else { self.addNote(e.text, for: e.exercise) }
        }
    }

    func updateNote(_ id: UUID, text: String, for exercise: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, let i = noteLog[exercise]?.firstIndex(where: { $0.id == id }) else { return }
        noteLog[exercise]?[i].text = t
        save()
    }

    func deleteNote(_ id: UUID, for exercise: String) {
        noteLog[exercise]?.removeAll { $0.id == id }
        if noteLog[exercise]?.isEmpty == true { noteLog[exercise] = nil }
        save()
    }

    /// Ster: deze oefening wordt je vaste keuze als de oorspronkelijke bezet is.
    func togglePreference(original: String, choice: String) {
        if prefs[original] == choice { prefs[original] = nil } else { prefs[original] = choice }
        save()
    }

    /// Verplaats een blok (een oefening of een superset) in het overzicht van een training.
    func moveBlock(template name: String, block id: UUID, onto targetID: UUID) {
        guard var items = templates[name], id != targetID else { return }
        var blocks: [[PlanItem]] = []
        for x in items {
            if let last = blocks.last?.last, last.group == x.group, last.blockKind == x.blockKind {
                blocks[blocks.count - 1].append(x)
            } else {
                blocks.append([x])
            }
        }
        guard let from = blocks.firstIndex(where: { $0.first?.id == id }),
              let to = blocks.firstIndex(where: { $0.first?.id == targetID }),
              blocks[from].first?.blockKind == blocks[to].first?.blockKind else { return }
        let moving = blocks.remove(at: from)
        blocks.insert(moving, at: to)
        items = blocks.flatMap { $0 }
        templates[name] = items
        save()
    }

    /// Verplaats een blok (oefening of superset) in de editor.
    func moveDraftBlock(_ headID: UUID, onto targetID: UUID) {
        guard var d = draft, headID != targetID else { return }
        var blocks = d.blocks
        guard let from = blocks.firstIndex(where: { $0.first?.id == headID }),
              let to = blocks.firstIndex(where: { $0.first?.id == targetID }),
              blocks[from].first?.blockKind == blocks[to].first?.blockKind else { return }
        let moving = blocks.remove(at: from)
        blocks.insert(moving, at: to)
        d.items = blocks.flatMap { $0 }
        EditorScreen.normalize(&d)
        draft = d
    }

    /// Verplaats een oefening in de editor naar de plek van een andere (slepen).
    func moveDraftItem(_ id: UUID, onto targetID: UUID) {
        guard var d = draft, id != targetID,
              let from = d.items.firstIndex(where: { $0.id == id }),
              let to = d.items.firstIndex(where: { $0.id == targetID }),
              d.items[from].blockKind == d.items[to].blockKind else { return }
        let item = d.items.remove(at: from)
        d.items.insert(item, at: to)
        EditorScreen.normalize(&d)
        draft = d
    }

    func complete() {
        guard var s = session else { return }
        if let c = current().cur, let set = s.findSet(c.setID), set.done {
            focusSetID = nil
            editField = nil
            focusID = nil
            save()
            return
        }
        guard let result = s.complete(focus: focusID, focusSet: focusSetID, warmFirst: warmFirst, restDefault: restDefault) else { return }
        session = s
        session?.lastActivity = Date()
        if staleReminder { Notifier.scheduleStale(after: Self.staleAfter) }
        scrollTick += 1
        focusSetID = nil
        editField = nil
        focusID = result.nextFocus
        toast = nil
        lastSetAt = Date()
        restOverAt = nil
        Haptics.success()
        if let seconds = result.restSeconds {
            restTotal = seconds
            restEnd = Date().addingTimeInterval(TimeInterval(seconds))
            armRestAlarm(seconds: seconds)
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

    /// Oefening voor vandaag overslaan, of (ook) uit het schema halen.
    func skipExercise(_ exID: UUID, removeFromSchema: Bool) {
        guard var s = session, let ex = s.exercise(exID) else { return }
        let names = [ex.name, ex.from].compactMap { $0 }
        s.skipExercise(exID)
        if removeFromSchema, var plans = templates[s.name] {
            if let i = plans.firstIndex(where: { names.contains($0.name) }) {
                plans.remove(at: i)
                templates[s.name] = plans
            }
        }
        session = s
        focusID = nil
        focusSetID = nil
        editField = nil
        sheet = nil
        Haptics.light()
        if !removeFromSchema, s.exercise(exID) != nil {
            toast = Toast(text: "Oefening voltooid", removed: nil, until: Date().addingTimeInterval(3))
        }
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
        var text = "Set verwijderd"
        if let ex = s.exercise(exID), !ex.sets.isEmpty, ex.sets.allSatisfy({ $0.done }) {
            text = "Set verwijderd \u{00B7} oefening voltooid"
            focusID = nil
            focusSetID = nil
            editField = nil
        }
        let until = Date().addingTimeInterval(5)
        toast = Toast(text: text, removed: RemovedSetBox(value: removed), until: until)
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
        guard let t = toast, let r = t.removed, var s = session else { return }
        s.restore(r.value)
        session = s
        toast = nil
        save()
    }

    func swapExercise(to name: String, manual: Bool) {
        guard var s = session, let ex = sheetEx, let current = s.exercise(ex) else { return }
        let old = current.name
        let original = current.from ?? old
        if swapScope == .prefOnly {
            prefs[original] = name
            sheet = nil
            save()
            return
        }
        let newID = s.swap(exID: ex, to: name, history: history)
        session = s
        focusID = newID
        focusSetID = nil
        if (manual && savePref) { prefs[original] = name }
        if swapScope == .schema, var plans = templates[s.name], let i = plans.firstIndex(where: { $0.name == old }) ?? plans.firstIndex(where: { $0.name == original }) {
            plans[i].name = name
            templates[s.name] = plans
        }
        sheet = nil
        save()
    }

    func clearPreference(for name: String) {
        prefs[name] = nil
        save()
    }

    /// Zet een oefening in het warming-upblok van het schema dat je aan het bewerken bent.
    func addDraftWarmup(_ name: String) {
        guard var d = draft else { return }
        let kind = Catalog.kind(name)
        var item = DraftItem(name: name, warmSets: 0, warmW: nil, sets: kind == .weights || kind == .bodyweight ? 2 : 1,
                             reps: kind == .weights || kind == .bodyweight ? 15 : 5, w: Catalog.info(name).defaultWeight, link: false)
        item.isWarmup = true
        let at = d.items.filter { $0.isWarmup }.count
        d.items.insert(item, at: at)
        EditorScreen.normalize(&d)
        draft = d
        sheet = nil
    }

    /// Zet een oefening in het cooling-downblok (achteraan) van het schema dat je aan het bewerken bent.
    func addDraftCooldown(_ name: String) {
        guard var d = draft else { return }
        let kind = Catalog.kind(name)
        var item = DraftItem(name: name, warmSets: 0, warmW: nil, sets: kind == .weights || kind == .bodyweight ? 2 : 1,
                             reps: kind == .weights || kind == .bodyweight ? 15 : 5, w: Catalog.info(name).defaultWeight, link: false)
        item.isCooldown = true
        d.items.append(item)
        EditorScreen.normalize(&d)
        draft = d
        sheet = nil
    }

    func renameProgram(_ id: String, to name: String) {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty, let i = programs.firstIndex(where: { $0.id == id }) else { return }
        programs[i].name = n
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
            if let e = restEnd { armRestAlarm(seconds: Int(e.timeIntervalSinceNow.rounded(.up))) }
        } else {
            restEnd = end.addingTimeInterval(TimeInterval(delta))
            restTotal += delta
            if let e = restEnd { armRestAlarm(seconds: Int(e.timeIntervalSinceNow.rounded(.up))) }
        }
    }

    /// Als de rust voorbij is: een korte trilling en, als het geluid aan staat, een geluidje. Alleen als de app open is.
    private func armRestAlarm(seconds: Int) {
        restAlarm?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, let end = self.restEnd, end <= Date().addingTimeInterval(0.5) else { return }
            Haptics.success()
            AudioServicesPlaySystemSound(1007)
        }
        restAlarm = work
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(max(1, seconds) * 1000), execute: work)
    }

    func skipRest() {
        restAlarm?.cancel()
        if let end = restEnd { restOverAt = min(end, Date()) } else { restOverAt = Date() }
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
        addToDraftWarmup = false
        addToDraftCooldown = false
        swapScope = .now
        if kind == .explain { linkDraft = "" }
    }

    var barDragging = false

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

    func newProgram(name: String) {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        let id = "p\(Int(Date().timeIntervalSince1970))"
        programs.append(PlanProgram(id: id, name: n, workouts: []))
        progID = id
        sheet = nil
        save()
    }

    /// Verwijdert een schema en de trainingen die nergens anders in zitten.
    func deleteProgram(_ id: String) {
        guard let gone = programs.first(where: { $0.id == id }) else { return }
        programs.removeAll { $0.id == id }
        let stillUsed = Set(programs.flatMap { $0.workouts })
        for name in gone.workouts where !stillUsed.contains(name) { templates[name] = nil }
        if programs.isEmpty {
            programs = [PlanProgram(id: "p\(Int(Date().timeIntervalSince1970))", name: "Mijn schema", workouts: [])]
        }
        if !programs.contains(where: { $0.id == progID }) { progID = programs[0].id }
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
        applyGym()
        save()
    }

    /// Zet de stappen van de aangevinkte apparaten van deze gym klaar voor de plus/min-knoppen.
    func applyGym() {
        var map: [String: WeightScale] = [:]
        var labels: [String: String] = [:]
        for m in gym.equipment where m.on {
            for name in m.exercises {
                if let scale = m.scale, map[name] == nil { map[name] = scale }
                if m.showsBrand || m.brand == "Eigen", labels[name] == nil { labels[name] = m.title }
            }
        }
        Catalog.gymScales = map
        Catalog.gymLabels = labels
        var acc: [String: [GymAccessory]] = [:]
        let all = gym.accessoryList
        for (ex, names) in exAcc {
            acc[ex] = all.filter { names.contains($0.name) }
        }
        Catalog.exAccessories = acc
        Catalog.defaultAccessories = all
    }

    private func mutateGym(_ body: (inout GymSetup) -> Void) {
        guard let gi = gyms.firstIndex(where: { $0.id == gym.id }) else { return }
        body(&gyms[gi])
        applyGym()
        save()
    }

    func toggleMachine(_ id: String) {
        mutateGym { g in
            if let i = g.equipment.firstIndex(where: { $0.id == id }) { g.equipment[i].on.toggle() }
        }
    }

    func machine(_ id: String?) -> GymMachine? {
        guard let id = id else { return nil }
        return gym.equipment.first { $0.id == id }
    }

    func hasMachine(_ model: MachineModel) -> Bool {
        gym.equipment.contains { $0.brand == model.brand && $0.name == model.name }
    }

    func addMachine(_ model: MachineModel) {
        guard !hasMachine(model) else { return }
        mutateGym { $0.equipment.append(GymMachine(model: model)) }
        Haptics.light()
    }

    /// Eigen apparaat; geeft het id terug zodat de bewerk-sheet kan openen.
    func addCustomMachine(name: String) -> String {
        let n = name.trimmingCharacters(in: .whitespaces)
        let m = GymMachine(brand: "Eigen", name: n.isEmpty ? "Eigen apparaat" : n)
        mutateGym { $0.equipment.append(m) }
        return m.id
    }

    // MARK: Opzetstukken

    private func mutateAccessories(_ body: (inout [GymAccessory]) -> Void) {
        mutateGym { g in
            var list = g.accessoryList
            body(&list)
            g.accessories = list
        }
    }

    func addAccessory(name: String) {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty, !gym.accessoryList.contains(where: { $0.name.lowercased() == n.lowercased() }) else { return }
        mutateAccessories { $0.append(GymAccessory(name: n)) }
        syncLiveAccessories()
    }

    func renameAccessory(_ id: String, to name: String) {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty, let old = gym.accessoryList.first(where: { $0.id == id })?.name, old != n else { return }
        mutateAccessories { list in if let i = list.firstIndex(where: { $0.id == id }) { list[i].name = n } }
        for (ex, names) in exAcc where names.contains(old) { exAcc[ex] = names.map { $0 == old ? n : $0 } }
        applyGym()
    }

    func setAccessoryStep(_ id: String, _ step: Double) {
        mutateAccessories { list in if let i = list.firstIndex(where: { $0.id == id }) { list[i].step = step } }
    }

    func deleteAccessory(_ id: String) {
        guard let old = gym.accessoryList.first(where: { $0.id == id })?.name else { return }
        mutateAccessories { $0.removeAll { $0.id == id } }
        for (ex, names) in exAcc where names.contains(old) { exAcc[ex] = names.filter { $0 != old } }
        applyGym()
        syncLiveAccessories()
        save()
    }

    func accessory(_ id: String?) -> GymAccessory? { gym.accessoryList.first { $0.id == id } }

    /// Opzetstukken van een oefening: je eigen keuze, anders alles bij kabeloefeningen.
    func accessoryNames(for exercise: String) -> [String] {
        Catalog.accessories(for: exercise).map { $0.name }
    }

    func exerciseUsesAccessory(_ exercise: String, _ acc: String) -> Bool { accessoryNames(for: exercise).contains(acc) }

    func toggleExerciseAccessory(_ exercise: String, _ acc: String) {
        var names = accessoryNames(for: exercise)
        if let i = names.firstIndex(of: acc) { names.remove(at: i) } else { names.append(acc) }
        exAcc[exercise] = names
        applyGym()
        syncLiveAccessories()
        save()
    }

    /// Een lopende oefening houdt altijd een opzetstuk dat nog bij hem hoort.
    func syncLiveAccessories() {
        guard var s = session else { return }
        var changed = false
        for i in s.exercises.indices {
            let list = Catalog.accessories(for: s.exercises[i].name)
            if list.isEmpty {
                if s.exercises[i].acc != nil { s.exercises[i].acc = nil; s.exercises[i].accStep = nil; changed = true }
            } else if !list.contains(where: { $0.name == s.exercises[i].acc }) {
                s.exercises[i].acc = list[0].name
                s.exercises[i].accStep = list[0].step > 0 ? list[0].step : nil
                changed = true
            }
        }
        if changed { session = s }
    }

    func setSideMode(_ exID: UUID, _ mode: SideMode) {
        guard var s = session else { return }
        s.setSideMode(exID, mode)
        session = s
        editField = nil
        Haptics.light()
        save()
    }

    func chooseAccessory(_ exID: UUID, _ acc: GymAccessory) {
        guard var s = session else { return }
        s.setAccessory(exID, to: acc, history: history)
        session = s
        Haptics.light()
        save()
    }

    func updateMachine(_ id: String, _ body: (inout GymMachine) -> Void) {
        mutateGym { g in
            if let i = g.equipment.firstIndex(where: { $0.id == id }) { body(&g.equipment[i]) }
        }
    }

    func replaceDraftItem(_ id: UUID, with name: String) {
        guard var d = draft, let i = d.items.firstIndex(where: { $0.id == id }) else { return }
        let old = d.items[i]
        let kind = Catalog.kind(name)
        let oldKind = Catalog.kind(old.name)
        d.items[i].name = name
        if kind != oldKind {
            d.items[i].sets = kind == .cardio ? 1 : max(1, old.sets)
            d.items[i].reps = kind == .cardio ? 10 : (oldKind == .cardio ? 8 : old.reps)
            d.items[i].repsMax = kind == .cardio ? nil : old.repsMax
        }
        d.items[i].w = Catalog.info(name).defaultWeight
        draft = d
        draftSwapID = nil
        sheet = nil
    }

    func removeMachine(_ id: String) {
        mutateGym { $0.equipment.removeAll { $0.id == id } }
        sheet = nil
    }

    func addGym(name: String) {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        let g = GymSetup(id: UUID().uuidString, name: n, equipment: [])
        gyms.append(g)
        gymID = g.id
        sheet = nil
        applyGym()
        save()
    }

    func renameGym(_ id: String, to name: String) {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty, let i = gyms.firstIndex(where: { $0.id == id }) else { return }
        gyms[i].name = n
        save()
    }

    func deleteGym(_ id: String) {
        guard gyms.count > 1 else { return }
        gyms.removeAll { $0.id == id }
        if gymID == id { gymID = gyms[0].id }
        sheet = nil
        applyGym()
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

    // MARK: Creatine

    static func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    var creaDoneToday: Bool { creaDone.contains(AppModel.dayKey(Date())) }

    func setCreatine(_ on: Bool) {
        crea = on
        if on { Notifier.requestAuthorizationIfNeeded() }
        rescheduleCreatine()
        save()
    }

    /// Vanuit de melding ("Gehad"): vink vandaag af zonder de app te openen.
    func markCreaDoneFromNotification() {
        let key = AppModel.dayKey(Date())
        if !creaDone.contains(key) { creaDone.append(key) }
        rescheduleCreatine()
        save()
    }

    func toggleCreaDone() {
        let key = AppModel.dayKey(Date())
        if let i = creaDone.firstIndex(of: key) { creaDone.remove(at: i) } else { creaDone.append(key) }
        if creaDone.count > 60 { creaDone.removeFirst(creaDone.count - 60) }
        Haptics.light()
        rescheduleCreatine()
        save()
    }

    func setCreaTime(_ minutes: Int) {
        creaTime = min(1439, max(0, minutes))
        rescheduleCreatine()
        save()
    }

    /// Weekdag-nummer volgens Calendar: 1 = zondag ... 7 = zaterdag.
    func creaTime(forWeekday d: Int) -> Int { creaDayTime[String(d)] ?? creaTime }
    func creaLateTime(forWeekday d: Int) -> Int { creaDayLate[String(d)] ?? creaLateTime }
    func creaLateOn(forWeekday d: Int) -> Bool { creaLateOn && !creaDayLateOff.contains(d) }
    func creaHasOwnTimes(_ d: Int) -> Bool {
        creaDayTime[String(d)] != nil || creaDayLate[String(d)] != nil || creaDayLateOff.contains(d)
    }

    static let weekdayNames = ["", "Zondag", "Maandag", "Dinsdag", "Woensdag", "Donderdag", "Vrijdag", "Zaterdag"]

    var creaSummary: String {
        if !crea { return "Uit" }
        var t = clockText(creaTime)
        if creaLateOn { t += " en " + clockText(creaLateTime) }
        let off = creaDayOff.count
        if off >= 7 { return "Aan, maar op geen enkele dag" }
        if off > 0 { t += " \u{00B7} \(7 - off) dagen" }
        if creaDayTime.count + creaDayLate.count > 0 { t += " \u{00B7} eigen tijden" }
        return t
    }

    func setCreaDay(_ d: Int, on: Bool) {
        if on { creaDayOff.removeAll { $0 == d } } else if !creaDayOff.contains(d) { creaDayOff.append(d) }
        rescheduleCreatine()
        save()
    }

    func setCreaDayTime(_ d: Int, minutes: Int) {
        creaDayTime[String(d)] = min(1439, max(0, minutes))
        rescheduleCreatine()
        save()
    }

    func setCreaDayLate(_ d: Int, minutes: Int) {
        creaDayLate[String(d)] = min(1439, max(0, minutes))
        rescheduleCreatine()
        save()
    }

    func setCreaDayLate(_ d: Int, on: Bool) {
        if on { creaDayLateOff.removeAll { $0 == d } } else if !creaDayLateOff.contains(d) { creaDayLateOff.append(d) }
        rescheduleCreatine()
        save()
    }

    func resetCreaDay(_ d: Int) {
        creaDayTime[String(d)] = nil
        creaDayLate[String(d)] = nil
        creaDayLateOff.removeAll { $0 == d }
        rescheduleCreatine()
        save()
    }

    func setCreaLate(on: Bool) {
        creaLateOn = on
        rescheduleCreatine()
        save()
    }

    func setCreaLateTime(_ minutes: Int) {
        creaLateTime = min(1439, max(0, minutes))
        rescheduleCreatine()
        save()
    }

    /// Plant de komende 14 dagen. Een dag die je hebt afgevinkt krijgt geen herinnering meer.
    func rescheduleCreatine() {
        Notifier.scheduleCreatine(on: crea, time: creaTime, lateOn: creaLateOn, lateTime: creaLateTime, doneDays: creaDone, offDays: creaDayOff, dayTimes: creaDayTime, dayLateTimes: creaDayLate, lateOffDays: creaDayLateOff)
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
    static let creatineCategory = "CREATINE"
    static let takenAction = "CREATINE_TAKEN"
    static let laterAction = "CREATINE_LATER"
    /// Wordt door de app gezet; draait wanneer je in de melding op "Gehad" tikt.
    static var onCreatineTaken: (() -> Void)?

    /// Knoppen onder de creatine-melding: "Gehad" haalt de tweede herinnering weg, "Later" laat hem staan.
    static func registerCategories() {
        let taken = UNNotificationAction(identifier: takenAction, title: "Gehad", options: [])
        let later = UNNotificationAction(identifier: laterAction, title: "Later", options: [])
        let category = UNNotificationCategory(identifier: creatineCategory, actions: [taken, later], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

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

    static func scheduleStale(after seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Workout nog bezig?"
        content.body = "Je laatste set was een tijd geleden. Open Set om hem af te sluiten."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "stale", content: content, trigger: trigger))
    }

    static func cancelStale() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["stale"])
    }

    static func cancelRest() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest"])
    }

    static func scheduleCreatine(on: Bool, time: Int, lateOn: Bool, lateTime: Int, doneDays: [String], offDays: [Int] = [], dayTimes: [String: Int] = [:], dayLateTimes: [String: Int] = [:], lateOffDays: [Int] = []) {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        let center = UNUserNotificationCenter.current()
        var ids = ["creatine"]
        for i in 0..<14 { ids.append("creatine-a-\(i)"); ids.append("creatine-b-\(i)") }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        guard on else { return }
        let cal = Calendar.current
        let now = Date()
        let start = cal.startOfDay(for: now)
        for i in 0..<14 {
            guard let day = cal.date(byAdding: .day, value: i, to: start) else { continue }
            if doneDays.contains(AppModel.dayKey(day)) { continue }
            let weekday = cal.component(.weekday, from: day)
            if offDays.contains(weekday) { continue }
            let first = dayTimes[String(weekday)] ?? time
            let late = dayLateTimes[String(weekday)] ?? lateTime
            add(center, id: "creatine-a-\(i)", day: day, minutes: first, body: "Tijd voor je creatine.", now: now)
            if lateOn && !lateOffDays.contains(weekday) && late > first {
                add(center, id: "creatine-b-\(i)", day: day, minutes: late, body: "Creatine nog niet gehad? Pak hem bij het avondeten.", now: now)
            }
        }
    }

    private static func add(_ center: UNUserNotificationCenter, id: String, day: Date, minutes: Int, body: String, now: Date) {
        let cal = Calendar.current
        guard let fire = cal.date(byAdding: .minute, value: minutes, to: day), fire > now else { return }
        let content = UNMutableNotificationContent()
        content.title = "Creatine"
        content.body = body
        content.sound = .default
        content.categoryIdentifier = creatineCategory
        let parts = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}


extension Draft {
    /// Opeenvolgende gekoppelde oefeningen (superset) vormen een blok.
    var blocks: [[DraftItem]] {
        var out: [[DraftItem]] = []
        for (i, it) in items.enumerated() {
            if i > 0, it.link, it.blockKind == 1, items[i - 1].blockKind == 1, !out.isEmpty {
                out[out.count - 1].append(it)
            } else {
                out.append([it])
            }
        }
        return out
    }
}
