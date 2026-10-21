import SwiftUI

/// Groot scherm bij een oefening in je workout: afbeelding, jouw beste set en alle vorige keren met hun sets.
struct ExerciseDetailScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    private var name: String { model.exerciseDetailName }

    private func setText(_ s: LoggedSet, _ kind: ExerciseKind) -> String {
        switch kind {
        case .weights: return Format.weight(s.w) + " kg \u{00D7} " + s.repsText
        case .bodyweight: return s.w == 0 ? s.repsText + " reps" : "+" + Format.weight(s.w) + " kg \u{00D7} " + s.repsText
        case .cardio, .timed: return Format.setText(kind, s.w, s.r)
        }
    }

    /// De zwaarste (of langste) werkset uit alle keren.
    private func best(_ all: [(date: Date, workout: String, exercise: LoggedExercise)], _ kind: ExerciseKind) -> LoggedSet? {
        let sets = all.flatMap { $0.exercise.sets }.filter { $0.type != .warmup }
        switch kind {
        case .weights: return sets.max { ($0.w, $0.r) < ($1.w, $1.r) }
        case .bodyweight: return sets.max { ($0.w, $0.r) < ($1.w, $1.r) }
        case .cardio, .timed: return sets.max { $0.r < $1.r }
        }
    }

    private func today() -> LoggedExercise? {
        guard let ex = model.session?.exercises.first(where: { $0.name == name }) else { return nil }
        let done = ex.sets.filter { $0.done }.map { LoggedSet(w: $0.w, r: $0.r, type: $0.type, r2: $0.r2, m: nil) }
        return done.isEmpty ? nil : LoggedExercise(name: name, sets: done, uni: ex.uni, two: nil, acc: ex.acc, blk: ex.blk)
    }

    var body: some View {
        let kind = Catalog.kind(name)
        let all = LiveSession.performances(of: name, in: model.history, limit: 10_000)
        VStack(spacing: 0) {
            HStack {
                Button { model.screen = model.exerciseDetailReturn } label: {
                    HStack(spacing: 2) {
                        Icon.chevronLeft(22)
                        Text(model.exerciseDetailReturn == .summary ? "Terug" : "Workout").sa(17)
                    }
                    .foregroundColor(ac.accentText)
                    .padding(.leading, 4).padding(.trailing, 10).frame(height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 6).frame(height: 52)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ExerciseHero(name: name, height: 250)
                    Text(name).sa(30, .bold, tracking: -0.5).foregroundColor(Tokens.text)
                        .lineLimit(3).minimumScaleFactor(0.75)
                        .padding(.top, 18)
                        .accessibilityAddTraits(.isHeader)
                    Text(Catalog.meta(name)).sa(15).foregroundColor(Tokens.text2).padding(.top, 2)

                    HStack(spacing: 0) {
                        stat(all.isEmpty ? "\u{2013}" : "\(all.count)\u{00D7}", "gedaan")
                        divider
                        stat(best(all, kind).map { setText($0, kind) } ?? "\u{2013}", "beste set")
                        divider
                        stat(all.first.map { DateText.short($0.date) } ?? "\u{2013}", "laatste keer")
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .glassCard(radius: Radius.card)
                    .padding(.top, 20)

                    if let t = today() {
                        SectionLabel(text: "Vandaag").padding(.top, 26).padding(.bottom, 10)
                        card(title: "Deze workout", sub: model.session?.name ?? "", e: t, kind: kind, highlight: true)
                    }

                    SectionLabel(text: "Vorige keren").padding(.top, 26).padding(.bottom, 10)
                    if all.isEmpty {
                        Text("Je hebt deze oefening nog niet eerder gedaan.").sa(15).foregroundColor(Tokens.text2)
                    }
                    VStack(spacing: 10) {
                        ForEach(0..<all.count, id: \.self) { i in
                            card(title: DateText.short(all[i].date), sub: all[i].workout, e: all[i].exercise, kind: kind, highlight: false)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(AppBackground())
    }

    private var divider: some View { Rectangle().fill(Tokens.line).frame(width: 1, height: 36) }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).sa(18, .semibold, mono: true).foregroundColor(Tokens.text).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).sa(13).foregroundColor(Tokens.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }

    private func card(title: String, sub: String, e: LoggedExercise, kind: ExerciseKind, highlight: Bool) -> some View {
        let labels = e.sets.setLabels
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title).sa(16, .semibold).foregroundColor(Tokens.text)
                Text(sub).sa(13).foregroundColor(Tokens.text2).lineLimit(1)
                Spacer(minLength: 0)
                if let acc = e.acc { Text(acc).sa(12, .medium).foregroundColor(ac.accentText) }
            }
            ForEach(Array(e.sets.enumerated()), id: \.offset) { idx, s in
                HStack(spacing: 12) {
                    Text(labels[idx]).sa(12, .semibold, mono: true).foregroundColor(Tokens.text2)
                        .frame(width: 26, height: 26).background(Circle().fill(Tokens.raised))
                    Text(setText(s, kind)).sa(15, .regular, mono: true).foregroundColor(Tokens.text)
                    Spacer(minLength: 0)
                    if s.type == .drop || s.type == .failure {
                        Text(s.type == .drop ? "dropset" : "tot falen").sa(12).foregroundColor(Tokens.text3)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: Radius.card)
        .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(highlight ? ac.accentSoft.opacity(0.45) : Color.clear))
    }
}
