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

        let needsSession = screen.hasPrefix("workout") || screen.hasPrefix("sheet-") || screen == "training-running"
        if needsSession {
            model.session = ScreenshotScenario.session(now: now, templates: model.templates, history: model.history)
        }

        switch screen {
        case "training": model.tab = .training
        case "training-running": model.tab = .training
        case "calendar-open":
            model.tab = .training
            model.calOpen = true
        case "progress": model.tab = .progress
        case "progress-empty": model.tab = .progress
        case "records": model.screen = .records
        case "training-empty": model.tab = .training
        case "gym": model.tab = .gym
        case "profile": model.tab = .profile
        case "workout": model.screen = .workout
        case "workout-rest":
            model.screen = .workout
            model.restTotal = 90
            model.restEnd = now.addingTimeInterval(64)
            model.lastSetAt = now.addingTimeInterval(-26)
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
        case "gym":
            model.openSheet(.gym)
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
