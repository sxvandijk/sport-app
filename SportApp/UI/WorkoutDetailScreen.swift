import SwiftUI

/// Eén afgeronde training in detail: elke oefening met al je sets.
struct WorkoutDetailScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    model.screen = .allWorkouts
                } label: {
                    HStack(spacing: 2) {
                        Icon.chevronLeft(22)
                        Text("Alle trainingen").sa(17)
                    }
                    .foregroundColor(ac.accentText)
                    .padding(.leading, 4).padding(.trailing, 10).frame(height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 6).frame(height: 52)

            if let h = model.history.first(where: { $0.id == model.detailID }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(h.name).sa(30, .bold, tracking: -0.5).foregroundColor(Tokens.text)
                            .accessibilityAddTraits(.isHeader)
                        Text(DateText.long(h.date).capitalized + " \u{00B7} \(h.minutes) min")
                            .sa(15).foregroundColor(Tokens.text2).padding(.top, 4)

                        HStack(alignment: .top, spacing: 12) {
                            stat("\(workSets(h))", "sets")
                            stat(Format.thousands(ProgressStats.volume(of: h)), "kg volume")
                            stat("\((h.exercises ?? []).count)", "oefeningen")
                        }
                        .padding(.top, 20).padding(.bottom, 8)

                        Button {
                            model.nameEdit = NameEdit(title: "Naam van de training", subtitle: DateText.short(h.date),
                                                      placeholder: "Naam", text: h.name, confirmTitle: "Bewaar") { model.renameHistory(h.id, to: $0) }
                        } label: {
                            HStack(spacing: 6) {
                                Icon.edit(14)
                                Text("Naam wijzigen").sa(15, .semibold)
                            }
                            .foregroundColor(ac.accentText)
                            .frame(height: 44).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if (h.exercises ?? []).isEmpty {
                            Text("Van deze training is geen detail bewaard.").sa(15).foregroundColor(Tokens.text2).padding(.top, 12)
                        }
                        ForEach(Array((h.exercises ?? []).enumerated()), id: \.offset) { _, e in exerciseCard(e) }
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("Training niet gevonden.").sa(15).foregroundColor(Tokens.text2).padding(20)
                Spacer()
            }
        }
        .background(AppBackground())
    }

    private func workSets(_ h: HistoryEntry) -> Int {
        (h.exercises ?? []).reduce(0) { $0 + $1.sets.filter { $0.type != .warmup }.count }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).sa(26, .semibold, mono: true).foregroundColor(Tokens.text).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).sa(13).foregroundColor(Tokens.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func exerciseCard(_ e: LoggedExercise) -> some View {
        var n = 0
        let kind = Catalog.kind(e.name)
        return VStack(alignment: .leading, spacing: 0) {
            Text(e.name).sa(17, .semibold).foregroundColor(Tokens.text)
            Text(Catalog.info(e.name).muscle + (e.acc.map { " \u{00B7} " + $0 } ?? "")
                 + (e.uni == true ? " \u{00B7} links en rechts apart" : (e.two == true ? " \u{00B7} per arm of been" : "")))
                .sa(13).foregroundColor(Tokens.text2).padding(.top, 2).padding(.bottom, 8)
            ForEach(Array(e.sets.enumerated()), id: \.offset) { _, s in
                let label: String = {
                    if s.type == .warmup { return "W" }
                    n += 1
                    return s.type == .work ? "\(n)" : s.type.letter
                }()
                HStack(spacing: 12) {
                    Text(label).sa(13, .semibold, mono: true).foregroundColor(Tokens.text2)
                        .frame(width: 28, height: 28).background(Circle().fill(Tokens.raised))
                    Text(setText(s, kind)).sa(15, .regular, mono: true).foregroundColor(Tokens.text)
                    Spacer(minLength: 0)
                    if s.type == .drop || s.type == .failure {
                        Text(s.type == .drop ? "dropset" : "tot falen").sa(12).foregroundColor(Tokens.text3)
                    }
                }
                .frame(minHeight: 36)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: Radius.card)
        .padding(.top, 12)
    }

    private func setText(_ s: LoggedSet, _ kind: ExerciseKind) -> String {
        if kind == .cardio || kind == .timed { return "\(s.repsText)" }
        if s.w > 0 { return Format.weight(s.w) + " kg \u{00D7} " + s.repsText }
        return s.repsText + " reps"
    }
}
