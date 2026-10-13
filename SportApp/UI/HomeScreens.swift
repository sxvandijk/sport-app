import SwiftUI

// MARK: - Tabbalk en minibalk

struct AppTabBar: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    private func icon(_ tab: HomeTab) -> Icon {
        switch tab {
        case .training: return Icon.tabTraining
        case .progress: return Icon.tabProgress
        case .gym: return Icon.tabGym
        case .profile: return Icon.tabProfile
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomeTab.allCases) { tab in
                let on = model.tab == tab
                Button {
                    model.tab = tab
                } label: {
                    VStack(spacing: 3) {
                        icon(tab)
                        Text(tab.title).sa(11, .semibold)
                    }
                    .foregroundColor(on ? ac.accentText : Tokens.text3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 2)
        .padding(.bottom, 4)
        .background(Tokens.bg.ignoresSafeArea(edges: .bottom))
    }
}

struct MiniBar: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        if let s = model.session {
            HStack(spacing: 8) {
                Button {
                    model.screen = .workout
                    model.sheet = nil
                } label: {
                    HStack(spacing: 12) {
                        Circle().fill(ac.accentLine).frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(s.name).sa(16, .semibold).foregroundColor(Tokens.text).lineLimit(1)
                            TimelineView(.periodic(from: Date(), by: 1)) { context in
                                let cur = s.current(focus: nil, warmFirst: model.warmFirst).cur
                                let name = cur.flatMap { s.exercise($0.exID)?.name }
                                let seconds = Int(context.date.timeIntervalSince(s.startAt))
                                Text(Format.clock(seconds: seconds) + (name.map { " · " + $0 } ?? ""))
                                    .sa(13, .regular, mono: true).foregroundColor(Tokens.text2).lineLimit(1)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 12)
                    .frame(height: 60)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open lopende workout")

                Button {
                    model.screen = .workout
                    model.sheet = nil
                } label: {
                    Text("Hervat").sa(16, .bold).foregroundColor(ac.onAccent)
                        .padding(.horizontal, 20).frame(height: 44)
                        .background(Capsule().fill(ac.accent))
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 4)
            .padding(.trailing, 12)
            .frame(height: Size.miniBar)
            .card(Tokens.raised, radius: Radius.card)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Tokens.bg)
        }
    }
}

// MARK: - Container met tabs

struct HomeContainer: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch model.tab {
                    case .training: TrainingTab()
                    case .progress: ProgressTab()
                    case .gym: GymTab()
                    case .profile: ProfileTab()
                    }
                }
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            MiniBar()
            AppTabBar()
        }
        .background(Tokens.bg.ignoresSafeArea())
    }
}

private struct ScreenTitle: View {
    let text: String
    var body: some View {
        Text(text).sa(34, .bold, tracking: -0.6).foregroundColor(Tokens.text)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Training

struct TrainingTab: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        let now = Date()
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text(DateText.long(now)).sa(13, .medium).foregroundColor(Tokens.text2).lineLimit(1)
                Spacer(minLength: 0)
                Button {
                    model.openSheet(.gym)
                } label: {
                    HStack(spacing: 5) {
                        Icon.pin(16)
                        Text(model.gym.name).sa(14, .semibold)
                        Icon.chevronDown(14)
                    }
                    .foregroundColor(Tokens.text)
                    .padding(.leading, 8).padding(.trailing, 10)
                    .frame(height: 32)
                    .background(Capsule().fill(Tokens.raised))
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Gym: \(model.gym.name). Tik om te wisselen")
            }
            ScreenTitle(text: "Training")

            CalendarCard(expandable: true).padding(.top, 14)

            HStack(alignment: .center) {
                SectionLabel(text: "Mijn schema")
                Spacer(minLength: 0)
                Button { model.openSheet(.program) } label: {
                    HStack(spacing: 6) {
                        Icon.updown(16)
                        Text("Wissel schema").sa(14, .semibold)
                    }
                    .foregroundColor(ac.accentText)
                    .padding(.horizontal, 12).frame(height: 34)
                    .background(Capsule().fill(ac.accentSoft))
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Wissel schema")
            }
            .padding(.top, 14)
            programButton
            Spacer().frame(height: 8)
            ForEach(model.program.workouts, id: \.self) { name in
                templateRow(name)
            }
            if model.program.workouts.isEmpty {
                Text("Dit schema heeft nog geen trainingen.").sa(15).foregroundColor(Tokens.text2)
                    .padding(.horizontal, 4).padding(.vertical, 16)
            }
            Button {
                model.newTemplate()
            } label: {
                HStack(spacing: 6) {
                    Icon.plus(18, 2.4)
                    Text("Training toevoegen aan schema").sa(15, .semibold)
                }
                .foregroundColor(ac.accentText)
                .frame(maxWidth: .infinity).frame(height: 44)
            }
            .buttonStyle(.plain)

            Button {
                model.askStart("")
            } label: {
                HStack(spacing: 14) {
                    Icon.plus(20).foregroundColor(Tokens.text)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Tokens.raised))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vrije training").sa(17, .semibold).foregroundColor(Tokens.text)
                        Text("Kies je oefeningen tijdens het trainen").sa(13).foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .card(Tokens.surface, radius: Radius.button)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
    }

    private var programButton: some View {
        let prog = model.program
        let next = model.nextWorkoutName()
        let count = prog.workouts.count
        var sub = "\(count) \(count == 1 ? "training" : "trainingen")"
        if let next = next { sub += " · volgende: " + next }
        return Button {
            model.openSheet(.program)
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(prog.name).sa(22, .bold, tracking: -0.3).foregroundColor(Tokens.text).lineLimit(1)
                    Text(sub).sa(13).foregroundColor(Tokens.text2).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Huidig schema \(prog.name). Tik om te wisselen")
    }

    private func templateRow(_ name: String) -> some View {
        let info = model.planSummary(name)
        let isNext = name == model.nextWorkoutName()
        return HStack(spacing: 0) {
            Button {
                model.ovName = name
                model.screen = .overview
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Text(name).sa(17, .semibold).foregroundColor(Tokens.text)
                        if isNext {
                            Text("Volgende").sa(12, .bold).foregroundColor(ac.accentText)
                                .padding(.horizontal, 8).frame(height: 22)
                                .background(Capsule().fill(ac.accentSoft))
                        }
                    }
                    Text(info.sub).sa(13).foregroundColor(Tokens.text2).padding(.top, 3)
                    Text(info.muscles).sa(13).foregroundColor(Tokens.text2).padding(.top, 1)
                }
                .padding(.leading, 16).padding(.trailing, 4).padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(name) bekijken")

            Button {
                model.tmName = name
                model.openSheet(.tplmenu)
            } label: {
                Icon.more(22).foregroundColor(Tokens.text2).frame(width: 48, height: 48).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)
            .accessibilityLabel("Opties voor \(name)")
        }
        .card(Tokens.surface, radius: Radius.button)
        .padding(.bottom, 8)
    }
}

// MARK: - Progressie

struct ProgressTab: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        let stats = ProgressStats.make(history: model.history, now: Date())
        VStack(alignment: .leading, spacing: 0) {
            Text("Laatste 4 weken").sa(13, .medium).foregroundColor(Tokens.text2)
                .frame(height: 44, alignment: .leading)
            Text("Progressie").sa(34, .bold, tracking: -0.6).foregroundColor(Tokens.text)
                .accessibilityAddTraits(.isHeader)

            HStack(alignment: .top, spacing: 12) {
                statView(String(stats.trainings), "trainingen")
                statView(Format.thousands(stats.volume), "kg volume")
                statView(String(stats.newRecords), "nieuwe PR\u{2019}s")
            }
            .padding(.top, 18)

            CalendarCard(expandable: true, openKey: \.calOpenProgress).padding(.top, 20)
            volumeCard(stats).padding(.top, 12)
            muscleCard(stats).padding(.top, 12)
            recordsSection(stats).padding(.top, 12)
        }
    }

    private func statView(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).sa(26, .semibold, tracking: -0.4, mono: true).foregroundColor(Tokens.text)
            Text(label).sa(13).foregroundColor(Tokens.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func volumeCard(_ stats: ProgressStats) -> some View {
        let volumes = stats.weekVolumes
        let top = max(volumes.max() ?? 0, 0.001)
        let thisWeek = volumes.last ?? 0
        return VStack(alignment: .leading, spacing: 0) {
            Text("Volume per week").sa(17, .semibold).foregroundColor(Tokens.text)
            Text("Totaal getild gewicht: kg \u{00D7} herhalingen, opgeteld. 9,8k = 9.800 kg.")
                .sa(13).foregroundColor(Tokens.text2).padding(.top, 2)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<volumes.count, id: \.self) { i in
                    VStack(spacing: 4) {
                        Text(volumes[i] > 0 ? Format.weight(volumes[i]) + "k" : "").sa(10, .regular, mono: true)
                            .foregroundColor(Tokens.text2).lineLimit(1).minimumScaleFactor(0.7)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(i == volumes.count - 1 ? ac.accentLine : ac.accentSoft)
                            .frame(height: max(4, CGFloat((volumes[i] / top * 100).rounded())))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 124, alignment: .bottom)
            .padding(.top, 14)
            HStack(spacing: 8) {
                ForEach(0..<stats.weekLabels.count, id: \.self) { i in
                    Text(stats.weekLabels[i]).sa(11, .regular, mono: true).foregroundColor(Tokens.text3)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 6)
            Text(thisWeek > 0 ? "Deze week tot nu toe \(Format.thousands(thisWeek * 1000)) kg" : "Nog geen volume deze week")
                .sa(13).foregroundColor(Tokens.text2).padding(.top, 10)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Tokens.surface, radius: Radius.card)
    }

    private func muscleCard(_ stats: ProgressStats) -> some View {
        let rows = Array(stats.muscleSets.prefix(8))
        let top = max(rows.map { $0.sets }.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Sets per spiergroep").sa(17, .semibold).foregroundColor(Tokens.text)
                Spacer()
                Text("deze week").sa(13).foregroundColor(Tokens.text2)
            }
            .padding(.bottom, 8)
            if rows.isEmpty {
                Text("Nog geen sets deze week.").sa(15).foregroundColor(Tokens.text2).padding(.vertical, 6)
            }
            ForEach(0..<rows.count, id: \.self) { i in
                HStack(spacing: 12) {
                    Text(rows[i].muscle).sa(15).foregroundColor(Tokens.text).frame(width: 92, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Tokens.track)
                            Capsule().fill(ac.accentLine)
                                .frame(width: geo.size.width * CGFloat(rows[i].sets) / CGFloat(top))
                        }
                    }
                    .frame(height: 8)
                    Text("\(rows[i].sets)").sa(15, .semibold, mono: true).foregroundColor(Tokens.text)
                        .frame(width: 24, alignment: .trailing)
                }
                .frame(height: 30)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Tokens.surface, radius: Radius.card)
    }

    // MARK: Persoonlijke records (eigen pagina)

    private func recordsSection(_ stats: ProgressStats) -> some View {
        let n = stats.records.count
        let sub = n == 0 ? "Rond een training af om records te zien" : "\(n) \(n == 1 ? "record" : "records") \u{00B7} laatste: " + (stats.records.first?.name ?? "")
        return Button {
            model.screen = .records
        } label: {
            HStack(spacing: 14) {
                Icon.star(22).foregroundColor(ac.accentText)
                    .frame(width: 48, height: 48).background(Circle().fill(ac.accentSoft))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Persoonlijke records").sa(17, .semibold).foregroundColor(Tokens.text)
                    Text(sub).sa(13).foregroundColor(Tokens.text2).lineLimit(1)
                }
                Spacer(minLength: 0)
                Icon.chevronRight(18).foregroundColor(Tokens.text2)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .card(Tokens.surface, radius: Radius.card)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gym

struct GymTab: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        let gym = model.gym
        VStack(alignment: .leading, spacing: 0) {
            Text("Apparaten en gewichtsstappen").sa(13, .medium).foregroundColor(Tokens.text2)
                .frame(height: 44, alignment: .leading)
            Text("Gym").sa(34, .bold, tracking: -0.6).foregroundColor(Tokens.text)
                .accessibilityAddTraits(.isHeader)

            Button {
                model.openSheet(.gym)
            } label: {
                HStack(spacing: 12) {
                    Icon.pin(18).foregroundColor(Tokens.text)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Tokens.raised))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gym.name).sa(17, .semibold).foregroundColor(Tokens.text)
                        Text(gym.summary).sa(13).foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: 6) {
                        Icon.updown(16)
                        Text("Wissel gym").sa(14, .semibold)
                    }
                    .foregroundColor(ac.accentText)
                    .padding(.horizontal, 12).frame(height: 34)
                    .background(Capsule().fill(ac.accentSoft))
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .card(Tokens.surface, radius: Radius.button)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)

            SectionLabel(text: "Apparaten in deze gym").padding(.top, 24).padding(.bottom, 2)
            ForEach(0..<gym.equipment.count, id: \.self) { i in
                let q = gym.equipment[i]
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(q.name).sa(16, .medium).foregroundColor(q.on ? Tokens.text : Tokens.text2)
                        Text(q.on ? q.steps : "Niet in deze gym").sa(13).foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                    SAToggle(isOn: q.on, onColor: ac.accentLine, label: q.name) { model.toggleMachine(i) }
                }
                .frame(minHeight: 60)
            }

            Button {} label: {
                Text("+ Apparaat toevoegen").sa(16, .semibold).foregroundColor(ac.accentText)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .card(Tokens.raised, radius: Radius.button)
            }
            .buttonStyle(.plain)
            .padding(.top, 12)

            Text("Later: een apparaat scannen met je camera, zodat de gewichten vanzelf worden ingevuld.")
                .sa(13).foregroundColor(Tokens.text3).lineSpacing(3).padding(.top, 10)
        }
    }
}

// MARK: - Profiel

struct ProfileTab: View {
    private var profileLine: String {
        let n = model.history.count
        guard let first = model.history.map({ $0.date }).min() else { return "Nog geen trainingen" }
        return "\(n) \(n == 1 ? "training" : "trainingen") \u{00B7} sinds " + DateText.month(first)
    }

    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 44)
            Text("Profiel").sa(34, .bold, tracking: -0.6).foregroundColor(Tokens.text)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 14) {
                Text("S").sa(20, .bold).foregroundColor(ac.onAccent)
                    .frame(width: 52, height: 52).background(Circle().fill(ac.accent))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stan").sa(19, .semibold).foregroundColor(Tokens.text)
                    Text(profileLine).sa(13, .regular, mono: true)
                        .foregroundColor(Tokens.text2)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(Tokens.surface, radius: Radius.button)
            .padding(.top, 16)

            SectionLabel(text: "Weergave").padding(.top, 24).padding(.bottom, 10)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Accentkleur").sa(16, .medium).foregroundColor(Tokens.text)
                    Spacer()
                    Text(model.accent.displayName).sa(14).foregroundColor(Tokens.text2)
                }
                AccentPicker().padding(.top, 8)
                Text("Modus").sa(16, .medium).foregroundColor(Tokens.text).padding(.top, 16).padding(.bottom, 8)
                ModePicker()
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(Tokens.surface, radius: Radius.button)

            SectionLabel(text: "Training").padding(.top, 24).padding(.bottom, 10)
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Standaard rusttijd").sa(16, .medium).foregroundColor(Tokens.text)
                        Text("Na een werkset").sa(13).foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: 0) {
                        Button { model.setRestDefault(model.restDefault - 15) } label: {
                            Text("−").sa(20).foregroundColor(Tokens.text).frame(width: 40, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Kortere rust")
                        Text(SAFormat.clock(seconds: model.restDefault)).sa(16, .semibold, mono: true)
                            .foregroundColor(Tokens.text).frame(minWidth: 48)
                        Button { model.setRestDefault(model.restDefault + 15) } label: {
                            Text("+").sa(20).foregroundColor(Tokens.text).frame(width: 40, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Langere rust")
                    }
                    .card(Tokens.raised, radius: Radius.field)
                }
                .frame(minHeight: 60)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Warming-up in superset").sa(16, .medium).foregroundColor(Tokens.text)
                        Text("Eerst direct je eerste werkset, dan wisselen").sa(13).foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                    SAToggle(isOn: model.warmFirst, onColor: ac.accentLine, label: "Warming-up in superset") {
                        model.warmFirst.toggle()
                        model.save()
                    }
                }
                .frame(minHeight: 64)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Algemene warming-up").sa(16, .medium).foregroundColor(Tokens.text)
                        Text(model.warmupOn ? "\(model.warmupMinutes) min aan het begin van elke training" : "Uit")
                            .sa(13).foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                    if model.warmupOn {
                        HStack(spacing: 0) {
                            Button { model.setWarmupMinutes(model.warmupMinutes - 1) } label: {
                                Text("\u{2212}").sa(20).foregroundColor(Tokens.text).frame(width: 40, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Kortere warming-up")
                            Text("\(model.warmupMinutes)").sa(16, .semibold, mono: true)
                                .foregroundColor(Tokens.text).frame(minWidth: 28)
                            Button { model.setWarmupMinutes(model.warmupMinutes + 1) } label: {
                                Text("+").sa(20).foregroundColor(Tokens.text).frame(width: 40, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Langere warming-up")
                        }
                        .card(Tokens.raised, radius: Radius.field)
                    }
                    SAToggle(isOn: model.warmupOn, onColor: ac.accentLine, label: "Algemene warming-up") {
                        model.setWarmup(on: !model.warmupOn)
                    }
                }
                .frame(minHeight: 64)
            }
            .padding(.horizontal, 16).padding(.vertical, 4)
            .card(Tokens.surface, radius: Radius.button)

            SectionLabel(text: "Herinneringen").padding(.top, 24).padding(.bottom, 10)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Creatine").sa(16, .medium).foregroundColor(Tokens.text)
                    Text(model.crea ? "Elke dag om 09:00" : "Uit").sa(13).foregroundColor(Tokens.text2)
                }
                Spacer(minLength: 0)
                SAToggle(isOn: model.crea, onColor: ac.accentLine, label: "Creatine-herinnering") {
                    model.setCreatine(!model.crea)
                }
            }
            .frame(minHeight: 64)
            .padding(.horizontal, 16).padding(.vertical, 4)
            .card(Tokens.surface, radius: Radius.button)

            Text("Later hier ook: kg of lb, gegevens exporteren en een back-up.")
                .sa(13).foregroundColor(Tokens.text3).lineSpacing(3).padding(.top, 16)
        }
    }
}

struct AccentPicker: View {
    @EnvironmentObject private var model: AppModel

    private func swatch(_ id: AccentID) -> Color {
        let hex = id.hex
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        return Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    @State private var expanded = false

    private func row(_ ids: [AccentID]) -> some View {
        HStack(spacing: 2) {
            ForEach(ids) { id in
                let on = model.accent == id
                Button {
                    model.accent = id
                    model.save()
                } label: {
                    Circle().fill(swatch(id))
                        .frame(width: 34, height: 34)
                        .frame(width: 48, height: 48)
                        .overlay(Circle().stroke(on ? Tokens.text : Color.clear, lineWidth: 2).frame(width: 48, height: 48))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(id.displayName)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, -4)
    }

    var body: some View {
        let showExtras = expanded || AccentID.extras.contains(model.accent)
        VStack(alignment: .leading, spacing: 0) {
            row(AccentID.primary)
            if showExtras {
                row(Array(AccentID.extras.prefix(6)))
                row(Array(AccentID.extras.dropFirst(6)))
            }
            Button {
                expanded.toggle()
            } label: {
                HStack(spacing: 6) {
                    Text(showExtras ? "Minder kleuren" : "Meer kleuren").sa(14, .semibold)
                    Icon.chevronDown(14).rotationEffect(.degrees(showExtras ? 180 : 0))
                }
                .foregroundColor(Tokens.text2)
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(AccentID.extras.contains(model.accent))
            .opacity(AccentID.extras.contains(model.accent) ? 0.4 : 1)
        }
    }
}

struct ModePicker: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppearanceMode.allCases) { mode in
                let on = model.themeMode == mode
                Button {
                    model.themeMode = mode
                    model.save()
                } label: {
                    Text(mode.displayName).sa(15, .semibold)
                        .foregroundColor(on ? Tokens.text : Tokens.text2)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .card(on ? Tokens.surface : Color.clear, radius: 11)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .card(Tokens.raised, radius: Radius.row)
    }
}
