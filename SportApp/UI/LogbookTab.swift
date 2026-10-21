import SwiftUI

/// Tab Logboek: je afgeronde trainingen als feed, per week gegroepeerd.
/// Later kunnen hier ook trainingen van vrienden tussen staan (zie DESIGN.md 6.11).
struct LogbookTab: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @State private var filter: String?
    @State private var onlyPRs = false
    @State private var limit = 15

    private struct WeekGroup: Identifiable {
        let id: Date
        let title: String
        let entries: [HistoryEntry]
    }

    var body: some View {
        let stats = ProgressStats.make(history: model.history, now: Date())
        let prDates = Dictionary(grouping: stats.records, by: { $0.date })
        let names = Array(Set(model.history.map { $0.name })).sorted()
        let all = model.history.sorted { $0.date > $1.date }
        let shown = all.filter { h in
            (filter == nil || h.name == filter) && (!onlyPRs || prDates[h.date] != nil)
        }
        let visible = Array(shown.prefix(limit))

        VStack(alignment: .leading, spacing: 0) {
            Text(all.isEmpty ? "Je trainingen" : "\(all.count) \(all.count == 1 ? "training" : "trainingen")")
                .sa(13, .medium, mono: true).foregroundColor(Tokens.text2)
                .frame(height: 44, alignment: .leading)
            ScreenTitle(text: "Logboek")

            if !all.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip("Alles", on: filter == nil && !onlyPRs) { filter = nil; onlyPRs = false }
                        chip("PR\u{2019}s", on: onlyPRs) { onlyPRs.toggle() }
                        ForEach(names, id: \.self) { n in
                            chip(n, on: filter == n) { filter = filter == n ? nil : n }
                        }
                    }
                    .padding(.horizontal, Spacing.screenMargin)
                }
                .padding(.horizontal, -Spacing.screenMargin)
                .padding(.top, 14)
            }

            if all.isEmpty {
                emptyCard("Nog geen trainingen", "Rond je eerste workout af, dan staat hij hier met je volume, sets en records.")
            } else if shown.isEmpty {
                emptyCard("Niets gevonden", "Geen trainingen met dit filter.")
            }

            ForEach(groups(visible)) { group in
                HStack(alignment: .firstTextBaseline) {
                    SectionLabel(text: group.title)
                    Spacer(minLength: 0)
                    Text(weekSummary(group.entries)).sa(12, .regular, mono: true).foregroundColor(Tokens.text3)
                }
                .padding(.top, 22).padding(.bottom, 8)
                ForEach(group.entries) { h in
                    Button {
                        model.detailID = h.id
                        model.detailReturn = .home
                        model.screen = .workoutDetail
                    } label: {
                        LogbookCard(entry: h, prNames: Set((prDates[h.date] ?? []).map { $0.name }))
                    }
                    .buttonStyle(PressScaleStyle(scale: 0.98))
                    .padding(.bottom, 8)
                }
            }

            if shown.count > visible.count {
                Button { withAnimation(Motion.tabContent) { limit += 15 } } label: {
                    Text("Toon meer").sa(15, .semibold).foregroundColor(ac.accentText)
                        .frame(maxWidth: .infinity).frame(height: 48).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .animation(Motion.tabContent, value: filter)
        .animation(Motion.tabContent, value: onlyPRs)
    }

    private func groups(_ entries: [HistoryEntry]) -> [WeekGroup] {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        cal.locale = Locale(identifier: "nl_NL")
        let thisWeek = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        var order: [Date] = []
        var byWeek: [Date: [HistoryEntry]] = [:]
        for h in entries {
            let start = cal.dateInterval(of: .weekOfYear, for: h.date)?.start ?? h.date
            if byWeek[start] == nil { order.append(start) }
            byWeek[start, default: []].append(h)
        }
        return order.map { start in
            let weeksAgo = (cal.dateComponents([.day], from: start, to: thisWeek).day ?? 0) / 7
            let title: String
            switch weeksAgo {
            case ..<1: title = "Deze week"
            case 1: title = "Vorige week"
            default: title = "Week \(cal.component(.weekOfYear, from: start)) \u{00B7} " + DateText.short(start)
            }
            return WeekGroup(id: start, title: title, entries: byWeek[start] ?? [])
        }
    }

    private func weekSummary(_ entries: [HistoryEntry]) -> String {
        let volume = entries.reduce(0) { $0 + ProgressStats.volume(of: $1) }
        return "\(entries.count)\u{00D7} \u{00B7} " + Format.thousands(volume) + " kg"
    }

    private func chip(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(title).sa(14, .medium).lineLimit(1)
                .foregroundColor(on ? ac.onAccent : Tokens.text)
                .padding(.horizontal, 16).frame(height: 40)
                .glassSurface(Capsule(), tint: on ? ac.accent : nil, interactive: true, fallback: on ? ac.accentLine : Tokens.raised)
                .contentShape(Capsule())
        }
        .buttonStyle(PressScaleStyle(scale: 0.94))
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func emptyCard(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).sa(17, .semibold).foregroundColor(Tokens.text)
            Text(text).sa(15).foregroundColor(Tokens.text2).lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: Radius.card)
        .padding(.top, 20)
    }
}

/// Eén training in de feed.
struct LogbookCard: View {
    let entry: HistoryEntry
    /// Oefeningen waarvan dit je record is.
    let prNames: Set<String>

    @Environment(\.accentColors) private var ac

    private var exercises: [LoggedExercise] { entry.exercises ?? [] }

    private var workSets: Int {
        exercises.reduce(0) { $0 + $1.countedSets.count }
    }

    private func summary(_ e: LoggedExercise) -> String {
        let sets = e.countedSets
        guard !sets.isEmpty else { return "" }
        let kind = Catalog.kind(e.name)
        switch kind {
        case .cardio, .timed:
            return Format.setText(kind, sets[0].w, sets[0].r)
        default:
            let top = sets.map { $0.w }.max() ?? 0
            if top <= 0 { return "\(sets.count) \u{00D7} \(sets.map { $0.r }.max() ?? 0) reps" }
            return "\(sets.count) \u{00D7} " + Format.weight(top) + " kg"
        }
    }

    /// Aandeel per spiergroep (op aantal sets), grootste eerst.
    private var muscleShare: [(muscle: String, fraction: Double)] {
        var counts: [String: Int] = [:]
        for e in exercises {
            let muscle = Catalog.info(e.name).muscle
            if muscle == "Cardio" || muscle == "Overig" { continue }
            counts[muscle, default: 0] += e.countedSets.count
        }
        let total = max(counts.values.reduce(0, +), 1)
        return counts.map { (muscle: $0.key, fraction: Double($0.value) / Double(total)) }
            .sorted { $0.fraction != $1.fraction ? $0.fraction > $1.fraction : $0.muscle < $1.muscle }
    }

    var body: some View {
        let shares = Array(muscleShare.prefix(4))
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name).sa(20, .bold, tracking: -0.3).foregroundColor(Tokens.text).lineLimit(1)
                    Text(DateText.short(entry.date) + " \u{00B7} " + Format.hhmm(entry.date)).sa(13).foregroundColor(Tokens.text2)
                }
                Spacer(minLength: 0)
                if !prNames.isEmpty {
                    HStack(spacing: 4) {
                        Icon.starFilled(13)
                        Text(prNames.count == 1 ? "PR" : "\(prNames.count) PR\u{2019}s").sa(12, .bold)
                    }
                    .foregroundColor(ac.accentText)
                    .padding(.horizontal, 10).frame(height: 26)
                    .background(Capsule().fill(ac.accentSoft))
                }
                Icon.chevronRight(16).foregroundColor(Tokens.text3).padding(.top, 4)
            }

            HStack(spacing: 0) {
                stat(Format.thousands(ProgressStats.volume(of: entry)), "kg")
                stat("\(workSets)", "sets")
                stat("\(entry.minutes)", "min")
            }

            if !exercises.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(exercises.prefix(3).enumerated()), id: \.offset) { _, e in
                        HStack(spacing: 10) {
                            ExerciseThumb(name: e.name, size: 38, radius: 10)
                            if prNames.contains(e.name) {
                                Icon.starFilled(12).foregroundColor(ac.accentText)
                                    .accessibilityLabel("Record")
                            }
                            Text(e.name).sa(15).foregroundColor(Tokens.text).lineLimit(1)
                            Spacer(minLength: 8)
                            Text(summary(e)).sa(14, .regular, mono: true).foregroundColor(Tokens.text2).lineLimit(1)
                        }
                    }
                    if exercises.count > 3 {
                        Text("+ \(exercises.count - 3) \(exercises.count - 3 == 1 ? "oefening" : "oefeningen")")
                            .sa(13).foregroundColor(Tokens.text3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if !shares.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        HStack(spacing: 3) {
                            ForEach(Array(shares.enumerated()), id: \.offset) { i, share in
                                Capsule()
                                    .fill(ac.accentLine.opacity([1, 0.6, 0.38, 0.22][i]))
                                    .frame(width: max(6, geo.size.width * CGFloat(share.fraction) - 3))
                            }
                        }
                    }
                    .frame(height: 6)
                    Text(shares.prefix(2).map { "\($0.muscle) \(Int(($0.fraction * 100).rounded()))%" }.joined(separator: " \u{00B7} "))
                        .sa(12).foregroundColor(Tokens.text3)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: Radius.card)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func stat(_ value: String, _ unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(value).sa(20, .semibold, tracking: -0.3, mono: true).foregroundColor(Tokens.text)
            Text(unit).sa(13).foregroundColor(Tokens.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
