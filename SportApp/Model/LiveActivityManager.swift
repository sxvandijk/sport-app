import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Start, ververst en beëindigt de Live Activity van de lopende training.
/// Op iOS 16.2 en nieuwer; op oudere versies gebeurt er niets.
enum LiveActivityManager {
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
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            let content = ActivityContent(state: state, staleDate: nil)
            let running = Activity<WorkoutActivityAttributes>.activities
            if let current = running.first(where: { abs($0.attributes.startAt.timeIntervalSince(startAt)) < 1 }) {
                guard state != last else { return }
                last = state
                Task { await current.update(content) }
            } else {
                endAll()
                last = state
                _ = try? Activity.request(attributes: WorkoutActivityAttributes(name: name, startAt: startAt),
                                          content: content, pushType: nil)
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
