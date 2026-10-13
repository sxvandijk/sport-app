import SwiftUI

// MARK: - Training-overzicht

struct OverviewScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    private struct Row: Identifiable {
        let id = UUID()
        let header: Bool
        let name: String
        let sub: String
        let badge: String
    }

    private func rows(for items: [PlanItem]) -> [Row] {
        var out: [Row] = []
        var superLetterIndex = 0
        var blockNo = 0
        let letters = Array("ABCDEFGH")
        for (i, x) in items.enumerated() {
            let prevSame = i > 0 && items[i - 1].group == x.group
            let nextSame = i < items.count - 1 && items[i + 1].group == x.group
            if !prevSame { blockNo += 1 }
            let inSS = prevSame || nextSame
            if inSS && !prevSame {
                superLetterIndex += 1
                out.append(Row(header: true, name: "", sub: "", badge: ""))
            }
            var pos = 1
            var j = i - 1
            while j >= 0 && items[j].group == x.group {
                pos += 1
                j -= 1
            }
            let maxReps = x.sets.map { $0.r }.max() ?? 0
            let maxW = x.sets.map { $0.w }.max() ?? 0
            let sub = (x.warm != nil ? "W + " : "") + "\(x.sets.count) × \(maxReps) · \(Format.weight(maxW)) kg · " + Catalog.info(x.name).muscle
            let letter = String(letters[min(max(superLetterIndex - 1, 0), letters.count - 1)])
            out.append(Row(header: false, name: x.name, sub: sub, badge: inSS ? letter + String(pos) : String(blockNo)))
        }
        return out
    }

    var body: some View {
        if let name = model.ovName, model.templates[name] != nil {
            let info = model.planSummary(name)
            let list = rows(for: info.items)
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
                        ForEach(list) { row in
                            if row.header {
                                HStack(spacing: 6) {
                                    Icon.link(14)
                                    Text("SUPERSET").sa(12, .semibold, tracking: 0.72)
                                }
                                .foregroundColor(Tokens.text2).padding(.top, 12)
                            } else {
                                HStack(spacing: 12) {
                                    Text(row.badge).sa(12, .bold).foregroundColor(Tokens.text2)
                                        .frame(width: 32, height: 32).background(Circle().fill(Tokens.raised))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(row.name).sa(17, .medium).foregroundColor(Tokens.text)
                                        Text(row.sub).sa(13, .regular, mono: true).foregroundColor(Tokens.text2)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .frame(minHeight: 60)
                            }
                        }
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

                        let badges = badgeList(draft)
                        ForEach(0..<draft.items.count, id: \.self) { i in
                            itemView(i, draft.items[i], badge: badges[i])
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

    /// Superset-badges (A1, A2, B1 ...) voor gekoppelde oefeningen.
    private func badgeList(_ draft: Draft) -> [String] {
        var groups: [Int] = []
        var gi = -1
        for (i, it) in draft.items.enumerated() {
            if !(i > 0 && it.link) { gi += 1 }
            groups.append(gi)
        }
        var sizes: [Int: Int] = [:]
        for g in groups { sizes[g, default: 0] += 1 }
        var letterOf: [Int: String] = [:]
        var li = 0
        var posIn: [Int: Int] = [:]
        let letters = Array("ABCDEFGH")
        var out: [String] = []
        for g in groups {
            if (sizes[g] ?? 0) > 1 {
                if letterOf[g] == nil {
                    letterOf[g] = String(letters[min(li, letters.count - 1)])
                    li += 1
                }
                posIn[g, default: 0] += 1
                out.append((letterOf[g] ?? "") + String(posIn[g] ?? 1))
            } else {
                out.append("")
            }
        }
        return out
    }

    @ViewBuilder
    private func itemView(_ i: Int, _ it: DraftItem, badge: String) -> some View {
        if i > 0 {
            HStack {
                Spacer()
                Button { edit(i) { $0.link.toggle() } } label: {
                    HStack(spacing: 6) {
                        Icon.link(14, 2.4)
                        Text(it.link ? "Superset" : "Koppel als superset").sa(13, .semibold)
                    }
                    .foregroundColor(it.link ? ac.accentText : Tokens.text3)
                    .padding(.horizontal, 12).frame(minWidth: 44).frame(height: 36)
                    .background(Capsule().fill(it.link ? ac.accentSoft : Color.clear))
                }
                .buttonStyle(.plain)
                .accessibilityValue(it.link ? "aan" : "uit")
                Spacer()
            }
            .padding(.top, -4).padding(.bottom, 4)
        }
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                if !badge.isEmpty {
                    Text(badge).sa(12, .bold).foregroundColor(Tokens.text2)
                        .padding(.horizontal, 7).frame(height: 22)
                        .card(Tokens.raised, radius: Radius.badge).padding(.top, 2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(it.name).sa(17, .semibold).foregroundColor(Tokens.text)
                    Text(Catalog.info(it.name).muscle + " · " + Format.weight(it.w) + " kg").sa(13).foregroundColor(Tokens.text2)
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
            HStack(spacing: 8) {
                counter(value: String(it.sets), unit: " sets", minus: "Minder sets", plus: "Meer sets",
                        onMinus: { edit(i) { $0.sets = max(1, $0.sets - 1) } },
                        onPlus: { edit(i) { $0.sets = min(10, $0.sets + 1) } })
                counter(value: String(it.reps), unit: " reps", minus: "Minder reps", plus: "Meer reps",
                        onMinus: { edit(i) { $0.reps = max(1, $0.reps - 1) } },
                        onPlus: { edit(i) { $0.reps += 1 } })
            }
            .padding(.top, 10).padding(.trailing, 8)

            Button { edit(i) { $0.warm.toggle() } } label: {
                HStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        Capsule().fill(it.warm ? Tokens.warm : Tokens.line).frame(width: 42, height: 26)
                        Circle().fill(Color.white).frame(width: 22, height: 22).padding(.leading, 2)
                            .offset(x: it.warm ? 16 : 0)
                    }
                    Text("Warming-upset").sa(15, .medium).foregroundColor(it.warm ? Tokens.text : Tokens.text2)
                }
                .frame(height: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .accessibilityValue(it.warm ? "aan" : "uit")
        }
        .padding(.leading, 16).padding(.trailing, 8).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Tokens.surface, radius: Radius.button)
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
