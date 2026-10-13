import Foundation

/// Schat de resterende trainingstijd uit de openstaande sets en de rusttijden.
struct DurationEstimator {
    /// Gemiddelde duur van één set (uitvoeren + invoeren). Wordt gekalibreerd uit je historie.
    var assumedSetSeconds: TimeInterval = 45

    struct Estimate: Equatable {
        var elapsed: TimeInterval
        var remaining: TimeInterval
        var total: TimeInterval { elapsed + remaining }
    }

    func estimate(for session: ActiveWorkoutSession, at now: Date = Date()) -> Estimate {
        Estimate(elapsed: session.elapsed(at: now), remaining: remainingTime(for: session))
    }

    /// Resterende tijd:
    /// - gewone oefening: open sets × (setduur + rust)
    /// - superset: alle open sets × setduur + (aantal rondes × rust), want er is alleen rust na de laatste oefening van elke ronde
    /// - warm-up sets rekenen met halve rust
    /// - de rust ná de allerlaatste set telt niet mee
    func remainingTime(for session: ActiveWorkoutSession) -> TimeInterval {
        var total: TimeInterval = 0
        var trailingRest: TimeInterval = 0

        for block in session.blocks {
            let pendingWorking = block.exercises.map { exercise in
                exercise.sets.filter { !$0.isCompleted && !$0.isWarmup }.count
            }
            let pendingWarmup = block.exercises.map { exercise in
                exercise.sets.filter { !$0.isCompleted && $0.isWarmup }.count
            }
            let pendingTotal = pendingWorking.reduce(0, +) + pendingWarmup.reduce(0, +)
            guard pendingTotal > 0 else { continue }

            let rest = TimeInterval(block.exercises.last?.restSeconds ?? 0)
            var blockTime = Double(pendingTotal) * assumedSetSeconds

            if block.isSuperset {
                let rounds = pendingWorking.max() ?? 0
                blockTime += Double(rounds) * rest
                trailingRest = rounds > 0 ? rest : rest * 0.5
            } else {
                let working = Double(pendingWorking[0])
                let warmup = Double(pendingWarmup[0])
                blockTime += working * rest + warmup * rest * 0.5
                trailingRest = working > 0 ? rest : rest * 0.5
            }
            total += blockTime
        }
        return max(0, total - trailingRest)
    }

    /// Kalibreert de setduur uit eerdere workouts: mediaan van (tijd tussen twee sets − ingestelde rust),
    /// alleen bij gewone oefeningen. Geeft nil bij te weinig data.
    static func calibratedSetSeconds(from history: [ActiveWorkoutSession], minimumSamples: Int = 10) -> TimeInterval? {
        var samples: [TimeInterval] = []
        for session in history {
            for block in session.blocks where !block.isSuperset {
                guard let exercise = block.exercises.first else { continue }
                let stamps = exercise.sets
                    .filter { $0.isCompleted && !$0.isWarmup }
                    .compactMap { $0.timestamp }
                    .sorted()
                for (a, b) in zip(stamps, stamps.dropFirst()) {
                    let seconds = b.timeIntervalSince(a) - TimeInterval(exercise.restSeconds)
                    if seconds > 5 && seconds < 240 { samples.append(seconds) }
                }
            }
        }
        guard samples.count >= minimumSamples else { return nil }
        let sorted = samples.sorted()
        let median = sorted[sorted.count / 2]
        return min(max(median, 20), 120)
    }
}
