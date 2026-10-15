import SwiftUI
import WidgetKit
import ActivityKit

private func liveAccent(_ hex: Int) -> Color {
    Color(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
          blue: Double(hex & 0xFF) / 255, opacity: 1)
}

/// Rusttijd aftellend, anders de tijd die de training al duurt.
private struct TimerText: View {
    let startAt: Date
    let state: WorkoutLiveState

    var body: some View {
        let now = Date()
        if let end = state.restEnd, end > now.addingTimeInterval(0.5) {
            Text(timerInterval: now...end, pauseTime: nil, countsDown: true, showsHours: false)
                .monospacedDigit()
                .foregroundColor(liveAccent(state.accent))
        } else {
            Text(startAt, style: .timer)
                .monospacedDigit()
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        let state = context.state
        let resting = (state.restEnd ?? .distantPast) > Date()
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.name).font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(resting ? "Rust" : state.exercise).font(.system(size: 20, weight: .bold)).lineLimit(1)
                }
                Spacer(minLength: 8)
                TimerText(startAt: context.attributes.startAt, state: state)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
            }
            ProgressView(value: Double(state.done), total: Double(max(state.total, 1)))
                .tint(liveAccent(state.accent))
            HStack {
                Text(resting ? "Straks: \(state.exercise)" : state.setText)
                    .font(.system(size: 13)).foregroundColor(.secondary).lineLimit(1)
                Spacer()
                Text("\(state.done) van \(state.total) sets").font(.system(size: 13)).foregroundColor(.secondary)
            }
        }
        .padding(16)
    }
}

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let state = context.state
            let color = liveAccent(state.accent)
            let resting = (state.restEnd ?? .distantPast) > Date()
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.name).font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                        Text(resting ? "Rust" : state.exercise).font(.system(size: 16, weight: .bold)).lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(startAt: context.attributes.startAt, state: state)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: Double(state.done), total: Double(max(state.total, 1))).tint(color)
                        HStack {
                            Text(resting ? "Straks: \(state.exercise)" : state.setText).font(.system(size: 12))
                                .foregroundColor(.secondary).lineLimit(1)
                            Spacer()
                            Text("\(state.done) van \(state.total) sets").font(.system(size: 12)).foregroundColor(.secondary)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill").foregroundColor(color)
            } compactTrailing: {
                TimerText(startAt: context.attributes.startAt, state: state)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "dumbbell.fill").foregroundColor(color)
            }
        }
    }
}
