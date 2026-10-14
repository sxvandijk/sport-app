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

    private var keepsKeyboard: Bool {
        switch kind {
        case .add, .swap, .change, .pref, .superset, .machineadd, .draftswap: return true
        default: return false
        }
    }

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
        case .change: return ("Oefening wisselen", name)
        case .pref: return ("Voorkeur kiezen", name.isEmpty ? "" : "Wat wil je doen als \(name) bezet is? Tik op de ster bij je keuze.")
        case .swap: return ("Machine bezet", name.isEmpty ? "" : "Vervang \(name) voor nu. Gedane sets blijven staan.")
        case .superset: return ("Superset", name.isEmpty ? "" : "Koppel oefeningen aan \(name). Je wisselt na elke set.")
        case .add:
            if model.addToDraftWarmup { return ("Warming-up toevoegen", "Komt vooraan in deze training") }
            return ("Oefening toevoegen", model.addToDraft ? "Wordt onderaan je schema gezet" : "Wordt onderaan je workout gezet")
        case .program: return ("Kies je schema", "Je schema bepaalt welke trainingen je op het startscherm ziet.")
        case .tplmenu: return (model.tmName ?? "", "Opties voor deze training")
        case .exmenu: return (name, "Opties voor deze oefening")
        case .swapscope: return ("Oefening wisselen", name.isEmpty ? "" : "Wanneer wil je \(name) wisselen?")
        case .settype: return ("Soort set", name)
        case .gym: return ("Kies je gym", "Machine bezet en de plus/min-stappen volgen de apparaten van deze gym.")
        case .draftswap: return ("Oefening wisselen", model.draft?.items.first(where: { $0.id == model.draftSwapID })?.name ?? "")
        case .machineadd: return ("Apparaat toevoegen", "Kies merk en type. Je past de stappen daarna aan.")
        case .machineedit: return (model.machine(model.machineEditID)?.title ?? "Apparaat", "Stappen en gekoppelde oefeningen")
        }
    }

    var body: some View {
        GeometryReader { geo in
            let inset = geo.safeAreaInsets.bottom
            let maxHeight = min(740, geo.size.height - 40)
            Group {
                if keepsKeyboard {
                    // Zoek-schermen: altijd dezelfde opbouw, anders verdwijnt het toetsenbord tijdens het typen.
                    sheet(scrolls: true, inset: inset).frame(height: maxHeight)
                } else {
                    ViewThatFits(in: .vertical) {
                        sheet(scrolls: false, inset: inset).frame(maxHeight: .infinity, alignment: .bottom)
                        sheet(scrolls: true, inset: inset).frame(height: maxHeight)
                    }
                }
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
                    if kind == .machineadd || kind == .machineedit {
                        Icon.check(20, 2.6).foregroundColor(ac.onAccent).frame(width: 36, height: 36)
                            .background(Circle().fill(ac.accentLine))
                            .frame(width: 44, height: 44).contentShape(Rectangle())
                    } else {
                        Icon.close(20).foregroundColor(Tokens.text2).frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(kind == .machineadd || kind == .machineedit ? "Klaar" : "Sluiten")
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
        .glassSurface(TopRounded(radius: 28), fallback: Tokens.surface)
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
        case .swap: SwapSheet(mode: .busy)
        case .change: SwapSheet(mode: .change)
        case .pref: SwapSheet(mode: .pref)
        case .superset: SupersetSheet()
        case .add: SearchList(mode: .add)
        case .settype: SetTypeSheet()
        case .gym: GymSheet()
        case .draftswap: SearchList(mode: .draftSwap)
        case .machineadd: MachineAddSheet()
        case .machineedit: MachineEditSheet()
        case .program: ProgramSheet()
        case .tplmenu: TemplateMenuSheet()
        case .exmenu: ExerciseMenuSheet()
        case .swapscope: SwapScopeSheet()
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

    private var exercise: LiveExercise? { model.session?.exercise(model.sheetEx) }

    private func plainRow(_ icon: Icon, _ tint: Color, _ title: String, _ sub: String, danger: Bool = false, action: @escaping () -> Void) -> some View {
        SheetRowButton(action: action) {
            HStack(spacing: 12) {
                icon.foregroundColor(tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).sa(17, .medium).foregroundColor(danger ? Tokens.danger : Tokens.text)
                    Text(sub).sa(13).foregroundColor(Tokens.text2)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16).frame(minHeight: 60)
        }
        .padding(.bottom, 6)
    }

    private var skipTexts: (title: String, sub: String) {
        guard let ex = exercise else { return ("Vandaag overslaan", "") }
        let done = ex.sets.filter { $0.done }.count
        let open = ex.sets.count - done
        if done == 0 { return ("Oefening vandaag overslaan", "Je schema blijft zoals het is.") }
        if open == 0 { return ("Alle sets zijn al gedaan", "") }
        return (open == 1 ? "Resterende set overslaan" : "Resterende \(open) sets overslaan",
                "Je \(done == 1 ? "gedane set blijft" : "\(done) gedane sets blijven") bewaard. De oefening telt dan als voltooid.")
    }

    var body: some View {
        plainRow(Icon.plus(20), Tokens.warm, "Warming-upset toevoegen", "Ongeveer de helft van je eerste werkset") {
            if let id = model.sheetEx { model.addWarmup(id) }
            model.closeSheet()
        }

        SheetRowButton(action: {
            let id = model.sheetEx
            model.openSheet(.swapscope, exID: id)
        }) {
            HStack(spacing: 12) {
                Icon.swap(20).foregroundColor(Tokens.text)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Oefening wisselen").sa(17, .medium).foregroundColor(Tokens.text)
                    Text("Voor vandaag of vast in je schema").sa(13).foregroundColor(Tokens.text2)
                }
                Spacer(minLength: 0)
                Icon.chevronRight(16).foregroundColor(Tokens.text3)
            }
            .padding(.horizontal, 16).frame(minHeight: 60)
        }
        .padding(.bottom, 6)

        let skip = skipTexts
        plainRow(Icon.skip(20), Tokens.text, skip.title, skip.sub) {
            if let id = model.sheetEx { model.skipExercise(id, removeFromSchema: false) }
        }
        plainRow(Icon.trash(20), Tokens.danger, "Verwijderen uit schema", "Weg uit vandaag en uit je schema.", danger: true) {
            guard let id = model.sheetEx else { return }
            model.confirm = ConfirmRequest(title: "Uit je schema verwijderen?",
                                           message: "\(exercise?.name ?? "Deze oefening") staat daarna niet meer in je training.",
                                           confirmTitle: "Verwijder uit schema") {
                model.skipExercise(id, removeFromSchema: true)
            }
        }
    }
}

private struct SwapScopeSheet: View {
    @EnvironmentObject private var model: AppModel

    private func row(_ title: String, _ sub: String, _ scope: SwapScope) -> some View {
        SheetRowButton(action: {
            let id = model.sheetEx
            model.openSheet(.change, exID: id)
            model.swapScope = scope
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).sa(17, .medium).foregroundColor(Tokens.text)
                    Text(sub).sa(13).foregroundColor(Tokens.text2)
                }
                Spacer(minLength: 0)
                Icon.chevronRight(16).foregroundColor(Tokens.text3)
            }
            .padding(.horizontal, 16).frame(minHeight: 64)
        }
        .padding(.bottom, 8)
    }

    var body: some View {
        row("Voor vandaag", "Alleen in deze workout. Je schema blijft zoals het is.", .now)
        row("Vast in schema", "De oefening wordt ook in je schema vervangen.", .schema)
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
    enum Mode { case busy, change, pref }

    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    let mode: Mode

    /// Laat zien wat je gaat doen.
    private func scopeLabel(_ name: String) -> some View {
        let text = model.swapScope == .schema ? "\(name) vast in je schema wisselen" : "\(name) voor deze keer wisselen"
        return HStack(spacing: 8) {
            Icon.swap(16).foregroundColor(ac.accentText)
            Text(text).sa(14, .semibold).foregroundColor(ac.accentText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: Radius.field, style: .continuous).fill(ac.accentSoft))
    }

    /// Wat er vervangen wordt, vooral handig midden in een oefening.
    private func replaceInfo(_ ex: LiveExercise) -> String {
        let total = ex.sets.count
        let open = ex.sets.filter { !$0.done }.count
        var text: String
        if open == 0 {
            text = "Alle sets van \(ex.name) zijn al gedaan, dus er is niets te vervangen."
        } else if open == total {
            text = "Vervangt alle \(total) \(total == 1 ? "set" : "sets") van \(ex.name)."
        } else if open == 1 {
            text = "Vervangt het laatste setje. Je gedane sets blijven bij \(ex.name)."
        } else {
            text = "Vervangt de laatste \(open) sets. Je gedane sets blijven bij \(ex.name)."
        }
        if model.swapScope == .schema { text += " Je schema krijgt de nieuwe oefening ook." }
        return text
    }

    var body: some View {
        let ex = model.session?.exercise(model.sheetEx)
        let name = ex?.name ?? ""
        let original = ex?.from ?? name
        let inWorkout = model.session?.exercises.map { $0.name } ?? []
        let suggestion = Catalog.suggestion(for: name, excluding: inWorkout)
        let preference = model.prefs[original]

        if mode != .pref, let ex = ex {
            if mode == .change { scopeLabel(name).padding(.bottom, 8) }
            Text(replaceInfo(ex)).sa(13).foregroundColor(Tokens.text2).padding(.bottom, 14).padding(.horizontal, 2)
        }
        swapList(original: original, suggestion: suggestion, preference: preference)
    }

    @ViewBuilder
    private func swapList(original: String, suggestion: String, preference: String?) -> some View {
        if mode != .pref, model.session?.exercise(model.sheetEx)?.from != nil {
            SectionLabel(text: "Terug naar het origineel").padding(.top, 4).padding(.bottom, 8)
            SheetRowButton(action: { model.swapExercise(to: original, manual: false) }) {
                HStack(spacing: 12) {
                    TitleSub(title: original, sub: Catalog.meta(original))
                    Spacer(minLength: 0)
                    Icon.swap(20).foregroundColor(Tokens.text)
                }
                .padding(.horizontal, 16).padding(.vertical, 8).frame(minHeight: 60)
            }
        }
        if mode != .pref {
            let same = preference == suggestion
            SectionLabel(text: same ? "Suggestie en jouw voorkeur" : "Suggestie van de app").padding(.top, 20).padding(.bottom, 8)
            SheetRowButton(action: { model.swapExercise(to: suggestion, manual: false) }) {
                HStack(spacing: 12) {
                    if same { Icon.starFilled(20).foregroundColor(ac.accentText) }
                    VStack(alignment: .leading, spacing: 2) {
                        TitleSub(title: suggestion, sub: Catalog.meta(suggestion))
                        if same {
                            Text("De app raadt deze aan en het is ook je voorkeur.").sa(12).foregroundColor(ac.accentText)
                        }
                    }
                    Spacer(minLength: 0)
                    Icon.swap(20).foregroundColor(Tokens.text)
                }
                .padding(.horizontal, 16).padding(.vertical, 8).frame(minHeight: 60)
            }
        }

        if let pref = preference, pref != suggestion || mode == .pref {
            SectionLabel(text: "Mijn voorkeur").padding(.top, mode == .pref ? 4 : 20).padding(.bottom, 8)
            SheetRowButton(action: { if mode != .pref { model.swapExercise(to: pref, manual: false) } }) {
                HStack(spacing: 12) {
                    Icon.starFilled(20).foregroundColor(ac.accentText)
                    TitleSub(title: pref, sub: Catalog.meta(pref))
                    Spacer(minLength: 0)
                    if mode != .pref { Icon.swap(20).foregroundColor(Tokens.text) }
                }
                .padding(.horizontal, 16).padding(.vertical, 8).frame(minHeight: 60)
            }
            if mode == .pref {
                Button { model.clearPreference(for: original) } label: {
                    Text("Voorkeur wissen").sa(14, .medium).foregroundColor(Tokens.text2).frame(height: 40, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        } else if preference == nil && mode == .pref {
            SectionLabel(text: "Mijn voorkeur").padding(.top, 4).padding(.bottom, 8)
            Text("Nog geen voorkeur. Tik hieronder op de ster bij een oefening.")
                .sa(15).foregroundColor(Tokens.text2).padding(.vertical, 4)
        }

        SectionLabel(text: mode == .pref ? "Oefeningen" : "Zelf kiezen").padding(.top, 20).padding(.bottom, 8)
        SearchList(mode: mode == .pref ? .preference : .swap, showStar: true)
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
    enum Mode { case add, swap, superset, preference, draftSwap }

    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    let mode: Mode
    var showStar = false
    @State private var creating = false
    @State private var newKind: ExerciseKind = .weights
    @State private var newMuscle = "Overig"
    @State private var muscleFilter: String?
    @State private var sort = SortMode.az

    enum SortMode { case standard, az, muscle, equipment }

    private static let muscles = ["Borst", "Schouders", "Triceps", "Biceps", "Onderarmen", "Lats", "Bovenrug", "Traps",
                                  "Quadriceps", "Hamstrings", "Billen", "Kuiten", "Core", "Cardio", "Overig"]

    private func results() -> [(name: String, info: ExerciseInfo)] {
        let q = model.query.lowercased().trimmingCharacters(in: .whitespaces)
        let current = model.session?.exercise(model.sheetEx)
        let pool: [(name: String, info: ExerciseInfo)] = Catalog.all + Catalog.custom.keys.sorted().map { (name: $0, info: Catalog.info($0)) }
        var names = pool.filter { item in
            if mode == .swap || mode == .preference, let c = current, item.name == c.name { return false }
            if let m = muscleFilter, item.info.muscle != m { return false }
            return q.isEmpty || item.name.lowercased().contains(q) || item.info.muscle.lowercased().contains(q)
        }
        if model.addToDraftWarmup && q.isEmpty && muscleFilter == nil {
            let first = names.filter { Catalog.warmupNames.contains($0.name) }
            names = first + names.filter { !Catalog.warmupNames.contains($0.name) }
        } else if (mode == .swap || mode == .preference) && q.isEmpty && muscleFilter == nil, let c = current {
            let muscle = Catalog.info(c.name).muscle
            let same = names.filter { $0.info.muscle == muscle }
            let other = names.filter { $0.info.muscle != muscle }
            names = same + other
        }
        switch sort {
        case .standard: break
        case .az: names.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .muscle: names.sort { ($0.info.muscle, $0.name.lowercased()) < ($1.info.muscle, $1.name.lowercased()) }
        case .equipment: names.sort { ($0.info.equipment, $0.name.lowercased()) < ($1.info.equipment, $1.name.lowercased()) }
        }
        // Je voorkeur staat altijd bovenaan.
        if showStar, let i = names.firstIndex(where: { $0.name == model.prefs[originalName] }) {
            let p = names.remove(at: i)
            names.insert(p, at: 0)
        }
        return names
    }

    private func groupLabel(_ item: (name: String, info: ExerciseInfo)) -> String? {
        if showStar && item.name == model.prefs[originalName] { return nil }
        switch sort {
        case .muscle: return item.info.muscle
        case .equipment: return item.info.equipment
        default: return nil
        }
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
            filterRow.padding(.top, 8)
            Spacer().frame(height: 4)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<shown.count, id: \.self) { i in
                    if let label = groupLabel(shown[i]), i == 0 || groupLabel(shown[i - 1]) != label {
                        SectionLabel(text: label).padding(.top, i == 0 ? 6 : 14).padding(.bottom, 2)
                    }
                    row(shown[i])
                }
                if shown.isEmpty {
                    Text("Niets gevonden.").sa(15).foregroundColor(Tokens.text2).padding(.horizontal, 4).padding(.vertical, 12)
                }
            }
            // Vaste minimale hoogte: de lijst springt niet omlaag als er minder resultaten zijn.
            .frame(maxWidth: .infinity, minHeight: 420, alignment: .topLeading)
            createSection
        }
    }

    private var originalName: String {
        let ex = model.session?.exercise(model.sheetEx)
        return ex?.from ?? ex?.name ?? ""
    }

    private func row(_ item: (name: String, info: ExerciseInfo)) -> some View {
        let chosen = mode == .superset && model.selectedNew.contains(item.name)
        let isPref = model.prefs[originalName] == item.name
        return rowContent(item, chosen: chosen, isPref: isPref)
            .background(RoundedRectangle(cornerRadius: Radius.field, style: .continuous).fill(isPref && showStar ? ac.accentSoft.opacity(0.5) : Color.clear))
    }

    private func rowContent(_ item: (name: String, info: ExerciseInfo), chosen: Bool, isPref: Bool) -> some View {
        HStack(spacing: 4) {
            Button { pick(item.name) } label: {
                HStack(spacing: 12) {
                    TitleSub(title: item.name, sub: Catalog.meta(item.name), titleSize: 17, titleWeight: .medium)
                    Spacer(minLength: 0)
                    if mode != .preference {
                        iconFor(chosen: chosen)
                            .foregroundColor(chosen ? ac.onAccent : Tokens.text)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(chosen ? ac.accentLine : Tokens.raised))
                    }
                }
                .padding(.horizontal, 4).padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if showStar {
                Button { model.togglePreference(original: originalName, choice: item.name) } label: {
                    (isPref ? Icon.starFilled(20) : Icon.star(20)).foregroundColor(isPref ? ac.accentText : Tokens.text3)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPref ? "Voorkeur, tik om te wissen" : "Maak dit je voorkeur")
            }
        }
    }

    private var filterRow: some View {
        HStack(spacing: 8) {
            Menu {
                Button { muscleFilter = nil } label: { Label("Alle spiergroepen", systemImage: muscleFilter == nil ? "checkmark" : "circle") }
                ForEach(Catalog.muscleGroups, id: \.self) { m in
                    Button { muscleFilter = m } label: { Label(m, systemImage: muscleFilter == m ? "checkmark" : "circle") }
                }
            } label: {
                filterLabel(Icon.filter(18), muscleFilter ?? "Alle spiergroepen", active: muscleFilter != nil)
            }
            .accessibilityLabel("Filter op spiergroep")
            Menu {
                Button { sort = .az } label: { Label("A\u{2013}Z", systemImage: sort == .az ? "checkmark" : "circle") }
                Button { sort = .muscle } label: { Label("Spiergroep", systemImage: sort == .muscle ? "checkmark" : "circle") }
                Button { sort = .equipment } label: { Label("Apparaat", systemImage: sort == .equipment ? "checkmark" : "circle") }
            } label: {
                filterLabel(Icon.sort(18), sort == .muscle ? "Spiergroep" : (sort == .equipment ? "Apparaat" : "A\u{2013}Z"), active: false)
            }
            .accessibilityLabel("Sorteren")
            Spacer(minLength: 0)
        }
    }

    private func filterLabel(_ icon: Icon, _ text: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            icon
            Text(text).sa(14, .medium).lineLimit(1)
            Icon.chevronDown(12, 2.4)
        }
        .foregroundColor(active ? ac.onAccent : Tokens.text)
        .padding(.horizontal, 14).frame(height: 40)
        .background(Capsule().fill(active ? ac.accentLine : Tokens.raised))
    }

    private func chip(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).sa(14, .medium)
                .foregroundColor(on ? ac.onAccent : Tokens.text)
                .padding(.horizontal, 14).frame(height: 36)
                .background(Capsule().fill(on ? ac.accentLine : Tokens.raised))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
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
        case .swap, .preference, .draftSwap: return Icon.swap(16)
        case .add: return Icon.plus(16, 2.6)
        case .superset: return chosen ? Icon.check(16, 2.6) : Icon.plus(16, 2.6)
        }
    }

    private func pick(_ name: String) {
        switch mode {
        case .add:
            if model.addToDraftWarmup {
                model.addDraftWarmup(name)
            } else if model.addToDraft {
                guard var d = model.draft else { return }
                let w = Catalog.info(name).defaultWeight
                d.items.append(DraftItem(name: name, warmSets: 0, warmW: nil, sets: Catalog.kind(name) == .cardio ? 1 : 3,
                                         reps: Catalog.kind(name) == .cardio ? 10 : 8,
                                         repsMax: Catalog.kind(name) == .cardio ? nil : 12, w: w, link: false))
                model.draft = d
                model.sheet = nil
            } else {
                model.addExercise(name)
            }
        case .swap, .preference:
            model.swapExercise(to: name, manual: true)
        case .draftSwap:
            if let id = model.draftSwapID { model.replaceDraftItem(id, with: name) }
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
        // De actieve gym staat bovenaan en heeft een kleurtje.
        let ordered = model.gyms.sorted { a, _ in a.id == model.gym.id }
        ForEach(ordered) { g in
            let active = g.id == model.gym.id
            HStack(spacing: 0) {
                Button { model.chooseGym(g.id) } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(g.name).sa(17, .semibold).foregroundColor(active ? ac.accentText : Tokens.text).lineLimit(1)
                            if active { Text("Actief").sa(11, .bold, tracking: 0.4).foregroundColor(ac.accentText) }
                        }
                        Text(g.summary).sa(13).foregroundColor(Tokens.text2)
                    }
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button {
                    let id = g.id
                    model.sheet = nil
                    model.nameEdit = NameEdit(title: "Gym hernoemen", subtitle: g.name, placeholder: "Nieuwe naam", text: g.name, confirmTitle: "Bewaar") { model.renameGym(id, to: $0) }
                } label: {
                    Icon.edit(18).foregroundColor(Tokens.text2).frame(width: 48, height: 48).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hernoem \(g.name)")
            }
            .background(RoundedRectangle(cornerRadius: Radius.row, style: .continuous).fill(active ? ac.accentSoft : Tokens.raised))
            .padding(.bottom, 6)
        }
        SheetRowButton(action: {
            model.sheet = nil
            model.nameEdit = NameEdit(title: "Nieuwe gym", placeholder: "Naam van de gym", text: "", confirmTitle: "Maak aan") { model.addGym(name: $0) }
        }) {
            actionRow(icon: Icon.plus(18, 2.4), title: "Nieuwe gym", color: ac.accentText)
        }
        .padding(.bottom, 6)
        if model.gyms.count > 1 {
            SheetRowButton(action: {
                let g = model.gym
                model.confirm = ConfirmRequest(title: "\(g.name) verwijderen?",
                                               message: "Alle apparaten en stappen van deze gym gaan weg. Je trainingen blijven bewaard.",
                                               confirmTitle: "Verwijder gym") { model.deleteGym(g.id) }
            }) {
                actionRow(icon: Icon.trash(18), title: "Verwijder \(model.gym.name)", color: Tokens.danger)
            }
        }
    }

    private func actionRow(icon: Icon, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            icon.foregroundColor(color).frame(width: 24)
            Text(title).sa(16, .semibold).foregroundColor(color).lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).frame(minHeight: 54)
    }
}

private struct MachineAddSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @State private var brand: String?

    private func results() -> [MachineModel] {
        let q = model.query.lowercased().trimmingCharacters(in: .whitespaces)
        return MachineDB.all.filter { m in
            if let b = brand, m.brand != b { return false }
            return q.isEmpty || m.name.lowercased().contains(q) || m.brand.lowercased().contains(q)
                || m.exercises.contains { $0.lowercased().contains(q) }
        }
    }

    var body: some View {
        let shown = results()
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Icon.search(18).foregroundColor(Tokens.text2)
                TextField("Zoek merk of apparaat", text: $model.query)
                    .sa(16).foregroundColor(Tokens.text)
                    .disableAutocorrection(true)
                    .frame(height: 44)
            }
            .padding(.horizontal, 14).frame(height: 48)
            .card(Tokens.raised, radius: Radius.field)

            Menu {
                Button { brand = nil } label: { Label("Alle merken", systemImage: brand == nil ? "checkmark" : "circle") }
                ForEach(MachineDB.brands, id: \.self) { b in
                    Button { brand = b } label: { Label(b, systemImage: brand == b ? "checkmark" : "circle") }
                }
            } label: {
                HStack(spacing: 6) {
                    Icon.filter(18)
                    Text(brand ?? "Alle merken").sa(14, .medium).lineLimit(1)
                    Icon.chevronDown(12, 2.4)
                }
                .foregroundColor(brand != nil ? ac.onAccent : Tokens.text)
                .padding(.horizontal, 14).frame(height: 40)
                .background(Capsule().fill(brand != nil ? ac.accentLine : Tokens.raised))
            }
            .padding(.top, 8)
            .accessibilityLabel("Filter op merk")

            Button {
                let id = model.addCustomMachine(name: model.query)
                model.machineEditID = id
                model.openSheet(.machineedit)
            } label: {
                HStack(spacing: 12) {
                    Icon.plus(18).foregroundColor(ac.accentText)
                    Text(model.query.trimmingCharacters(in: .whitespaces).isEmpty ? "Eigen apparaat maken" : "Eigen apparaat \u{201C}\(model.query)\u{201D} maken")
                        .sa(16, .semibold).foregroundColor(ac.accentText).lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 4).frame(minHeight: 52).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(shown) { m in
                    let have = model.hasMachine(m)
                    if brand == nil, m.id == shown.first(where: { $0.brand == m.brand })?.id {
                        SectionLabel(text: m.brand).padding(.top, 10).padding(.bottom, 2)
                    }
                    Button { model.addMachine(m) } label: {
                        HStack(spacing: 12) {
                            TitleSub(title: m.name, sub: m.brand + " \u{00B7} " + m.series, titleSize: 17, titleWeight: .medium)
                            Spacer(minLength: 0)
                            (have ? Icon.check(16) : Icon.plus(16))
                                .foregroundColor(have ? ac.onAccent : Tokens.text)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(have ? ac.accentLine : Tokens.raised))
                        }
                        .padding(.horizontal, 4).padding(.vertical, 8)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                if shown.isEmpty {
                    Text("Niets gevonden. Maak een eigen apparaat.").sa(15).foregroundColor(Tokens.text2).padding(.horizontal, 4).padding(.vertical, 12)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 360, alignment: .topLeading)
        }
        .onDisappear { model.query = "" }
    }

}

private struct MachineEditSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    private static let stepChoices: [Double] = [0.5, 1, 1.25, 1.5, 2, 2.5, 3, 4, 4.5, 5, 7.5, 10]
    private static let addOnChoices: [Double] = [0.5, 1, 1.25, 1.5, 2, 2.5, 3, 4, 5]

    var body: some View {
        if let m = model.machine(model.machineEditID) {
            let id = m.id
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Icon.machine(24).foregroundColor(ac.accentText)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(ac.accentSoft))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(m.stepsText).sa(15, .medium).foregroundColor(Tokens.text)
                        Text(m.exercises.isEmpty ? "Nog geen oefeningen gekoppeld" : "\(m.exercises.count) gekoppelde oefening" + (m.exercises.count == 1 ? "" : "en"))
                            .sa(13).foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 8)
                adjustRow("Eerste stand (kg)", value: m.min, delta: m.step > 0 ? m.step : 5) { v in
                    model.updateMachine(id) { $0.min = Swift.max(0, Swift.min(v, $0.max)) }
                }
                adjustRow("Zwaarste stand (kg)", value: m.max, delta: m.step > 0 ? m.step : 5) { v in
                    model.updateMachine(id) { $0.max = Swift.max(v, $0.min) }
                }
                HStack {
                    Text("Stap per stand").sa(16, .medium).foregroundColor(Tokens.text)
                    Spacer(minLength: 0)
                    Menu {
                        ForEach(Self.stepChoices, id: \.self) { v in
                            Button(GymMachine.fmt(v) + " kg") { model.updateMachine(id) { $0.step = v } }
                        }
                    } label: { valuePill(m.step > 0 ? GymMachine.fmt(m.step) + " kg" : "Kies") }
                }
                .frame(minHeight: 52)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Extra plaatje").sa(16, .medium).foregroundColor(Tokens.text)
                        Text("Schuif of pin die je bovenop een stand zet").sa(12).foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                    Menu {
                        Button("Geen") { model.updateMachine(id) { $0.addOn = nil } }
                        ForEach(Self.addOnChoices, id: \.self) { v in
                            Button("+" + GymMachine.fmt(v) + " kg") { model.updateMachine(id) { $0.addOn = v } }
                        }
                    } label: { valuePill(m.addOn.map { "+" + GymMachine.fmt($0) + " kg" } ?? "Geen") }
                }
                .frame(minHeight: 52)

                SectionLabel(text: "Oefeningen op dit apparaat").padding(.top, 14).padding(.bottom, 2)
                ForEach(MachineDB.candidates(family: m.family), id: \.self) { name in
                    let on = m.exercises.contains(name)
                    Button {
                        model.updateMachine(id) { mm in
                            if let i = mm.exercises.firstIndex(of: name) { mm.exercises.remove(at: i) } else { mm.exercises.append(name) }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(name).sa(16, .medium).foregroundColor(Tokens.text).lineLimit(1)
                            Spacer(minLength: 0)
                            (on ? Icon.check(16) : Icon.plus(16))
                                .foregroundColor(on ? ac.onAccent : Tokens.text)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(on ? ac.accentLine : Tokens.raised))
                        }
                        .padding(.horizontal, 4).frame(minHeight: 50).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                FlatButton(title: "Verwijder uit deze gym", color: Tokens.danger) {
                    model.confirm = ConfirmRequest(title: "\(m.title) verwijderen?", message: "Dit apparaat gaat uit je gym. De stappen van de gekoppelde oefeningen worden weer standaard.",
                                                   confirmTitle: "Verwijder") { model.removeMachine(id) }
                }.padding(.top, 10)
            }
        } else {
            Text("Apparaat niet gevonden.").sa(15).foregroundColor(Tokens.text2)
        }
    }

    private func valuePill(_ text: String) -> some View {
        HStack(spacing: 6) {
            Text(text).sa(15, .semibold)
            Icon.chevronDown(12, 2.4)
        }
        .foregroundColor(Tokens.text)
        .padding(.horizontal, 14).frame(height: 40)
        .background(Capsule().fill(Tokens.raised))
    }

    private func adjustRow(_ title: String, value: Double, delta: Double, set: @escaping (Double) -> Void) -> some View {
        HStack(spacing: 0) {
            Text(title).sa(16, .medium).foregroundColor(Tokens.text)
            Spacer(minLength: 0)
            Button { set(Swift.max(0, value - delta)) } label: {
                Icon.minus(18).foregroundColor(Tokens.text).frame(width: 44, height: 44).contentShape(Rectangle())
            }.buttonStyle(.plain)
            Text(GymMachine.fmt(value)).sa(16, .semibold, mono: true).foregroundColor(Tokens.text).frame(minWidth: 44)
            Button { set(value + delta) } label: {
                Icon.plus(18, 2.4).foregroundColor(Tokens.text).frame(width: 44, height: 44).contentShape(Rectangle())
            }.buttonStyle(.plain)
        }
        .frame(minHeight: 52)
    }
}

private struct ProgramSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @State private var menuFor: String?
    @State private var confirm = false
    @State private var newName = ""

    var body: some View {
        ForEach(model.programs) { p in
            HStack(spacing: 4) {
                ListRow(title: p.name,
                        sub: p.workouts.isEmpty ? "Nog geen trainingen" : p.workouts.joined(separator: " \u{00B7} "),
                        selected: p.id == model.program.id) { model.chooseProgram(p.id) }
                Button {
                    confirm = false
                    newName = p.name
                    menuFor = menuFor == p.id ? nil : p.id
                } label: {
                    Icon.more(20).foregroundColor(Tokens.text2).frame(width: 44, height: 60).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 6)
                .accessibilityLabel("Opties voor schema \(p.name)")
            }
            if menuFor == p.id { optionsPanel(p) }
        }
        FlatButton(title: "+ Nieuw schema", color: ac.accentText) { model.newProgram() }.padding(.top, 6)
    }

    private func optionsPanel(_ p: PlanProgram) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TextField("Naam van het schema", text: $newName)
                    .sa(16).foregroundColor(Tokens.text)
                    .padding(.horizontal, 12).frame(height: 44)
                    .card(Tokens.surface, radius: Radius.field)
                Button {
                    model.renameProgram(p.id, to: newName)
                    menuFor = nil
                } label: {
                    Text("Opslaan").sa(15, .semibold).foregroundColor(ac.onAccent)
                        .padding(.horizontal, 14).frame(height: 44)
                        .card(ac.accentLine, radius: Radius.field)
                }
                .buttonStyle(.plain)
            }
            if confirm {
                HStack(spacing: 8) {
                    Button { confirm = false } label: {
                        Text("Annuleer").sa(16, .semibold).foregroundColor(Tokens.text)
                            .frame(maxWidth: .infinity).frame(height: 46).card(Tokens.surface, radius: Radius.field)
                    }
                    .buttonStyle(.plain)
                    Button {
                        confirm = false
                        menuFor = nil
                        model.deleteProgram(p.id)
                    } label: {
                        Text("Verwijder schema").sa(16, .bold).foregroundColor(Tokens.onDanger)
                            .frame(maxWidth: .infinity).frame(height: 46).card(Tokens.danger, radius: Radius.field)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button { confirm = true } label: {
                    HStack(spacing: 8) {
                        Icon.trash(18)
                        Text("Schema verwijderen").sa(16, .semibold)
                    }
                    .foregroundColor(Tokens.danger)
                    .frame(height: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .card(Tokens.raised, radius: Radius.row)
        .padding(.bottom, 8)
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
