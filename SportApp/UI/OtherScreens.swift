import SwiftUI

// MARK: - Training-overzicht

struct OverviewScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    /// "3 × 8–12 · 22,5 kg · Borst", "3 × 15 · Core" of "2,37 km · 3 min · Cardio".
    static func planLine(_ x: PlanItem) -> String {
        let kind = Catalog.kind(x.name)
        let muscle = Catalog.info(x.name).muscle
        guard let f = x.sets.first else { return "Geen sets · " + muscle }
        if kind == .cardio { return Format.setText(.cardio, f.w, f.r) + " · " + muscle }
        return "\(x.sets.count) × " + Format.reps(f.r, f.rmax) + " \u{00B7} " + muscle
    }

    /// Opeenvolgende oefeningen met hetzelfde groepsnummer vormen een superset.
    private func blocks(of items: [PlanItem]) -> [[PlanItem]] {
        var out: [[PlanItem]] = []
        for x in items {
            if let last = out.last?.last, last.group == x.group {
                out[out.count - 1].append(x)
            } else {
                out.append([x])
            }
        }
        return out
    }

    private func exerciseRow(_ x: PlanItem, number: Int, hue: Color?) -> some View {
        HStack(spacing: 12) {
            NumberBadge(text: String(number), hue: hue)
            VStack(alignment: .leading, spacing: 2) {
                Text(x.name).sa(17, .medium).foregroundColor(Tokens.text)
                Text((x.warm != nil ? "W + " : "") + OverviewScreen.planLine(x)).sa(13, .regular, mono: true)
                    .foregroundColor(Tokens.text2)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .frame(minHeight: 60)
    }

    var body: some View {
        if let name = model.ovName, model.templates[name] != nil {
            let info = model.planSummary(name)
            let blockList = blocks(of: info.items)
            VStack(spacing: 0) {
                HStack {
                    Button {
                        model.screen = .home
                        model.ovName = nil
                    } label: {
                        HStack(spacing: 2) {
                            Icon.chevronLeft(22)
                            Text(model.program.name).sa(17)
                        }
                        .foregroundColor(ac.accentText)
                        .padding(.leading, 4).padding(.trailing, 10).frame(height: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button {
                        model.tmName = name
                        model.openSheet(.tplmenu)
                    } label: {
                        Icon.more(24).foregroundColor(Tokens.text).frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Opties voor deze training")
                }
                .padding(.horizontal, 6).frame(height: 52)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(name).sa(30, .bold, tracking: -0.5).foregroundColor(Tokens.text)
                            .accessibilityAddTraits(.isHeader)
                        Text(info.sub).sa(15).foregroundColor(Tokens.text2).padding(.top, 4)
                        Text(info.muscles).sa(15).foregroundColor(Tokens.text2).padding(.top, 2)
                        HStack(spacing: 8) {
                            Icon.clock(18).foregroundColor(Tokens.text2)
                            Text(lastText(name)).sa(14).foregroundColor(Tokens.text)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .card(Tokens.surface, radius: Radius.row)
                        .padding(.top, 14)

                        SectionLabel(text: "Oefeningen").padding(.top, 22).padding(.bottom, 4)
                        overviewBlocks(blockList)
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(title: "Start training", height: 56, fontSize: 18, icon: Icon.play(18)) {
                    model.askStart(name)
                }
                .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 12)
                .background(Tokens.bg.ignoresSafeArea(edges: .bottom))
            }
            .background(Tokens.bg.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private func overviewBlocks(_ blockList: [[PlanItem]]) -> some View {
        ForEach(0..<blockList.count, id: \.self) { bi in
            let members = blockList[bi]
            let before = blockList[0..<bi].reduce(0) { $0 + $1.count }
            if members.count > 1 {
                let idx = blockList[0..<bi].filter { $0.count > 1 }.count
                SupersetFrame(index: idx, count: members.count) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<members.count, id: \.self) { mi in
                            exerciseRow(members[mi], number: before + mi + 1, hue: SupersetStyle.color(idx))
                        }
                    }
                    .padding(.horizontal, 12)
                }
            } else {
                exerciseRow(members[0], number: before + 1, hue: nil)
            }
        }
    }

    private func lastText(_ name: String) -> String {
        let now = Date()
        guard let entry = model.history.sorted(by: { $0.date > $1.date }).first(where: { $0.name == name }) else {
            return "Nog niet eerder gedaan"
        }
        let off = model.dayOffset(entry.date, now: now)
        let day = off == 0 ? "vandaag" : DateText.short(entry.date)
        return "Vorige keer \(day) · \(entry.minutes) min"
    }
}

// MARK: - Schema-editor

struct EditorScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    private func edit(_ i: Int, _ change: (inout DraftItem) -> Void) {
        guard var d = model.draft, d.items.indices.contains(i) else { return }
        change(&d.items[i])
        model.draft = d
    }

    var body: some View {
        if let draft = model.draft {
            let nameOk = !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
            let sets = draft.items.reduce(0) { $0 + $1.sets }
            let warm = draft.items.filter { $0.warm }.count
            let minutes = Int((Double(sets) * 2.25 + Double(warm)).rounded())
            VStack(spacing: 0) {
                HStack {
                    Button { model.cancelDraft() } label: {
                        Text("Annuleer").sa(17).foregroundColor(Tokens.text2).padding(.horizontal, 12).frame(height: 44)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text(draft.orig != nil ? "Training aanpassen" : "Nieuwe training").sa(17, .semibold).foregroundColor(Tokens.text)
                    Spacer()
                    Button { model.saveDraft() } label: {
                        Text("Bewaar").sa(17, .bold).foregroundColor(ac.accentText).padding(.horizontal, 12).frame(height: 44)
                            .opacity(nameOk ? 1 : 0.4)
                    }
                    .buttonStyle(.plain)
                    .disabled(!nameOk)
                }
                .padding(.horizontal, 8).frame(height: 52)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionLabel(text: "Naam").padding(.bottom, 8)
                        TextField("Bijv. Push B", text: nameBinding)
                            .sa(22, .semibold).foregroundColor(Tokens.text)
                            .padding(.horizontal, 16).frame(height: 56)
                            .card(Tokens.surface, radius: Radius.row)

                        HStack(alignment: .firstTextBaseline) {
                            SectionLabel(text: "Oefeningen")
                            Spacer()
                            if !draft.items.isEmpty {
                                Text("\(draft.items.count) · \(sets) sets · ~\(minutes) min")
                                    .sa(13, .regular, mono: true).foregroundColor(Tokens.text2)
                            }
                        }
                        .padding(.top, 24).padding(.bottom, 8)

                        if draft.items.isEmpty {
                            Text("Nog geen oefeningen. Voeg je eerste oefening toe.").sa(15).foregroundColor(Tokens.text2)
                                .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                                .padding(.vertical, 28).padding(.horizontal, 12)
                        }

                        let ssList = supersetIndices(draft)
                        ForEach(0..<draft.items.count, id: \.self) { i in
                            itemView(i, draft.items[i], ss: ssList[i])
                        }

                        Button {
                            model.openSheet(.add)
                            model.addToDraft = true
                        } label: {
                            HStack(spacing: 6) {
                                Icon.plus(18, 2.4)
                                Text("Oefening toevoegen").sa(16, .semibold)
                            }
                            .foregroundColor(ac.accentText)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .card(Tokens.raised, radius: Radius.button)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)

                        Text("Koppel twee oefeningen met de knop ertussen om er een superset van te maken.")
                            .sa(12).foregroundColor(Tokens.text3).multilineTextAlignment(.center).lineSpacing(3)
                            .frame(maxWidth: .infinity).padding(.top, 10)

                        if draft.orig != nil {
                            Button { model.deleteDraftTemplate() } label: {
                                Text("Training verwijderen").sa(16, .semibold).foregroundColor(Tokens.danger)
                                    .frame(maxWidth: .infinity).frame(height: 52)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 24)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 40)
                }
            }
            .background(Tokens.bg.ignoresSafeArea())
        }
    }

    private var nameBinding: Binding<String> {
        Binding(get: { model.draft?.name ?? "" },
                set: { value in
                    guard var d = model.draft else { return }
                    d.name = value
                    model.draft = d
                })
    }

    /// Per oefening: hoeveelste superset (voor de kleur), of nil als de oefening alleen staat.
    private func supersetIndices(_ draft: Draft) -> [Int?] {
        var groups: [Int] = []
        var gi = -1
        for (i, it) in draft.items.enumerated() {
            if !(i > 0 && it.link) { gi += 1 }
            groups.append(gi)
        }
        var sizes: [Int: Int] = [:]
        for g in groups { sizes[g, default: 0] += 1 }
        var order: [Int: Int] = [:]
        var out: [Int?] = []
        for g in groups {
            if (sizes[g] ?? 0) > 1 {
                if order[g] == nil { order[g] = order.count }
                out.append(order[g])
            } else {
                out.append(nil)
            }
        }
        return out
    }

    private static let presets: [(title: String, lo: Int, hi: Int)] = [("5\u{2013}8", 5, 8), ("8\u{2013}12", 8, 12), ("12\u{2013}15", 12, 15)]

    @ViewBuilder
    private func itemView(_ i: Int, _ it: DraftItem, ss: Int?) -> some View {
        let hue: Color? = ss.map { SupersetStyle.color($0) }
        if i > 0 {
            HStack {
                Spacer()
                Button { edit(i) { $0.link.toggle() } } label: {
                    HStack(spacing: 6) {
                        Icon.link(14, 2.4)
                        Text(it.link ? "Superset met vorige" : "Koppel als superset").sa(13, .semibold)
                    }
                    .foregroundColor(it.link ? (hue ?? ac.accentText) : Tokens.text3)
                    .padding(.horizontal, 12).frame(minWidth: 44).frame(height: 36)
                    .background(Capsule().fill(it.link ? (hue ?? ac.accent).opacity(0.18) : Color.clear))
                }
                .buttonStyle(.plain)
                .accessibilityValue(it.link ? "aan" : "uit")
                Spacer()
            }
            .padding(.top, -4).padding(.bottom, 4)
        }
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                NumberBadge(text: String(i + 1), hue: hue, size: 28).padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(it.name).sa(17, .semibold).foregroundColor(Tokens.text)
                    Text(Catalog.info(it.name).muscle + " \u{00B7} " + Catalog.kind(it.name).title).sa(13).foregroundColor(Tokens.text2)
                }
                Spacer(minLength: 0)
                Button { moveUp(i) } label: {
                    Icon.chevronUp(18).foregroundColor(Tokens.text2).frame(width: 36, height: 44)
                        .opacity(i == 0 ? 0.3 : 1).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Omhoog")
                Button { remove(i) } label: {
                    Icon.trash(18).foregroundColor(Tokens.danger).frame(width: 40, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Verwijder oefening")
            }
            if Catalog.kind(it.name) == .cardio {
                HStack(spacing: 8) {
                    counter(value: Format.km(it.w), unit: " km", minus: "Minder kilometers", plus: "Meer kilometers",
                            onMinus: { edit(i) { $0.w = max(0, (($0.w - 0.1) * 100).rounded() / 100) } },
                            onPlus: { edit(i) { $0.w = (($0.w + 0.1) * 100).rounded() / 100 } })
                    counter(value: String(it.reps), unit: " min", minus: "Minder minuten", plus: "Meer minuten",
                            onMinus: { edit(i) { $0.reps = max(1, $0.reps - 1) } },
                            onPlus: { edit(i) { $0.reps += 1 } })
                }
                .padding(.top, 10).padding(.trailing, 8)
            } else {
                HStack(spacing: 8) {
                    counter(value: String(it.sets), unit: " sets", minus: "Minder sets", plus: "Meer sets",
                            onMinus: { edit(i) { $0.sets = max(1, $0.sets - 1) } },
                            onPlus: { edit(i) { $0.sets = min(10, $0.sets + 1) } })
                    counter(value: String(it.reps), unit: " reps", minus: "Minder reps", plus: "Meer reps",
                            onMinus: { edit(i) { $0.reps = max(1, $0.reps - 1) } },
                            onPlus: { edit(i) {
                                $0.reps += 1
                                if let m = $0.repsMax, m <= $0.reps { $0.repsMax = nil }
                            } })
                }
                .padding(.top, 10).padding(.trailing, 8)
                HStack(spacing: 8) {
                    counter(value: it.repsMax.map { String($0) } ?? "\u{2013}", unit: " tot", minus: "Minder maximum reps", plus: "Meer maximum reps",
                            onMinus: { edit(i) {
                                if let m = $0.repsMax { $0.repsMax = m - 1 <= $0.reps ? nil : m - 1 }
                            } },
                            onPlus: { edit(i) { $0.repsMax = ($0.repsMax ?? $0.reps) + 1 } })
                    Button { edit(i) { $0.warm.toggle() } } label: {
                        HStack(spacing: 6) {
                            Icon.plus(16, 2.4)
                            Text("Warming-up").sa(14, .semibold)
                        }
                        .foregroundColor(it.warm ? Color.black.opacity(0.85) : Tokens.warm)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .card(it.warm ? Tokens.warm : Tokens.raised, radius: Radius.field)
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(it.warm ? "aan" : "uit")
                }
                .padding(.top, 8).padding(.trailing, 8)
                HStack(spacing: 6) {
                    Text("Advies").sa(12, .medium).foregroundColor(Tokens.text3)
                    ForEach(0..<EditorScreen.presets.count, id: \.self) { k in
                        let p = EditorScreen.presets[k]
                        let on = it.reps == p.lo && it.repsMax == p.hi
                        Button { edit(i) { $0.reps = p.lo; $0.repsMax = p.hi } } label: {
                            Text(p.title).sa(13, .semibold, mono: true)
                                .foregroundColor(on ? Tokens.text : Tokens.text2)
                                .padding(.horizontal, 12).frame(height: 32)
                                .background(Capsule().fill(on ? ac.accentSoft : Tokens.raised))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, 8)
            }
        }
        .padding(.leading, 16).padding(.trailing, 8).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Tokens.surface, radius: Radius.button)
        .overlay(RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .stroke(hue?.opacity(0.7) ?? Color.clear, lineWidth: 1.5))
        .padding(.bottom, 8)
    }

    private func counter(value: String, unit: String, minus: String, plus: String,
                         onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            Button(action: onMinus) {
                Text("−").sa(20, .medium).foregroundColor(Tokens.text).frame(width: 40, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(minus)
            HStack(spacing: 0) {
                Text(value).sa(18, .semibold, mono: true).foregroundColor(Tokens.text)
                Text(unit).sa(13).foregroundColor(Tokens.text2)
            }
            .frame(maxWidth: .infinity)
            Button(action: onPlus) {
                Text("+").sa(20, .medium).foregroundColor(Tokens.text).frame(width: 40, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(plus)
        }
        .frame(maxWidth: .infinity).frame(height: 44)
        .card(Tokens.raised, radius: Radius.field)
    }

    private func moveUp(_ i: Int) {
        guard var d = model.draft, i > 0, d.items.indices.contains(i) else { return }
        d.items.swapAt(i, i - 1)
        d.items[0].link = false
        model.draft = d
    }

    private func remove(_ i: Int) {
        guard var d = model.draft, d.items.indices.contains(i) else { return }
        d.items.remove(at: i)
        if !d.items.isEmpty { d.items[0].link = false }
        model.draft = d
    }
}

// MARK: - Afgerond

struct SummaryScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        if let sm = model.summary {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Icon.check(32, 2.6).foregroundColor(ac.onAccent)
                            .frame(width: 64, height: 64).background(Circle().fill(ac.accent))
                        Text(sm.title).sa(30, .bold, tracking: -0.5).foregroundColor(Tokens.text).padding(.top, 20)
                            .accessibilityAddTraits(.isHeader)
                        Text(sm.note).sa(15).foregroundColor(Tokens.text2).padding(.top, 4)
                        HStack(alignment: .top, spacing: 12) {
                            stat(sm.time, "duur", flex: 1)
                            stat(sm.sets, "sets", flex: 1)
                            stat(sm.volume, "kg volume", flex: 1.3)
                        }
                        .padding(.top, 28).padding(.bottom, 24)
                        ForEach(sm.lines) { ln in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ln.name).sa(16, .medium).foregroundColor(Tokens.text)
                                Text(ln.summary).sa(13, .regular, mono: true).foregroundColor(Tokens.text2)
                            }
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 24).padding(.top, 48).padding(.bottom, 24)
                }
                PrimaryButton(title: "Klaar", height: 58, fontSize: 18) { model.goHome() }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
            }
            .background(Tokens.bg.ignoresSafeArea())
        }
    }

    private func stat(_ value: String, _ label: String, flex: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).sa(28, .semibold, mono: true).foregroundColor(Tokens.text).lineLimit(1)
            Text(label).sa(13).foregroundColor(Tokens.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
