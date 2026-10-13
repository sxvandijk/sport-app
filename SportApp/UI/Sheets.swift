import SwiftUI

/// Alle sheets uit het prototype, als eigen overlay (scrim + blad onderaan).
struct SheetOverlay: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack(alignment: .bottom) {
            if let kind = model.sheet {
                Tokens.scrim
                    .ignoresSafeArea()
                    .onTapGesture { model.closeSheet() }
                    .accessibilityLabel("Sluiten")
                    .accessibilityAddTraits(.isButton)
                    .transition(.opacity)
                SheetBody(kind: kind)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeOut(duration: 0.22), value: model.sheet)
    }
}

private struct SheetBody: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    let kind: SheetKind

    private var exercise: LiveExercise? { model.session?.exercise(model.sheetEx) }

    private var heading: (title: String, sub: String) {
        let s = model.session
        let name = exercise?.name ?? ""
        switch kind {
        case .menu:
            let t = s.map { $0.name + " · " + Format.clock(seconds: Int(Date().timeIntervalSince($0.startAt))) } ?? ""
            return ("Workout", t)
        case .stop:
            let open = s?.openWorkSets ?? 0
            return ("Workout stoppen?", (open == 1 ? "Er staat nog 1 set open." : "Er staan nog \(open) sets open.") + " Je gedane sets worden bewaard.")
        case .start:
            if let s = s {
                let minutes = max(1, Int((Date().timeIntervalSince(s.startAt) / 60).rounded()))
                return ("Er loopt al een workout", "\(s.name) loopt al \(minutes) min.")
            }
            return ("Er loopt al een workout", "")
        case .explain: return ("Uitleg", name)
        case .swap: return ("Machine bezet", name.isEmpty ? "" : "Vervang \(name) voor de sets die nog open staan. Gedane sets blijven staan.")
        case .superset: return ("Superset", name.isEmpty ? "" : "Koppel oefeningen aan \(name). Je wisselt na elke set.")
        case .add: return ("Oefening toevoegen", model.addToDraft ? "Wordt onderaan je schema gezet" : "Wordt onderaan je workout gezet")
        case .program: return ("Kies je schema", "Je schema bepaalt welke trainingen je op het startscherm ziet.")
        case .tplmenu: return (model.tmName ?? "", "Opties voor deze training")
        case .exmenu: return (name, "Opties voor deze oefening")
        case .settype: return ("Soort set", name)
        case .gym: return ("Kies je gym", "Machine bezet en de plus/min-stappen volgen de apparaten van deze gym.")
        }
    }

    var body: some View {
        GeometryReader { geo in
            let inset = geo.safeAreaInsets.bottom
            let maxHeight = min(740, geo.size.height - 40)
            ViewThatFits(in: .vertical) {
                sheet(scrolls: false, inset: inset).frame(maxHeight: .infinity, alignment: .bottom)
                sheet(scrolls: true, inset: inset).frame(height: maxHeight)
            }
            .frame(maxHeight: maxHeight)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func sheet(scrolls: Bool, inset: CGFloat) -> some View {
        let h = heading
        return VStack(spacing: 0) {
            Capsule().fill(Tokens.line).frame(width: 36, height: 5).padding(.top, 8)
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(h.title).sa(20, .bold, tracking: -0.2).foregroundColor(Tokens.text)
                        .accessibilityAddTraits(.isHeader)
                    if !h.sub.isEmpty {
                        Text(h.sub).sa(14).foregroundColor(Tokens.text2)
                    }
                }
                .padding(.top, 8)
                Spacer(minLength: 0)
                Button { model.closeSheet() } label: {
                    Icon.close(20).foregroundColor(Tokens.text2).frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sluiten")
            }
            .padding(.top, 10).padding(.leading, 20).padding(.trailing, 12).padding(.bottom, 4)

            if scrolls {
                ScrollView { padded }
            } else {
                padded.fixedSize(horizontal: false, vertical: true)
            }
            Color.clear.frame(height: inset)
        }
        .frame(maxWidth: .infinity)
        .background(TopRounded(radius: Radius.sheetTop).fill(Tokens.surface))
    }

    private var padded: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var content: some View {
        switch kind {
        case .menu: MenuSheet()
        case .stop: StopSheet()
        case .start: StartSheet()
        case .explain: ExplainSheet()
        case .swap: SwapSheet()
        case .superset: SupersetSheet()
        case .add: SearchList(mode: .add)
        case .settype: SetTypeSheet()
        case .gym: GymSheet()
        case .program: ProgramSheet()
        case .tplmenu: TemplateMenuSheet()
        case .exmenu: ExerciseMenuSheet()
        }
    }
}

// MARK: - Bouwstenen

private struct CheckMark: View {
    @Environment(\.accentColors) private var ac
    var body: some View { Icon.check(20).foregroundColor(ac.accentText) }
}

private struct ListRow: View {
    let title: String
    let sub: String
    var selected = false
    var minHeight: CGFloat = 60
    let action: () -> Void

    var body: some View {
        SheetRowButton(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).sa(17, .semibold).foregroundColor(Tokens.text)
                    Text(sub).sa(13).foregroundColor(Tokens.text2)
                }
                Spacer(minLength: 0)
                if selected { CheckMark() }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .frame(minHeight: minHeight)
        }
        .padding(.bottom, 6)
    }
}

private struct FlatButton: View {
    let title: String
    var color: Color = Tokens.text
    var height: CGFloat = 52
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).sa(16, .semibold).foregroundColor(color)
                .frame(maxWidth: .infinity).frame(height: height)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Menu, stoppen, starten

private struct MenuSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        SheetRowButton(action: { model.openSheet(.add) }) {
            HStack(spacing: 12) {
                Icon.plus(20)
                Text("Oefening toevoegen").sa(17, .medium)
                Spacer(minLength: 0)
            }
            .foregroundColor(Tokens.text)
            .padding(.horizontal, 16).frame(minHeight: 52)
        }
        SectionLabel(text: "Instellingen").padding(.top, 22).padding(.bottom, 8)
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Warming-up in superset").sa(17, .medium).foregroundColor(Tokens.text)
                Text("Na een warming-upset blijf je bij dezelfde oefening en doe je direct de eerste werkset. Daarna wissel je.")
                    .sa(13).foregroundColor(Tokens.text2).lineSpacing(2)
            }
            Spacer(minLength: 0)
            SAToggle(isOn: model.warmFirst, onColor: ac.accentLine, label: "Warming-up in superset") {
                model.warmFirst.toggle()
                model.save()
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Tokens.raised, radius: Radius.row)

        SheetRowButton(action: { model.openSheet(.stop) }) {
            Text("Workout stoppen").sa(17, .semibold).foregroundColor(Tokens.danger)
                .padding(.horizontal, 16).frame(minHeight: 52, alignment: .leading)
        }
        .padding(.top, 22)
    }
}

private struct ExerciseMenuSheet: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        SheetRowButton(action: {
            if let id = model.sheetEx { model.addWarmup(id) }
            model.closeSheet()
        }) {
            HStack(spacing: 12) {
                Icon.plus(20).foregroundColor(Tokens.warm)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Warming-upset toevoegen").sa(17, .medium).foregroundColor(Tokens.text)
                    Text("Ongeveer de helft van je eerste werkset").sa(13).foregroundColor(Tokens.text2)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16).frame(minHeight: 60)
        }
    }
}

private struct StopSheet: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Button { model.finish(note: "Eerder gestopt. Je gedane sets zijn opgeslagen.") } label: {
            Text("Stoppen en opslaan").sa(17, .bold).foregroundColor(Tokens.onDanger)
                .frame(maxWidth: .infinity).frame(height: 56)
                .card(Tokens.danger, radius: Radius.button)
        }
        .buttonStyle(.plain)
        FlatButton(title: "Workout verwijderen", color: Tokens.danger) { model.discardWorkout() }.padding(.top, 8)
        Button { model.closeSheet() } label: {
            Text("Verder trainen").sa(17, .semibold).foregroundColor(Tokens.text)
                .frame(maxWidth: .infinity).frame(height: 56)
                .card(Tokens.raised, radius: Radius.button)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}

private struct StartSheet: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        let name = model.session?.name ?? ""
        let pending = (model.pending ?? "").isEmpty ? "lege training" : (model.pending ?? "")
        PrimaryButton(title: "Hervat " + name, height: 56) {
            model.sheet = nil
            model.screen = .workout
        }
        Button { model.doStart(model.pending ?? "") } label: {
            Text("Stop \(name) en start \(pending)").sa(17, .semibold).foregroundColor(Tokens.danger)
                .frame(maxWidth: .infinity).frame(height: 56)
                .card(Tokens.raised, radius: Radius.button)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}

// MARK: - Uitleg

private struct ExplainSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        let name = model.session?.exercise(model.sheetEx)?.name ?? ""
        let query = (name + " form").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let yt = URL(string: "https://www.youtube.com/results?search_query=" + query)
        let saved = model.links[name].flatMap { URL(string: $0) }

        if let yt = yt {
            Link(destination: yt) {
                HStack(spacing: 12) {
                    Icon.explain(22)
                    Text("Zoek op YouTube").sa(17, .semibold)
                    Spacer(minLength: 0)
                    Text("opent YouTube").sa(13, .medium).foregroundColor(Tokens.text2)
                }
                .foregroundColor(Tokens.text)
                .padding(.horizontal, 16).frame(minHeight: 56)
                .card(Tokens.raised, radius: Radius.row)
            }
        }
        if let saved = saved {
            Link(destination: saved) {
                HStack(spacing: 12) {
                    Icon.link(20)
                    Text("Open mijn video").sa(17, .bold)
                    Spacer(minLength: 0)
                }
                .foregroundColor(ac.onAccent)
                .padding(.horizontal, 16).frame(minHeight: 56)
                .card(ac.accent, radius: Radius.row)
            }
            .padding(.top, 8)
        }

        SectionLabel(text: "Eigen link").padding(.top, 22).padding(.bottom, 8)
        HStack(spacing: 8) {
            TextField("Plak een link", text: $model.linkDraft)
                .sa(16).foregroundColor(Tokens.text)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding(.horizontal, 14).frame(height: 48)
                .card(Tokens.raised, radius: Radius.field)
            Button { model.saveLink(for: name) } label: {
                Text("Bewaar").sa(16, .bold).foregroundColor(ac.accentText)
                    .padding(.horizontal, 16).frame(height: 48)
                    .card(Tokens.raised, radius: Radius.field)
            }
            .buttonStyle(.plain)
        }
        Text("Een eigen link wordt bij deze oefening bewaard en staat daarna bovenaan.")
            .sa(13).foregroundColor(Tokens.text2).lineSpacing(3).padding(.top, 8)
        if saved != nil {
            Button { model.clearLink(for: name) } label: {
                Text("Link verwijderen").sa(15, .semibold).foregroundColor(Tokens.danger).frame(height: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }
}

// MARK: - Machine bezet

private struct SwapSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        let ex = model.session?.exercise(model.sheetEx)
        let name = ex?.name ?? ""
        let inWorkout = model.session?.exercises.map { $0.name } ?? []
        let suggestion = Catalog.suggestion(for: name, excluding: inWorkout)
        let preference = model.prefs[ex?.from ?? name] ?? model.prefs[name]

        SectionLabel(text: "Suggestie van de app").padding(.top, 4).padding(.bottom, 8)
        SheetRowButton(action: { model.swapExercise(to: suggestion, manual: false) }) {
            HStack(spacing: 12) {
                TitleSub(title: suggestion, sub: Catalog.meta(suggestion))
                Spacer(minLength: 0)
                Icon.swap(20).foregroundColor(Tokens.text)
            }
            .padding(.horizontal, 16).padding(.vertical, 8).frame(minHeight: 60)
        }

        SectionLabel(text: "Mijn voorkeur").padding(.top, 20).padding(.bottom, 8)
        if let pref = preference {
            SheetRowButton(action: { model.swapExercise(to: pref, manual: false) }) {
                HStack(spacing: 12) {
                    Icon.star(20).foregroundColor(ac.accentText)
                    TitleSub(title: pref, sub: Catalog.meta(pref))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16).padding(.vertical, 8).frame(minHeight: 60)
            }
        } else {
            Text("Nog geen voorkeur. Kies hieronder een oefening en zet ‘Bewaar als voorkeur’ aan.")
                .sa(15).foregroundColor(Tokens.text2).padding(.vertical, 4)
        }

        SectionLabel(text: "Zelf kiezen").padding(.top, 20).padding(.bottom, 8)
        SearchList(mode: .swap)

        HStack(spacing: 12) {
            Text("Bewaar mijn keuze als voorkeur").sa(15, .medium).foregroundColor(Tokens.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            SAToggle(isOn: model.savePref, onColor: ac.accentLine, label: "Bewaar als voorkeur") {
                model.savePref.toggle()
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .card(Tokens.raised, radius: Radius.row)
        .padding(.top, 12)
    }
}

// MARK: - Superset

private struct SupersetSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        let s = model.session
        let base = s?.exercise(model.sheetEx)
        let inGroup = base.map { b in (s?.exercises.filter { $0.group == b.group }.count ?? 0) > 1 } ?? false
        let candidates: [LiveExercise] = (s?.exercises ?? []).filter { e in
            guard let b = base else { return false }
            return e.group != b.group && e.sets.contains(where: { !$0.done })
        }
        let count = model.selected.count + model.selectedNew.count

        if inGroup {
            SheetRowButton(action: { model.unlinkSheetExercise() }) {
                Text("Loskoppelen uit superset").sa(17, .semibold).foregroundColor(Tokens.danger)
                    .padding(.horizontal, 16).frame(minHeight: 52, alignment: .leading)
            }
            .padding(.bottom, 4)
        }
        SectionLabel(text: "Uit dit schema").padding(.top, 14).padding(.bottom, 8)
        ForEach(candidates) { e in
            let on = model.selected.contains(e.id)
            SheetRowButton(action: {
                if let i = model.selected.firstIndex(of: e.id) { model.selected.remove(at: i) } else { model.selected.append(e.id) }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(on ? ac.accentLine : Color.clear)
                        Circle().stroke(on ? Color.clear : Tokens.line, lineWidth: 2)
                        if on { Icon.check(14, 3).foregroundColor(ac.onAccent) }
                    }
                    .frame(width: 26, height: 26)
                    TitleSub(title: e.name, sub: LiveSession.summary(of: e.sets, kind: Catalog.kind(e.name)), titleSize: 17, titleWeight: .medium)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16).padding(.vertical, 8).frame(minHeight: 56)
            }
            .padding(.bottom, 6)
            .accessibilityAddTraits(on ? .isSelected : [])
        }
        if candidates.isEmpty {
            Text("Geen andere oefeningen in dit schema.").sa(15).foregroundColor(Tokens.text2).padding(.vertical, 4)
        }
        SectionLabel(text: "Nieuwe oefening zoeken").padding(.top, 20).padding(.bottom, 8)
        SearchList(mode: .superset)

        Button { model.linkSelected() } label: {
            Text(count > 0 ? "Koppelen (\(count))" : "Kies minstens één oefening").sa(17, .bold)
                .foregroundColor(ac.onAccent)
                .frame(maxWidth: .infinity).frame(height: 56)
                .card(ac.accent, radius: Radius.button)
                .opacity(count > 0 ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(count == 0)
        .padding(.top, 16)
    }
}

// MARK: - Zoeken (toevoegen, bezet, superset)

private struct SearchList: View {
    enum Mode { case add, swap, superset }

    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    let mode: Mode
    @State private var creating = false
    @State private var newKind: ExerciseKind = .weights
    @State private var newMuscle = "Overig"

    private static let muscles = ["Borst", "Schouders", "Triceps", "Biceps", "Onderarmen", "Lats", "Bovenrug", "Traps",
                                  "Quadriceps", "Hamstrings", "Billen", "Kuiten", "Core", "Cardio", "Overig"]

    private func results() -> [(name: String, info: ExerciseInfo)] {
        let q = model.query.lowercased().trimmingCharacters(in: .whitespaces)
        let current = model.session?.exercise(model.sheetEx)
        let pool: [(name: String, info: ExerciseInfo)] = Catalog.all + Catalog.custom.keys.sorted().map { (name: $0, info: Catalog.info($0)) }
        var names = pool.filter { item in
            if mode == .swap, let c = current, item.name == c.name { return false }
            return q.isEmpty || item.name.lowercased().contains(q) || item.info.muscle.lowercased().contains(q)
        }
        if mode == .swap && q.isEmpty, let c = current {
            let muscle = Catalog.info(c.name).muscle
            let same = names.filter { $0.info.muscle == muscle }
            let other = names.filter { $0.info.muscle != muscle }
            names = same + other
        }
        return Array(names.prefix(10))
    }

    var body: some View {
        let shown = results()

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Icon.search(18).foregroundColor(Tokens.text2)
                TextField("Zoek oefening of spiergroep", text: $model.query)
                    .sa(16).foregroundColor(Tokens.text)
                    .disableAutocorrection(true)
                    .frame(height: 44)
            }
            .padding(.horizontal, 14).frame(height: 48)
            .card(Tokens.raised, radius: Radius.field)
            Spacer().frame(height: 8)

            ForEach(0..<shown.count, id: \.self) { i in
                let item = shown[i]
                let chosen = mode == .superset && model.selectedNew.contains(item.name)
                Button { pick(item.name) } label: {
                    HStack(spacing: 12) {
                        TitleSub(title: item.name, sub: Catalog.meta(item.name), titleSize: 17, titleWeight: .medium)
                        Spacer(minLength: 0)
                        iconFor(chosen: chosen)
                            .foregroundColor(chosen ? ac.onAccent : Tokens.text)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(chosen ? ac.accentLine : Tokens.raised))
                    }
                    .padding(.horizontal, 4).padding(.vertical, 8)
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            if shown.isEmpty {
                Text("Niets gevonden.").sa(15).foregroundColor(Tokens.text2).padding(.horizontal, 4).padding(.vertical, 12)
            }
            createSection
        }
    }

    private var queryName: String { model.query.trimmingCharacters(in: .whitespaces) }

    @ViewBuilder
    private var createSection: some View {
        let exact = Catalog.allNames.contains(where: { $0.lowercased() == queryName.lowercased() })
        if !queryName.isEmpty && !exact {
            Button { creating.toggle() } label: {
                HStack(spacing: 12) {
                    Icon.plus(16, 2.6).foregroundColor(ac.accentText).frame(width: 32, height: 32)
                        .background(Circle().fill(ac.accentSoft))
                    Text("Eigen oefening: " + queryName).sa(17, .medium).foregroundColor(ac.accentText).lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 4).padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if creating {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Soort", selection: $newKind) {
                        ForEach([ExerciseKind.weights, .bodyweight, .cardio], id: \.self) { k in Text(k.title).tag(k) }
                    }
                    .pickerStyle(.segmented)
                    if newKind != .cardio {
                        HStack {
                            Text("Spiergroep").sa(15).foregroundColor(Tokens.text2)
                            Spacer()
                            Picker("Spiergroep", selection: $newMuscle) {
                                ForEach(SearchList.muscles, id: \.self) { m in Text(m).tag(m) }
                            }
                            .pickerStyle(.menu)
                            .accentColor(ac.accentText)
                        }
                    }
                    PrimaryButton(title: "Toevoegen", height: 52, icon: Icon.plus(20, 2.6)) { createAndPick() }
                }
                .padding(12)
                .card(Tokens.raised, radius: Radius.field)
            }
        }
    }

    private func createAndPick() {
        let muscle = newKind == .cardio ? "Cardio" : newMuscle
        let equipment = newKind == .bodyweight ? "Lichaamsgewicht" : (newKind == .cardio ? "Cardio" : "Eigen")
        if let name = model.addCustomExercise(name: queryName, muscle: muscle, equipment: equipment, kind: newKind) {
            pick(name)
        }
    }

    private func iconFor(chosen: Bool) -> Icon {
        switch mode {
        case .swap: return Icon.swap(16)
        case .add: return Icon.plus(16, 2.6)
        case .superset: return chosen ? Icon.check(16, 2.6) : Icon.plus(16, 2.6)
        }
    }

    private func pick(_ name: String) {
        switch mode {
        case .add:
            if model.addToDraft {
                guard var d = model.draft else { return }
                let w = Catalog.info(name).defaultWeight
                d.items.append(DraftItem(name: name, warm: false, warmW: nil, sets: Catalog.kind(name) == .cardio ? 1 : 3,
                                         reps: Catalog.kind(name) == .cardio ? 10 : 8,
                                         repsMax: Catalog.kind(name) == .cardio ? nil : 12, w: w, link: false))
                model.draft = d
                model.sheet = nil
            } else {
                model.addExercise(name)
            }
        case .swap:
            model.swapExercise(to: name, manual: true)
        case .superset:
            if let i = model.selectedNew.firstIndex(of: name) { model.selectedNew.remove(at: i) } else { model.selectedNew.append(name) }
        }
    }
}

// MARK: - Settype, gym, schema, trainingsmenu

private struct SetTypeSheet: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        let ex = model.session?.exercise(model.sheetEx)
        let current = ex?.sets.first(where: { $0.id == model.sheetSet })
        ForEach(SetType.allCases, id: \.self) { type in
            let color = color(for: type)
            SheetRowButton(action: {
                if let ex = ex, let set = current { model.setType(exID: ex.id, setID: set.id, to: type) }
            }) {
                HStack(spacing: 14) {
                    Text(type.letter).sa(15, .bold).foregroundColor(color)
                        .frame(width: 32, height: 32).background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Tokens.surface))
                    TitleSub(title: type.name, sub: type.detail)
                    Spacer(minLength: 0)
                    if current?.type == type { CheckMark() }
                }
                .padding(.horizontal, 16).padding(.vertical, 8).frame(minHeight: 60)
            }
            .padding(.bottom, 6)
        }
        Button {
            if let ex = ex, let set = current {
                model.sheet = nil
                model.deleteSet(exID: ex.id, setID: set.id)
            }
        } label: {
            Text("Set verwijderen").sa(17, .semibold).foregroundColor(Tokens.danger)
                .padding(.horizontal, 16).frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    private func color(for type: SetType) -> Color {
        switch type {
        case .warmup: return Tokens.warm
        case .drop: return Tokens.drop
        case .failure: return Tokens.danger
        case .work: return Tokens.text
        }
    }
}

private struct GymSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        ForEach(model.gyms) { g in
            ListRow(title: g.name, sub: g.summary, selected: g.id == model.gym.id) { model.chooseGym(g.id) }
        }
        FlatButton(title: "+ Nieuwe gym", color: ac.accentText) { model.closeSheet() }.padding(.top, 6)
    }
}

private struct ProgramSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @State private var confirm: String?

    var body: some View {
        ForEach(model.programs) { p in
            HStack(spacing: 4) {
                ListRow(title: p.name,
                        sub: p.workouts.isEmpty ? "Nog geen trainingen" : p.workouts.joined(separator: " \u{00B7} "),
                        selected: p.id == model.program.id) { model.chooseProgram(p.id) }
                Button { confirm = confirm == p.id ? nil : p.id } label: {
                    Icon.trash(20).foregroundColor(Tokens.danger).frame(width: 48, height: 60).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 6)
                .accessibilityLabel("Verwijder schema \(p.name)")
            }
            if confirm == p.id {
                HStack(spacing: 8) {
                    Button { confirm = nil } label: {
                        Text("Annuleer").sa(16, .semibold).foregroundColor(Tokens.text)
                            .frame(maxWidth: .infinity).frame(height: 48).card(Tokens.raised, radius: Radius.field)
                    }
                    .buttonStyle(.plain)
                    Button {
                        confirm = nil
                        model.deleteProgram(p.id)
                    } label: {
                        Text("Verwijder schema").sa(16, .bold).foregroundColor(Tokens.onDanger)
                            .frame(maxWidth: .infinity).frame(height: 48).card(Tokens.danger, radius: Radius.field)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 8)
            }
        }
        FlatButton(title: "+ Nieuw schema", color: ac.accentText) { model.newProgram() }.padding(.top, 6)
    }
}

private struct TemplateMenuSheet: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        let name = model.tmName ?? ""
        SheetRowButton(action: { model.editTemplate(name) }) {
            HStack(spacing: 12) {
                Icon.edit(20)
                Text("Training aanpassen").sa(17, .medium)
                Spacer(minLength: 0)
            }
            .foregroundColor(Tokens.text)
            .padding(.horizontal, 16).frame(minHeight: 52)
        }
        .padding(.bottom, 6)
        SheetRowButton(action: { model.duplicateTemplate(name) }) {
            HStack(spacing: 12) {
                Icon.duplicate(20)
                Text("Dupliceren").sa(17, .medium)
                Spacer(minLength: 0)
            }
            .foregroundColor(Tokens.text)
            .padding(.horizontal, 16).frame(minHeight: 52)
        }
        .padding(.bottom, 6)
        SheetRowButton(action: { model.removeTemplateFromProgram(name) }) {
            HStack(spacing: 12) {
                Icon.trash(20)
                Text("Verwijderen uit schema").sa(17, .semibold)
                Spacer(minLength: 0)
            }
            .foregroundColor(Tokens.danger)
            .padding(.horizontal, 16).frame(minHeight: 52)
        }
    }
}
