import SwiftUI

/// Alle afgeronde trainingen op een eigen pagina, met filter op training.
struct AllWorkoutsScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @State private var filter: String?
    @State private var limit = 20
    @State private var openWorkout: UUID?

    var body: some View {
        let names = Array(Set(model.history.map { $0.name })).sorted()
        let all = model.history.sorted { $0.date > $1.date }
        let shown = all.filter { filter == nil || $0.name == filter }
        let visible = Array(shown.prefix(limit))
        VStack(spacing: 0) {
            HStack {
                Button {
                    model.screen = .home
                } label: {
                    HStack(spacing: 2) {
                        Icon.chevronLeft(22)
                        Text("Progressie").sa(17)
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
                    Text("Alle trainingen").sa(30, .bold, tracking: -0.5).foregroundColor(Tokens.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(all.isEmpty ? "Nog geen trainingen" : "\(shown.count) \(shown.count == 1 ? "training" : "trainingen")")
                        .sa(15).foregroundColor(Tokens.text2).padding(.top, 4)

                    if names.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                chip("Alle", on: filter == nil) { filter = nil; limit = 20 }
                                ForEach(names, id: \.self) { n in
                                    chip(n, on: filter == n) { filter = n; limit = 20 }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, -20).padding(.top, 16)
                    }

                    if all.isEmpty {
                        Text("Rond een training af, dan verschijnt hij hier.")
                            .sa(15).foregroundColor(Tokens.text2).lineSpacing(3)
                            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .glassCard(radius: Radius.card).padding(.top, 20)
                    }
                    VStack(spacing: 0) {
                        ForEach(visible) { h in workoutRow(h) }
                    }
                    .padding(.top, 12)
                    if shown.count > visible.count {
                        Button { limit += 20 } label: {
                            Text("Toon meer").sa(15, .semibold).foregroundColor(ac.accentText)
                                .frame(maxWidth: .infinity).frame(height: 48).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(AppBackground())
    }

    private func chip(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).sa(14, .medium).lineLimit(1)
                .foregroundColor(on ? ac.onAccent : Tokens.text)
                .padding(.horizontal, 16).frame(height: 40)
                .glassSurface(Capsule(), tint: on ? ac.accent : nil, interactive: true, fallback: on ? ac.accentLine : Tokens.raised)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func workoutRow(_ h: HistoryEntry) -> some View {
        let open = openWorkout == h.id
        return VStack(alignment: .leading, spacing: 0) {
            Button { openWorkout = open ? nil : h.id } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(h.name).sa(16, .semibold).foregroundColor(Tokens.text)
                        Text(DateText.short(h.date) + " \u{00B7} \(h.minutes) min \u{00B7} " + Format.thousands(ProgressStats.volume(of: h)) + " kg")
                            .sa(13).foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                    (open ? Icon.chevronUp(14) : Icon.chevronDown(14)).foregroundColor(Tokens.text3)
                }
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if open {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(h.exercises ?? [], id: \.name) { e in
                        let sets = e.sets.filter { $0.type != .warmup }
                        HStack(alignment: .firstTextBaseline) {
                            Text(e.name).sa(14, .medium).foregroundColor(Tokens.text).lineLimit(1)
                            Spacer(minLength: 8)
                            Text(sets.map { Format.weight($0.w) + "\u{00D7}" + $0.repsText }.joined(separator: ", "))
                                .sa(12, .regular, mono: true).foregroundColor(Tokens.text2).lineLimit(1)
                        }
                    }
                    if (h.exercises ?? []).isEmpty {
                        Text("Van deze training is geen detail bewaard.").sa(13).foregroundColor(Tokens.text2)
                    }
                }
                .padding(.bottom, 10)
            }
            Divider().background(Tokens.line)
        }
    }
}
