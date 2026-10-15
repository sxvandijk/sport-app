import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Wat de Live Activity (vergrendelscherm en Dynamic Island) van de lopende training laat zien.
/// Dit bestand zit in zowel de app als de widget-extensie.
struct WorkoutLiveState: Codable, Hashable {
    var exercise: String
    var setText: String
    var done: Int
    var total: Int
    /// Einde van de rusttijd; `nil` als je niet aan het rusten bent.
    var restEnd: Date?
    var accent: Int
}

#if canImport(ActivityKit)
@available(iOS 16.1, *)
struct WorkoutActivityAttributes: ActivityAttributes {
    typealias ContentState = WorkoutLiveState
    var name: String
    var startAt: Date
}
#endif
