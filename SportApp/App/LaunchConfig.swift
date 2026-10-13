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

        let needsSession = screen.hasPrefix("workout") || screen.hasPrefix("sheet-") || screen == "training-running"
        if needsSession {
            model.session = ScreenshotScenario.session(now: now, templates: model.templates)
        }

        switch screen {
        case "training": model.tab = .training
        case "training-running": model.tab = .training
        case "calendar-open":
            model.tab = .training
            model.calOpen = true
        case "progress": model.tab = .progress
        case "gym": model.tab = .gym
        case "profile": model.tab = .profile
        case "workout": model.screen = .workout
        case "workout-rest":
            model.screen = .workout
            model.restTotal = 90
            model.restEnd = now.addingTimeInterval(64)
        case "workout-superset":
            model.screen = .workout
            if let s = model.session, let target = s.exercises.first(where: { $0.name == "Chest press machine" }) {
                model.focusID = target.id
            }
        case "workout-toast":
            model.screen = .workout
            if let s = model.session, let ex = s.exercises.first, let set = ex.sets.last {
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
        case "overview":
            model.screen = .overview
            model.ovName = "Push A"
        case "editor":
            model.draft = Draft(name: "Push A", plans: model.templates["Push A"] ?? [])
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
            model.askStart("Pull A")
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
        case "gym":
            model.openSheet(.gym)
        case "program":
            model.openSheet(.program)
        case "tplmenu":
            model.tmName = "Push A"
            model.openSheet(.tplmenu)
        default:
            break
        }
    }
}

/// De beginstand van het prototype, zodat screenshots met het prototype te vergelijken zijn.
enum ScreenshotScenario {
    static func session(now: Date, templates: [String: [PlanItem]]) -> LiveSession {
        var s = LiveSession.make(name: "Push A", startAt: now.addingTimeInterval(-(23 * 60 + 14)), templates: templates)
        if s.exercises.count >= 3 {
            for i in s.exercises[0].sets.indices { s.exercises[0].sets[i].done = true }
            if s.exercises[0].sets.count > 3 { s.exercises[0].sets[3].r = 8 }
            s.exercises[1].sets[0].done = true
            s.exercises[1].sets[1].done = true
            s.exercises[2].sets[0].done = true
        }
        return s
    }

    static func summary(templates: [String: [PlanItem]], now: Date) -> SessionSummary {
        var s = session(now: now.addingTimeInterval(-(31 * 60)), templates: templates)
        for e in s.exercises.indices {
            for i in s.exercises[e].sets.indices { s.exercises[e].sets[i].done = true }
        }
        return s.finishSummary(now: now, note: nil).summary
    }
}
