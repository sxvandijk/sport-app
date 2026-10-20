import Foundation

/// Launch-argumenten waarmee CI schermen kan fotograferen, bijvoorbeeld:
/// `-screenshotScreen workout-rest -screenshotAppearance dark -screenshotAccent viola`.
/// Zonder `-screenshotScreen` gedraagt de app zich gewoon.
struct LaunchConfig {
    var screen: String?
    var appearance: AppearanceMode?
    var accent: AccentID?

    var isScreenshotRun: Bool { screen != nil }

    init(defaults: UserDefaults = .standard) {
        screen = defaults.string(forKey: "screenshotScreen")
        appearance = defaults.string(forKey: "screenshotAppearance").flatMap(AppearanceMode.init(rawValue:))
        accent = defaults.string(forKey: "screenshotAccent").flatMap(AccentID.init(rawValue:))
    }

    /// Zet de app in de gevraagde stand (zelfde beginstand als het prototype: Push A, 23:14 bezig).
    func apply(to model: AppModel, now: Date = Date()) {
        if let appearance = appearance { model.themeMode = appearance }
        if let accent = accent { model.accent = accent }
        guard let screen = screen else { return }
        if !screen.hasSuffix("-empty") {
            model.history = ScreenshotScenario.history(templates: model.templates, now: now)
        }

        if screen.contains("acc") {
            model.exAcc = ["Cable One Arm Tricep Extension": ["Touw", "Rechte stang"]]
            model.applyGym()
        }
        let needsSession = screen.hasPrefix("workout") || screen.hasPrefix("sheet-") || screen == "training-running"
        if needsSession {
            model.session = ScreenshotScenario.session(now: now, templates: model.templates, history: model.history)
        }

        if ["gym", "sheet-gym", "sheet-machineadd", "sheet-machineedit"].contains(screen) {
            let picks = MachineDB.all.filter { $0.brand == "Technogym" && ["Chest press", "Lat pulldown", "Leg press"].contains($0.name) }
                + MachineDB.all.filter { $0.brand == "Matrix" && $0.name == "Shoulder press" }
            model.gyms[0].equipment = picks.map { GymMachine(model: $0) }
            model.gyms[0].name = "Mijn sportschool"
            model.applyGym()
        }
        switch screen {
        case "start": model.tab = .start
        case "training": model.tab = .training
        case "training-running": model.tab = .training
        case "calendar-open":
            model.tab = .training
            model.calOpen = true
        case "progress": model.tab = .progress
        case "progress-empty": model.tab = .progress
        case "records": model.screen = .records
        case "allworkouts": model.screen = .allWorkouts
        case "weekplan":
            model.weekPlan = ["2": "Push", "4": "Pull", "6": "Legs"]
            if let name = model.program.workouts.first { model.weekOverrides[AppModel.dateKey(Date())] = name }
            model.screen = .weekPlan
        case "workoutdetail":
            model.detailID = model.history.sorted { $0.date > $1.date }.first(where: { !($0.exercises ?? []).isEmpty })?.id
            model.screen = .workoutDetail
        case "creatine": model.screen = .creatine; model.crea = true
        case "training-empty": model.tab = .training
        case "gym": model.tab = .gym
        case "profile": model.tab = .profile
        case "settings-training": model.profileSub = .training; model.screen = .settings
        case "settings-notifications": model.profileSub = .notifications; model.screen = .settings
        case "workout": model.screen = .workout
        case "workout-rest":
            model.screen = .workout
            model.restTotal = 90
            model.restEnd = now.addingTimeInterval(64)
            model.lastSetAt = now.addingTimeInterval(-26)
        case "workout-acc", "workout-side":
            model.screen = .workout
            if let s = model.session, let target = s.exercises.first(where: { $0.name == "Cable One Arm Tricep Extension" }) {
                model.focusID = target.id
            }
        case "workout-superset":
            model.screen = .workout
            if let s = model.session, let target = s.exercises.first(where: { $0.name == "Dumbbell Shoulder Press" }) {
                model.focusID = target.id
            }
        case "workout-toast":
            model.screen = .workout
            if let s = model.session, let ex = s.exercises.first(where: { !$0.name.isEmpty }), let set = ex.sets.last {
                model.deleteSet(exID: ex.id, setID: set.id)
            }
        case "workout-done":
            model.screen = .workout
            if var s = model.session {
                for e in s.exercises.indices {
                    for i in s.exercises[e].sets.indices { s.exercises[e].sets[i].done = true }
                }
                model.session = s
            }
        case "workout-numpad":
            model.screen = .workout
            model.editField = .weight
        case "workout-split":
            model.screen = .workout
            if var s = model.session, let i = s.exercises.firstIndex(where: { Catalog.kind($0.name) == .weights && $0.sets.contains(where: { $0.type != .warmup }) }) {
                s.exercises[i].uni = true
                s.exercises[i].splitW = true
                for k in s.exercises[i].sets.indices where s.exercises[i].sets[k].type != .warmup {
                    s.exercises[i].sets[k].r2 = s.exercises[i].sets[k].r - 1
                    s.exercises[i].sets[k].w2 = s.exercises[i].sets[k].w - 2.5
                    s.exercises[i].sets[k].done = false
                }
                model.focusID = s.exercises[i].id
                model.session = s
            }
        case "summary-added":
            model.summary = ScreenshotScenario.summary(templates: model.templates, now: now)
            model.summaryAdded = ["Lopen", "Cable crunch", "Face pull"].map { PlanItem(name: $0, group: 0, sets: [PlanSet(w: 20, r: 10, rmax: nil)]) }
            model.summaryUnpicked = ["Cable crunch"]
            model.summaryTemplate = "Push"
            model.screen = .summary
        case "workout-select":
            model.screen = .workout
            if let s = model.session, let ex = s.exercises.first, let set = ex.sets.first {
                model.selectSet(exID: ex.id, setID: set.id)
            }
        case "overview":
            ScreenshotScenario.addWarmup(to: model)
            model.screen = .overview
            model.ovName = "Push"
        case "editor":
            ScreenshotScenario.addWarmup(to: model)
            model.draft = Draft(name: "Push", plans: model.templates["Push"] ?? [])
            model.edReturn = .overview
            model.screen = .editor
        case "summary":
            model.summary = ScreenshotScenario.summary(templates: model.templates, now: now)
            model.screen = .summary
        default:
            if screen.hasPrefix("sheet-") { applySheet(String(screen.dropFirst(6)), to: model) }
        }
    }

    private func applySheet(_ name: String, to model: AppModel) {
        let current = model.current().cur
        let exID = current?.exID
        switch name {
        case "menu":
            model.screen = .workout
            model.openSheet(.menu)
        case "stop":
            model.screen = .workout
            model.openSheet(.stop)
        case "start":
            model.askStart("Pull")
        case "explain":
            model.screen = .workout
            model.openSheet(.explain, exID: exID)
        case "swap":
            model.screen = .workout
            model.openSheet(.swap, exID: exID)
        case "superset":
            model.screen = .workout
            model.openSheet(.superset, exID: exID)
        case "add":
            model.screen = .workout
            model.openSheet(.add)
        case "settype":
            model.screen = .workout
            model.openSheet(.settype, exID: exID, setID: current?.setID)
        case "exmenu":
            model.screen = .workout
            model.openSheet(.exmenu, exID: exID)
        case "accuse", "accpick":
            model.screen = .workout
            let target = model.session?.exercises.first(where: { $0.name == "Cable One Arm Tricep Extension" })?.id
            model.openSheet(name == "accuse" ? .accuse : .accpick, exID: target)
        case "sidemode":
            model.screen = .workout
            let target = model.session?.exercises.first(where: { $0.name == "Cable One Arm Tricep Extension" })?.id
            model.openSheet(.sidemode, exID: target)
        case "accedit":
            model.accEditID = model.gym.accessoryList.first?.id
            model.openSheet(.accedit)
        case "weekplan":
            model.weekPlan = ["2": "Push", "4": "Pull", "6": "Legs"]
            model.screen = .weekPlan
        case "gym":
            model.openSheet(.gym)
        case "machineadd":
            model.openSheet(.machineadd)
        case "machineedit":
            model.machineEditID = model.gym.equipment.first?.id
            model.openSheet(.machineedit)
        case "program":
            model.openSheet(.program)
        case "tplmenu":
            model.tmName = "Push"
            model.openSheet(.tplmenu)
        default:
            break
        }
    }
}

/// De beginstand van het prototype, zodat screenshots met het prototype te vergelijken zijn.
enum ScreenshotScenario {
    /// Zes weken voorbeeldtrainingen (alleen voor screenshots): om de dag Push, Pull, Legs, Upper met een beetje progressie.
    static func history(templates: [String: [PlanItem]], now: Date) -> [HistoryEntry] {
        let cal = Calendar.current
        let order = ["Push", "Pull", "Legs", "Upper"]
        var out: [HistoryEntry] = []
        var day = 2
        var n = 0
        while day <= 42 {
            let name = order[n % 4]
            let date = cal.date(byAdding: .hour, value: 18, to: cal.date(byAdding: .day, value: -day, to: cal.startOfDay(for: now)) ?? now) ?? now
            var logged: [LoggedExercise] = []
            let bump = Double(max(0, 12 - n)) * 0.25
            for item in templates[name] ?? [] {
                let sets = item.sets.map { LoggedSet(w: max(0, $0.w - bump), r: $0.r, type: .work) }
                logged.append(LoggedExercise(name: item.name, sets: sets))
            }
            out.append(HistoryEntry(date: date, name: name, minutes: 45 + (n * 7) % 20, exercises: logged))
            day += (n % 3 == 2) ? 3 : 2
            n += 1
        }
        return out
    }

    static func session(now: Date, templates: [String: [PlanItem]], history: [HistoryEntry] = []) -> LiveSession {
        var s = LiveSession.make(name: "Push", startAt: now.addingTimeInterval(-(23 * 60 + 14)), templates: templates, history: history)
        let off = 0
        if s.exercises.count >= 3 + off {
            for i in s.exercises[off].sets.indices { s.exercises[off].sets[i].done = true }
            if s.exercises[off].sets.count > 3 { s.exercises[off].sets[3].r = 8 }
            s.exercises[off + 1].sets[0].done = true
            s.exercises[off + 1].sets[1].done = true
            s.exercises[off + 2].sets[0].done = true
        }
        return s
    }

    /// Voorbeeld-warming-up (rotator cuff) vooraan in Push, voor de schermen die het blok tonen.
    static func addWarmup(to model: AppModel) {
        var plans = model.templates["Push"] ?? []
        if plans.contains(where: { $0.isWarmup == true }) { return }
        var item = PlanItem(name: "Rotator cuff external rotation", group: 0,
                            sets: [PlanSet(w: 2.5, r: 15, rmax: nil), PlanSet(w: 2.5, r: 15, rmax: nil)])
        item.isWarmup = true
        plans.insert(item, at: 0)
        var cool = PlanItem(name: "Fietsen", group: 99, sets: [PlanSet(w: 0, r: 5, rmax: nil)])
        cool.isCooldown = true
        plans.append(cool)
        model.templates["Push"] = plans
    }

    static func summary(templates: [String: [PlanItem]], now: Date) -> SessionSummary {
        var s = session(now: now.addingTimeInterval(-(31 * 60)), templates: templates)
        for e in s.exercises.indices {
            for i in s.exercises[e].sets.indices { s.exercises[e].sets[i].done = true }
        }
        return s.finishSummary(now: now, note: nil).summary
    }
}
