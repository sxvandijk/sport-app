import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Start, ververst en beëindigt de Live Activity van de lopende training.
/// Op iOS 16.2 en nieuwer; op oudere versies gebeurt er niets.
enum LiveActivityManager {
    /// Laatste melding van het systeem, om te kunnen zien waarom er niets verschijnt.
    static var lastError: String?

    /// Korte regels voor het statusblokje in het profiel.
    static func diagnose() -> [String] {
        var lines: [String] = []
        let dir = Bundle.main.builtInPlugInsPath
        let names = dir.flatMap { try? FileManager.default.contentsOfDirectory(atPath: $0) } ?? []
        lines.append(names.isEmpty ? "Widget-extensie: niet in de app gevonden" : "Widget-extensie: \(names.joined(separator: ", "))")
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            lines.append("Live Activities in Instellingen: " + (ActivityAuthorizationInfo().areActivitiesEnabled ? "aan" : "uit"))
            lines.append("Actieve activiteiten: \(Activity<WorkoutActivityAttributes>.activities.count)")
        } else {
            lines.append("Live Activities vragen iOS 16.2 of nieuwer")
        }
        #endif
        lines.append("Laatste melding: " + (lastError ?? "geen"))
        return lines
    }

    static func sync(name: String?, startAt: Date?, state: WorkoutLiveState?) {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            Impl.sync(name: name, startAt: startAt, state: state)
        }
        #endif
    }

    #if canImport(ActivityKit)
    @available(iOS 16.2, *)
    private enum Impl {
        static var last: WorkoutLiveState?

        static func sync(name: String?, startAt: Date?, state: WorkoutLiveState?) {
            guard let name = name, let startAt = startAt, let state = state else {
                endAll()
                return
            }
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                LiveActivityManager.lastError = "Live Activities staan uit voor deze app"
                return
            }
            let content = ActivityContent(state: state, staleDate: nil)
            let running = Activity<WorkoutActivityAttributes>.activities
            if let current = running.first(where: { abs($0.attributes.startAt.timeIntervalSince(startAt)) < 1 }) {
                guard state != last else { return }
                last = state
                Task { await current.update(content) }
            } else {
                endAll()
                last = state
                do {
                    _ = try Activity.request(attributes: WorkoutActivityAttributes(name: name, startAt: startAt),
                                             content: content, pushType: nil)
                    LiveActivityManager.lastError = nil
                } catch {
                    LiveActivityManager.lastError = String(describing: error)
                }
            }
        }

        static func endAll() {
            last = nil
            for activity in Activity<WorkoutActivityAttributes>.activities {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }
        }
    }
    #endif
}
