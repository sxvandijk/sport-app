import SwiftUI

// MARK: - Training-overzicht

struct OverviewScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @State private var expanded: Set<UUID> = []
    @StateObject private var coord = ReorderCoordinator()

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

    private func exerciseRow(_ x: PlanItem, number: Int, hue: Color?, handle: Bool = false, reserve: Bool = false) -> some View {
        let open = expanded.contains(x.id)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
            Button {
                if open { expanded.remove(x.id) } else { expanded.insert(x.id) }
            } label: {
                HStack(spacing: 12) {
                    NumberBadge(text: String(number), hue: hue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(x.name).sa(17, .medium).foregroundColor(Tokens.text)
                        Text((x.warm != nil ? "\(x.warmCount ?? 1)W + " : "") + OverviewScreen.planLine(x)).sa(13, .regular, mono: true)
                            .foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                    Icon.chevronRight(16).foregroundColor(Tokens.text3).rotationEffect(.degrees(open ? 90 : 0))
                }
                .padding(.vertical, 8)
                .frame(minHeight: 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if handle { dragHandle(x.id) }
            else if reserve { Color.clear.frame(width: 40, height: 44) }
            }
            if open { setLines(x) }
        }
    }

    /// Drie streepjes: vasthouden en slepen om dit blok te verplaatsen.
    private func dragHandle(_ id: UUID) -> some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule().fill(Tokens.text3).frame(width: 18, height: 2.5)
            }
        }
        .frame(width: 40, height: 44)
        .contentShape(Rectangle())
        .reorderGesture(id, coord) { target in model.moveBlock(template: model.ovName ?? "", block: id, onto: target) }
        .accessibilityLabel("Sleep om te verplaatsen")
    }

    private func setLines(_ x: PlanItem) -> some View {
        let kind = Catalog.kind(x.name)
        return VStack(alignment: .leading, spacing: 6) {
            if x.warm != nil {
                Text("\(x.warmCount ?? 1) warming-up \(x.warmCount == 1 || x.warmCount == nil ? "set" : "sets")")
                    .sa(14, .regular, mono: true).foregroundColor(Tokens.warm)
            }
            ForEach(0..<x.sets.count, id: \.self) { i in
                let s = x.sets[i]
                let value: String = kind == .cardio ? Format.setText(.cardio, s.w, s.r) : (kind == .timed ? "\(s.r) min" : Format.reps(s.r, s.rmax) + " reps")
                Text("Set \(i + 1)  \u{00B7}  " + value).sa(14, .regular, mono: true).foregroundColor(Tokens.text2)
            }
            Button { model.editTemplate(model.ovName ?? "") } label: {
                Text("Aanpassen").sa(14, .semibold).foregroundColor(ac.accentText).frame(height: 36, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 44).padding(.bottom, 10)
    }

    private func warmupRow(_ x: PlanItem) -> some View {
        HStack(spacing: 12) {
            Circle().fill(Tokens.warm).frame(width: 10, height: 10).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(x.name).sa(17, .medium).foregroundColor(Tokens.text)
                Text(OverviewScreen.warmupLine(x)).sa(13, .regular, mono: true).foregroundColor(Tokens.text2)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .frame(minHeight: 56)
    }

    /// "2 × 15 · Schouders" of "5 min · Cardio".
    static func warmupLine(_ x: PlanItem) -> String {
        let kind = Catalog.kind(x.name)
        let muscle = Catalog.info(x.name).muscle
        guard let f = x.sets.first else { return muscle }
        if kind == .timed { return "\(f.r) min \u{00B7} " + muscle }
        if kind == .cardio { return Format.setText(.cardio, f.w, f.r) + " \u{00B7} " + muscle }
        return "\(x.sets.count) \u{00D7} \(f.r) \u{00B7} " + muscle
    }

    var body: some View {
        if let name = model.ovName, model.templates[name] != nil {
            let info = model.planSummary(name)
            let blockList = blocks(of: info.items.filter { $0.isWarmup != true })
            let warmItems = info.items.filter { $0.isWarmup == true }
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

                        if !warmItems.isEmpty {
                            SectionLabel(text: "Warming-up").padding(.top, 22).padding(.bottom, 4)
                            ForEach(warmItems) { x in warmupRow(x) }
                        }
                        SectionLabel(text: "Oefeningen").padding(.top, 22).padding(.bottom, 4)
                        overviewBlocks(blockList)
                    }
                    .coordinateSpace(name: "reorder")
                    .onPreferenceChange(ReorderFramesKey.self) { coord.setFrames($0) }
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
        ForEach(blockList, id: \.first!.id) { members in
            let bi = blockList.firstIndex(where: { $0.first?.id == members.first?.id }) ?? 0
            let before = blockList[0..<bi].reduce(0) { $0 + $1.count }
            if members.count > 1 {
                let idx = blockList[0..<bi].filter { $0.count > 1 }.count
                SupersetFrame(index: idx, count: members.count) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(members) { member in
                            let mi = members.firstIndex(where: { $0.id == member.id }) ?? 0
                            exerciseRow(members[mi], number: before + mi + 1, hue: SupersetStyle.color(idx), reserve: true)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .overlay(alignment: .trailing) { dragHandle(members[0].id).padding(.trailing, 4) }
                .reorderRow(members[0].id, coord)
            } else {
                exerciseRow(members[0], number: before + 1, hue: nil, handle: true)
                    .reorderRow(members[0].id, coord)
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
    @StateObject private var coord = ReorderCoordinator()

    private func edit(_ i: Int, _ change: (inout DraftItem) -> Void) {
        guard var d = model.draft, d.items.indices.contains(i) else { return }
        change(&d.items[i])
        model.draft = d
    }

    var body: some View {
        if let draft = model.draft {
            let nameOk = !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
            let workItems = draft.items.filter { !$0.isWarmup }
            let warmCount = draft.items.filter { $0.isWarmup }.count
            let sets = workItems.reduce(0) { $0 + $1.sets }
            let warm = workItems.reduce(0) { $0 + $1.warmSets }
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

                        warmupSection(draft, warmCount: warmCount)

                        HStack(alignment: .firstTextBaseline) {
                            SectionLabel(text: "Oefeningen")
                            Spacer()
                            if !workItems.isEmpty {
                                Text("\(workItems.count) · \(sets) sets · ~\(minutes) min")
                                    .sa(13, .regular, mono: true).foregroundColor(Tokens.text2)
                            }
                        }
                        .padding(.top, 24).padding(.bottom, 8)

                        if workItems.isEmpty {
                            Text("Nog geen oefeningen. Voeg je eerste oefening toe.").sa(15).foregroundColor(Tokens.text2)
                                .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                                .padding(.vertical, 28).padding(.horizontal, 12)
                        }

                        let ssList = supersetIndices(draft)
                        ForEach(Array(draft.items[warmCount...])) { item in
                            if let i = draft.items.firstIndex(where: { $0.id == item.id }) {
                                itemView(i, item, ss: ssList[i], first: warmCount)
                            }
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
                    .coordinateSpace(name: "reorder")
                    .onPreferenceChange(ReorderFramesKey.self) { coord.setFrames($0) }
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

    private func warmupSection(_ draft: Draft, warmCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "Warming-up").padding(.top, 24).padding(.bottom, 4)
            Text("Staat vooraan in deze training. Bijvoorbeeld rotator cuff of fietsen.")
                .sa(13).foregroundColor(Tokens.text2).padding(.bottom, 8)
            ForEach(Array(draft.items[0..<warmCount])) { item in
                if let i = draft.items.firstIndex(where: { $0.id == item.id }) {
                    warmupCard(i, item, isFirst: i == 0)
                }
            }
            Button {
                model.openSheet(.add)
                model.addToDraft = true
                model.addToDraftWarmup = true
            } label: {
                HStack(spacing: 6) {
                    Icon.plus(18, 2.4)
                    Text("Warming-up toevoegen").sa(16, .semibold)
                }
                .foregroundColor(Tokens.warm)
                .frame(maxWidth: .infinity).frame(height: 48)
                .card(Tokens.raised, radius: Radius.button)
            }
            .buttonStyle(.plain)
        }
    }

    private func warmupCard(_ i: Int, _ it: DraftItem, isFirst: Bool) -> some View {
        let info = Catalog.info(it.name)
        let kind = info.kind
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Circle().fill(Tokens.warm).frame(width: 10, height: 10).frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(it.name).sa(17, .semibold).foregroundColor(Tokens.text)
                    Text(info.muscle + " \u{00B7} " + kind.title).sa(13).foregroundColor(Tokens.text2)
                }
                Spacer(minLength: 0)
                cardHandle(it)
                Button { remove(i) } label: {
                    Icon.trash(18).foregroundColor(Tokens.danger).frame(width: 40, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Verwijder warming-up")
            }
            if kind == .timed {
                HStack(spacing: 8) {
                    counter(value: String(it.reps), unit: " min", minus: "Minder minuten", plus: "Meer minuten",
                            onMinus: { edit(i) { $0.reps = max(1, $0.reps - 1) } },
                            onPlus: { edit(i) { $0.reps += 1 } })
                    Spacer().frame(maxWidth: .infinity)
                }
                .padding(.top, 10).padding(.trailing, 8)
            } else if kind == .cardio {
                cardioCounters(i, it)
            } else {
                setsAndReps(i, it)
            }
        }
        .padding(.leading, 16).padding(.trailing, 8).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Tokens.surface, radius: Radius.button)
        .reorderRow(it.id, coord)
        .padding(.bottom, 8)
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
    private func itemView(_ i: Int, _ it: DraftItem, ss: Int?, first: Int) -> some View {
        let hue: Color? = ss.map { SupersetStyle.color($0) }
        let kind = Catalog.kind(it.name)
        if i > first { linkToggle(i, it, hue: hue) }
        VStack(alignment: .leading, spacing: 0) {
            itemHeader(i, it, hue: hue, number: i - first + 1, canMoveUp: i > first)
            if kind == .cardio {
                cardioCounters(i, it)
            } else if kind == .timed {
                timedCounter(i, it)
            } else {
                warmupAndSets(i, it)
                repRange(i, it)
                presetRow(i, it)
            }
        }
        .padding(.leading, 16).padding(.trailing, 8).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Tokens.surface, radius: Radius.button)
        .overlay(itemBorder(hue))
        .reorderRow(it.id, coord)
        .padding(.bottom, 8)
    }

    private func itemBorder(_ hue: Color?) -> some View {
        let color: Color = hue?.opacity(0.7) ?? Color.clear
        return RoundedRectangle(cornerRadius: Radius.button, style: .continuous).stroke(color, lineWidth: 1.5)
    }

    private func linkToggle(_ i: Int, _ it: DraftItem, hue: Color?) -> some View {
        let tint: Color = hue ?? ac.accentText
        let textColor: Color = it.link ? tint : Tokens.text3
        let fillColor: Color = it.link ? tint.opacity(0.18) : Color.clear
        let title = it.link ? "Superset met vorige" : "Koppel als superset"
        return HStack {
            Spacer()
            Button { edit(i) { $0.link.toggle() } } label: {
                HStack(spacing: 6) {
                    Icon.link(14, 2.4)
                    Text(title).sa(13, .semibold)
                }
                .foregroundColor(textColor)
                .padding(.horizontal, 12).frame(minWidth: 44).frame(height: 36)
                .background(Capsule().fill(fillColor))
            }
            .buttonStyle(.plain)
            .accessibilityValue(it.link ? "aan" : "uit")
            Spacer()
        }
        .padding(.top, -4).padding(.bottom, 4)
    }

    /// Drie streepjes: vasthouden en slepen. Alleen hier, zodat je overal anders gewoon kunt scrollen.
    private func cardHandle(_ it: DraftItem) -> some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule().fill(Tokens.text3).frame(width: 18, height: 2.5)
            }
        }
        .frame(width: 40, height: 44)
        .contentShape(Rectangle())
        .reorderGesture(it.id, coord) { target in model.moveDraftItem(it.id, onto: target) }
        .accessibilityLabel("Sleep om te verplaatsen")
    }

    private func itemHeader(_ i: Int, _ it: DraftItem, hue: Color?, number: Int, canMoveUp: Bool) -> some View {
        let info = Catalog.info(it.name)
        let sub = info.muscle + " \u{00B7} " + info.kind.title
        return HStack(alignment: .top, spacing: 10) {
            NumberBadge(text: String(number), hue: hue, size: 28).padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(it.name).sa(17, .semibold).foregroundColor(Tokens.text)
                Text(sub).sa(13).foregroundColor(Tokens.text2)
            }
            Spacer(minLength: 0)
            cardHandle(it)
            Button { remove(i) } label: {
                Icon.trash(18).foregroundColor(Tokens.danger).frame(width: 40, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Verwijder oefening")
        }
    }

    private func cardioCounters(_ i: Int, _ it: DraftItem) -> some View {
        HStack(spacing: 8) {
            counter(value: Format.km(it.w), unit: " km", minus: "Minder kilometers", plus: "Meer kilometers",
                    onMinus: { edit(i) { $0.w = max(0, (($0.w - 0.1) * 100).rounded() / 100) } },
                    onPlus: { edit(i) { $0.w = (($0.w + 0.1) * 100).rounded() / 100 } })
            counter(value: String(it.reps), unit: " min", minus: "Minder minuten", plus: "Meer minuten",
                    onMinus: { edit(i) { $0.reps = max(1, $0.reps - 1) } },
                    onPlus: { edit(i) { $0.reps += 1 } })
        }
        .padding(.top, 10).padding(.trailing, 8)
    }

    private func setsAndReps(_ i: Int, _ it: DraftItem) -> some View {
        HStack(spacing: 8) {
            counter(value: String(it.sets), unit: " sets", minus: "Minder sets", plus: "Meer sets",
                    onMinus: { edit(i) { $0.sets = max(1, $0.sets - 1) } },
                    onPlus: { edit(i) { $0.sets = min(10, $0.sets + 1) } })
            counter(value: String(it.reps), unit: " reps", minus: "Minder reps", plus: "Meer reps",
                    onMinus: { edit(i) { $0.reps = max(1, $0.reps - 1) } },
                    onPlus: { edit(i) { $0.repsUp() } })
        }
        .padding(.top, 10).padding(.trailing, 8)
    }

    private func timedCounter(_ i: Int, _ it: DraftItem) -> some View {
        HStack(spacing: 8) {
            counter(value: String(it.reps), unit: " min", minus: "Minder minuten", plus: "Meer minuten",
                    onMinus: { edit(i) { $0.reps = max(1, $0.reps - 1) } },
                    onPlus: { edit(i) { $0.reps += 1 } })
            Spacer().frame(maxWidth: .infinity)
        }
        .padding(.top, 10).padding(.trailing, 8)
    }

    /// Rij 1: warming-up aan/uit, ernaast het aantal sets.
    private func warmupAndSets(_ i: Int, _ it: DraftItem) -> some View {
        HStack(spacing: 8) {
            warmupSwitch(i, it)
            counter(value: String(it.sets), unit: " sets", minus: "Minder sets", plus: "Meer sets",
                    onMinus: { edit(i) { $0.sets = max(1, $0.sets - 1) } },
                    onPlus: { edit(i) { $0.sets = min(10, $0.sets + 1) } })
        }
        .padding(.top, 10).padding(.trailing, 8)
    }

    private func warmupSwitch(_ i: Int, _ it: DraftItem) -> some View {
        HStack(spacing: 0) {
            Button { edit(i) { $0.warmSets = max(0, $0.warmSets - 1) } } label: {
                Text("\u{2212}").sa(20, .medium).foregroundColor(Tokens.text).frame(width: 40, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Minder warming-upsets")
            VStack(spacing: 0) {
                Text(it.warmSets == 0 ? "Uit" : String(it.warmSets)).sa(18, .semibold, mono: true)
                    .foregroundColor(it.warmSets == 0 ? Tokens.text3 : Tokens.warm)
                Text("warming-up").sa(11, .medium).foregroundColor(Tokens.text2)
            }
            .frame(maxWidth: .infinity)
            .lineLimit(1).minimumScaleFactor(0.8)
            Button { edit(i) { $0.warmSets = min(5, $0.warmSets + 1) } } label: {
                Text("+").sa(20, .medium).foregroundColor(Tokens.text).frame(width: 40, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Meer warming-upsets")
        }
        .frame(maxWidth: .infinity).frame(height: 44)
        .card(Tokens.raised, radius: Radius.field)
    }

    /// Rij 2: rep range van-tot.
    private func repRange(_ i: Int, _ it: DraftItem) -> some View {
        let maxText: String = it.repsMax.map { String($0) } ?? "\u{2013}"
        return VStack(alignment: .leading, spacing: 6) {
            Text("Rep range").sa(12, .semibold, tracking: 0.4).foregroundColor(Tokens.text3)
            HStack(spacing: 8) {
                counter(value: String(it.reps), unit: " reps", minus: "Minder reps", plus: "Meer reps",
                        onMinus: { edit(i) { $0.reps = max(1, $0.reps - 1) } },
                        onPlus: { edit(i) { $0.repsUp() } })
                counter(value: maxText, unit: " tot", minus: "Minder maximum reps", plus: "Meer maximum reps",
                        onMinus: { edit(i) { $0.maxDown() } },
                        onPlus: { edit(i) { $0.maxUp() } })
            }
        }
        .padding(.top, 12).padding(.trailing, 8)
    }

    private func presetRow(_ i: Int, _ it: DraftItem) -> some View {
        HStack(spacing: 6) {
            Text("Advies rep range").sa(12, .medium).foregroundColor(Tokens.text3)
            ForEach(0..<EditorScreen.presets.count, id: \.self) { k in
                presetChip(i, it, EditorScreen.presets[k])
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    private func presetChip(_ i: Int, _ it: DraftItem, _ p: (title: String, lo: Int, hi: Int)) -> some View {
        let on = it.reps == p.lo && it.repsMax == p.hi
        let fill: Color = on ? ac.accentSoft : Tokens.raised
        let text: Color = on ? Tokens.text : Tokens.text2
        return Button { edit(i) { $0.reps = p.lo; $0.repsMax = p.hi } } label: {
            Text(p.title).sa(13, .semibold, mono: true)
                .foregroundColor(text)
                .padding(.horizontal, 12).frame(height: 32)
                .background(Capsule().fill(fill))
        }
        .buttonStyle(.plain)
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
        if d.items[i - 1].isWarmup != d.items[i].isWarmup { return }
        d.items.swapAt(i, i - 1)
        EditorScreen.normalize(&d)
        model.draft = d
    }

    private func remove(_ i: Int) {
        guard var d = model.draft, d.items.indices.contains(i) else { return }
        d.items.remove(at: i)
        EditorScreen.normalize(&d)
        model.draft = d
    }

    /// Warming-ups staan vooraan en zijn nooit gekoppeld; de eerste echte oefening heeft niets om aan te koppelen.
    static func normalize(_ d: inout Draft) {
        var seenWork = false
        for k in d.items.indices {
            if d.items[k].isWarmup {
                d.items[k].link = false
            } else if !seenWork {
                d.items[k].link = false
                seenWork = true
            }
        }
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
