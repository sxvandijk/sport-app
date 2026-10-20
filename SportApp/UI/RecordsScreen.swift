import SwiftUI

/// Alle persoonlijke records op een eigen pagina, met filter op spiergroep.
struct RecordsScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @State private var filter: String?

    var body: some View {
        let stats = ProgressStats.make(history: model.history, now: Date())
        let muscles = Array(Set(stats.records.map { Catalog.info($0.name).muscle })).sorted()
        let shown = stats.records.filter { filter == nil || Catalog.info($0.name).muscle == filter }
        VStack(spacing: 0) {
            HStack {
                Button {
                    model.screen = .home
                } label: {
                    HStack(spacing: 2) {
                        Icon.chevronLeft(22)
                        Text("Profiel").sa(17)
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
                    Text("Persoonlijke records").sa(30, .bold, tracking: -0.5).foregroundColor(Tokens.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(stats.records.isEmpty ? "Nog geen records" : "\(stats.records.count) oefeningen \u{00B7} je beste set per oefening")
                        .sa(15).foregroundColor(Tokens.text2).padding(.top, 4)

                    if muscles.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                chip("Alle", on: filter == nil) { filter = nil }
                                ForEach(muscles, id: \.self) { m in
                                    chip(m, on: filter == m) { filter = m }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, -20).padding(.top, 16)
                    }

                    if stats.records.isEmpty {
                        Text("Rond een training af, dan verschijnen hier je zwaarste sets. Je records worden berekend uit wat je echt hebt gedaan.")
                            .sa(15).foregroundColor(Tokens.text2).lineSpacing(3)
                            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .glassCard(radius: Radius.card).padding(.top, 20)
                    }
                    VStack(spacing: 0) {
                        ForEach(shown) { r in RecordCard(record: r) }
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(AppBackground())
    }

    private func chip(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).sa(14, .semibold)
                .foregroundColor(on ? ac.onAccent : Tokens.text)
                .padding(.horizontal, 14).frame(height: 36)
                .background(Capsule().fill(on ? ac.accent : Tokens.raised))
                .frame(height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

struct RecordCard: View {
    @Environment(\.accentColors) private var ac
    let record: PersonalRecord

    var body: some View {
        let r = record
        let fresh = Date().timeIntervalSince(r.date) < 7 * 86400
        let main: String
        let unit: String
        if r.kind == .bodyweight && r.weight == 0 {
            main = "\(r.reps)"
            unit = " reps"
        } else if r.kind == .bodyweight {
            main = "+" + Format.weight(r.weight)
            unit = " kg \u{00D7} \(r.reps)"
        } else {
            main = Format.weight(r.weight)
            unit = " kg \u{00D7} \(r.reps)"
        }
        return HStack(spacing: 14) {
            VStack(spacing: 2) {
                Icon.star(18).foregroundColor(ac.accentText)
            }
            .frame(width: 44, height: 44)
            .background(Circle().fill(ac.accentSoft))
            VStack(alignment: .leading, spacing: 3) {
                Text(r.name).sa(16, .semibold).foregroundColor(Tokens.text).lineLimit(1)
                HStack(spacing: 8) {
                    Text(Catalog.info(r.name).muscle + (r.acc.map { " \u{00B7} " + $0 } ?? "") + " \u{00B7} " + DateText.short(r.date)).sa(13).foregroundColor(Tokens.text2)
                    if fresh {
                        Text("Nieuw").sa(11, .bold).foregroundColor(ac.accentText)
                            .padding(.horizontal, 7).frame(height: 20)
                            .background(Capsule().fill(ac.accentSoft))
                    }
                }
                if r.oneRM > 0 {
                    Text("Geschat 1RM " + Format.weight(r.oneRM.rounded()) + " kg").sa(12, .regular, mono: true)
                        .foregroundColor(Tokens.text3)
                }
            }
            Spacer(minLength: 8)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(main).sa(24, .semibold, tracking: -0.4, mono: true).foregroundColor(Tokens.text)
                Text(unit).sa(13, .medium).foregroundColor(Tokens.text2)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: Radius.button)
        .padding(.bottom, 8)
    }
}
