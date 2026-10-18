import SwiftUI

// MARK: - Tabbalk en minibalk

struct AppTabBar: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    private func icon(_ tab: HomeTab) -> Icon {
        switch tab {
        case .start: return Icon.tabStart
        case .training: return Icon.tabTraining
        case .progress: return Icon.tabProgress
        case .gym: return Icon.tabGym
        case .profile: return Icon.tabProfile
        }
    }

    @State private var dragX: CGFloat?

    var body: some View {
        GeometryReader { geo in
            let count = CGFloat(HomeTab.allCases.count)
            let slot = (geo.size.width - 10) / count
            let rest = 5 + CGFloat(model.tab.rawValue) * slot
            let lensX = dragX.map { min(max($0 - slot / 2, 5), 5 + slot * (count - 1)) } ?? rest
            ZStack(alignment: .leading) {
                // De "lens": volgt je vinger vloeiend en veert daarna in het gekozen tabblad.
                Color.clear
                    .frame(width: slot, height: 54)
                    .glassSurface(Capsule(), tint: ac.accent.opacity(0.45), interactive: false, fallback: ac.accentSoft)
                    .scaleEffect(dragX != nil ? 1.12 : 1)
                    .offset(x: lensX)
                    .animation(dragX != nil ? .interactiveSpring(response: 0.18, dampingFraction: 0.85)
                                            : .spring(response: 0.38, dampingFraction: 0.74), value: lensX)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragX != nil)
                HStack(spacing: 0) {
                    ForEach(HomeTab.allCases) { tab in
                        let on = model.tab == tab
                        VStack(spacing: 3) {
                            icon(tab)
                            Text(tab.title).sa(11, .semibold)
                        }
                        .foregroundColor(on ? ac.accentText : Tokens.text2)
                        .frame(width: slot, height: 54)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
                        .accessibilityAction { model.tab = tab }
                    }
                }
                .padding(.horizontal, 5)
            }
            .frame(height: 64)
            .contentShape(Capsule())
            // Tik of houd je vinger op de balk en schuif: het glas volgt je vinger.
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in
                    model.barDragging = true
                    dragX = v.location.x
                    let i = Int(((v.location.x - 5) / slot).rounded(.down))
                    let clamped = min(max(i, 0), HomeTab.allCases.count - 1)
                    if let t = HomeTab(rawValue: clamped), t != model.tab {
                        Haptics.light()
                        model.tab = t
                    }
                }
                .onEnded { _ in
                    dragX = nil
                    DispatchQueue.main.async { model.barDragging = false }
                })
        }
        .frame(height: 64)
        .glassSurface(Capsule())
        .padding(.horizontal, 16)
        .padding(.bottom, -8)
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
            .glassSurface(RoundedRectangle(cornerRadius: 30, style: .continuous), tint: ac.accentSoft, fallback: Tokens.raised)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Container met tabs

struct HomeContainer: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch model.tab {
                    case .start: StartTab()
                    case .training: TrainingTab()
                    case .progress: ProgressTab()
                    case .gym: GymTab()
                    case .profile: ProfileTab()
                    }
                }
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.top, 8)
                .padding(.bottom, model.session == nil ? 100 : 180)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: 8) {
                MiniBar()
                AppTabBar()
            }
        }
        .background(AppBackground())
        .simultaneousGesture(DragGesture(minimumDistance: 40)
            .onEnded { v in
                guard !model.barDragging, abs(v.translation.width) > abs(v.translation.height) * 1.8, abs(v.translation.width) > 70 else { return }
                let next = model.tab.rawValue + (v.translation.width < 0 ? 1 : -1)
                if let t = HomeTab(rawValue: next) {
                    Haptics.light()
                    withAnimation(.easeOut(duration: 0.2)) { model.tab = t }
                }
            })
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

            Button { model.screen = .weekPlan } label: {
                HStack(spacing: 12) {
                    Icon.calendar(18).foregroundColor(ac.accentText)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Weekplanning").sa(16, .semibold).foregroundColor(Tokens.text)
                        Text("Plan je week in, of zet een training vast op een dag").sa(13).foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                    Icon.chevronRight(16).foregroundColor(Tokens.text3)
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                .glassCard(radius: Radius.button)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 10)

            HStack(alignment: .center) {
                SectionLabel(text: "Mijn schema")
                Spacer(minLength: 0)
                Button { model.openSheet(.program) } label: {
                    HStack(spacing: 6) {
                        Text("Wissel schema").sa(14, .semibold)
                        Icon.updown(16)
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

            VStack(alignment: .leading, spacing: 0) {
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
                    .glassCard(radius: Radius.button)
                }
                .buttonStyle(.plain)
                .padding(.top, 16)

            }
        }
    }

    private var programButton: some View {
        let prog = model.program
        let next = model.nextWorkoutName()
        let count = prog.workouts.count
        var sub = "\(count) \(count == 1 ? "training" : "trainingen")"
        if let next = next { sub += " · volgende: " + next }
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Button { model.openSheet(.program) } label: {
                    Text(prog.name).sa(22, .bold, tracking: -0.3).foregroundColor(Tokens.text).lineLimit(1)
                        .frame(minHeight: 36).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Huidig schema \(prog.name). Tik om te wisselen")
                Button {
                    model.nameEdit = NameEdit(title: "Schema hernoemen", subtitle: prog.name, placeholder: "Nieuwe naam", text: prog.name, confirmTitle: "Bewaar") { model.renameProgram(prog.id, to: $0) }
                } label: {
                    Icon.edit(17).foregroundColor(Tokens.text2).frame(width: 40, height: 36).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hernoem schema \(prog.name)")
                Spacer(minLength: 0)
            }
            Text(sub).sa(13).foregroundColor(Tokens.text2).lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
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
        .glassCard(radius: Radius.button)
        .padding(.bottom, 8)
    }
}

// MARK: - Progressie

struct ProgressTab: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @State private var volumeInfo = false
    @State private var selectedWeek: Int?
    @State private var openWorkout: UUID?

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
            allWorkoutsLink().padding(.top, 12)
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
            HStack(spacing: 4) {
                Text("Volume per week").sa(17, .semibold).foregroundColor(Tokens.text)
                Button { volumeInfo.toggle() } label: {
                    Text("i").sa(12, .bold, mono: true).foregroundColor(Tokens.text3)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Tokens.line, lineWidth: 1.5))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Uitleg over volume")
                Spacer(minLength: 0)
            }
            .frame(height: 28)
            if volumeInfo {
                Text("Totaal getild gewicht: kg \u{00D7} herhalingen, opgeteld. 9,8k = 9.800 kg.")
                    .sa(13).foregroundColor(Tokens.text2).padding(.top, 4)
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<volumes.count, id: \.self) { i in
                    VStack(spacing: 4) {
                        Text(volumes[i] > 0 ? Format.weight(volumes[i]) + "k" : "").sa(10, .regular, mono: true)
                            .foregroundColor(Tokens.text2).lineLimit(1).minimumScaleFactor(0.7)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(i == volumes.count - 1 || selectedWeek == i ? ac.accentLine : ac.accentSoft)
                            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(selectedWeek == i ? Tokens.text : Color.clear, lineWidth: 2))
                            .frame(height: max(4, CGFloat((volumes[i] / top * 100).rounded())))
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedWeek = selectedWeek == i ? nil : i
                        openWorkout = nil
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Week \(stats.weekLabels[i]), \(Format.weight(volumes[i])) duizend kg")
                    .accessibilityAddTraits(.isButton)
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
            Text(selectedWeek == nil
                 ? (thisWeek > 0 ? "Deze week tot nu toe \(Format.thousands(thisWeek * 1000)) kg. Tik op een week voor je trainingen." : "Nog geen volume deze week. Tik op een week voor je trainingen.")
                 : "")
                .sa(13).foregroundColor(Tokens.text2).padding(.top, selectedWeek == nil ? 10 : 0)
            if let w = selectedWeek { weekWorkouts(w, label: stats.weekLabels[w]) }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: Radius.card)
    }

    private func weekWorkouts(_ week: Int, label: String) -> some View {
        let items = ProgressStats.workouts(inWeek: week, history: model.history, now: Date())
        return VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "Trainingen in \(label)").padding(.top, 14).padding(.bottom, 4)
            if items.isEmpty {
                Text("Geen trainingen in deze week.").sa(15).foregroundColor(Tokens.text2).padding(.vertical, 8)
            }
            ForEach(items) { h in workoutRow(h) }
        }
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

    private func allWorkoutsLink() -> some View {
        let n = model.history.count
        return Button {
            model.screen = .allWorkouts
        } label: {
            HStack(spacing: 14) {
                Icon.tabTraining.foregroundColor(ac.accentText)
                    .frame(width: 48, height: 48).background(Circle().fill(ac.accentSoft))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alle trainingen").sa(17, .semibold).foregroundColor(Tokens.text)
                    Text(n == 0 ? "Nog geen trainingen" : "\(n) \(n == 1 ? "training" : "trainingen") \u{00B7} filter per training").sa(13).foregroundColor(Tokens.text2).lineLimit(1)
                }
                Spacer(minLength: 0)
                Icon.chevronRight(18).foregroundColor(Tokens.text2)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .glassCard(radius: Radius.card)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        .glassCard(radius: Radius.card)
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
            .glassCard(radius: Radius.card)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gym

struct GymTab: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @State private var showAccessories = false

    private func segment(_ title: String, on: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).sa(15, .semibold).foregroundColor(on ? Tokens.text : Tokens.text2)
                .frame(maxWidth: .infinity).frame(height: 40)
                .background(Capsule().fill(on ? Tokens.raised : Color.clear))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        let gym = model.gym
        VStack(alignment: .leading, spacing: 0) {
            Text("Apparaten en opzetstukken").sa(13, .medium).foregroundColor(Tokens.text2)
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
                        Text("Wissel gym").sa(14, .semibold)
                        Icon.updown(16)
                    }
                    .foregroundColor(ac.accentText)
                    .padding(.horizontal, 12).frame(height: 34)
                    .background(Capsule().fill(ac.accentSoft))
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .glassCard(radius: Radius.button)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)

            HStack(spacing: 4) {
                segment("Apparaten", on: !showAccessories) { showAccessories = false }
                segment("Opzetstukken", on: showAccessories) { showAccessories = true }
            }
            .padding(4)
            .glassSurface(Capsule(), interactive: false, fallback: Tokens.surface)
            .padding(.top, 14)

            if showAccessories {
                accessoriesSection
            } else {
                machinesSection
            }
        }
    }

    @ViewBuilder
    private var accessoriesSection: some View {
        Button {
            model.nameEdit = NameEdit(title: "Nieuw opzetstuk", subtitle: "Bijvoorbeeld Triceps touw", placeholder: "Naam van het opzetstuk", text: "", confirmTitle: "Voeg toe") { model.addAccessory(name: $0) }
        } label: {
            Text("+ Opzetstuk toevoegen").sa(16, .semibold).foregroundColor(ac.accentText)
                .frame(maxWidth: .infinity).frame(height: 52)
                .card(Tokens.raised, radius: Radius.button)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, 14)
        Text("Touw, rechte stang, V-stang: bij kabeloefeningen staan ze standaard klaar. Je gewicht wordt per opzetstuk onthouden.")
            .sa(13).foregroundColor(Tokens.text2).lineSpacing(3).padding(.top, 14).padding(.bottom, 8)
        let list = model.gym.accessoryList
        VStack(spacing: 0) {
            ForEach(list) { a in
                Button {
                    model.accEditID = a.id
                    model.openSheet(.accedit)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(a.name).sa(16, .medium).foregroundColor(Tokens.text).lineLimit(1)
                            Text(a.step > 0 ? "Stap \(GymMachine.fmt(a.step)) kg" : "Stap van de oefening").sa(13).foregroundColor(Tokens.text2)
                        }
                        Spacer(minLength: 0)
                        Icon.chevronRight(16).foregroundColor(Tokens.text3)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if a.id != list.last?.id { Divider().background(Tokens.line).padding(.leading, 16) }
            }
        }
        .glassCard(radius: Radius.button)
    }

    @ViewBuilder
    private var machinesSection: some View {
        let gym = model.gym
        Button { model.openSheet(.machineadd) } label: {
            Text("+ Apparaat toevoegen").sa(16, .semibold).foregroundColor(ac.accentText)
                .frame(maxWidth: .infinity).frame(height: 52)
                .card(Tokens.raised, radius: Radius.button)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, 14)

        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "Apparaten in deze gym").padding(.top, 24).padding(.bottom, 2)
            if gym.equipment.isEmpty {
                Text("Voeg de apparaten toe die jouw gym heeft. De plus/min-knoppen in je training volgen dan de gewichtsstappen van die apparaten.")
                    .sa(14).foregroundColor(Tokens.text2).lineSpacing(3).padding(.vertical, 8)
            }
            let groups = Dictionary(grouping: gym.equipment) { $0.showsBrand || $0.brand == "Eigen" ? $0.brand : "Overig" }
            ForEach(groups.keys.sorted(), id: \.self) { brand in
                SectionLabel(text: brand).padding(.top, 14).padding(.bottom, 4)
                VStack(spacing: 0) {
                    let rows = (groups[brand] ?? []).sorted { $0.name < $1.name }
                    ForEach(rows) { q in
                        HStack(spacing: 0) {
                            Button {
                                model.machineEditID = q.id
                                model.openSheet(.machineedit)
                            } label: {
                                HStack(spacing: 12) {
                                    Icon.machine(20).foregroundColor(q.on ? ac.accentText : Tokens.text3)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(q.on ? ac.accentSoft : Tokens.raised))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(q.name).sa(16, .medium).foregroundColor(q.on ? Tokens.text : Tokens.text2).lineLimit(1)
                                        Text(q.on ? q.stepsText : "Niet in deze gym").sa(13).foregroundColor(Tokens.text2).lineLimit(1)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.leading, 12)
                                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            SAToggle(isOn: q.on, onColor: ac.accentLine, label: q.name) { model.toggleMachine(q.id) }
                                .padding(.horizontal, 12)
                        }
                        if q.id != rows.last?.id { Divider().background(Tokens.line).padding(.leading, 64) }
                    }
                }
                .glassCard(radius: Radius.button)
            }

            Text("Tik op een apparaat om de stappen aan te passen. De waarden uit de lijst zijn standaarden; controleer ze bij jouw machines.")
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
            .glassCard(radius: Radius.button)
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
            .glassCard(radius: Radius.button)

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
                        Text("Elke week opnieuw beginnen").sa(16, .medium).foregroundColor(Tokens.text)
                        Text("Op maandag weer de eerste training van je schema").sa(13).foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                    SAToggle(isOn: model.weekReset, onColor: ac.accentLine, label: "Elke week opnieuw beginnen") {
                        model.weekReset.toggle()
                        model.save()
                    }
                }
                .frame(minHeight: 64)
                Divider().background(Tokens.line)
                Button { model.screen = .weekPlan } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weekplanning").sa(16, .medium).foregroundColor(Tokens.text)
                            Text(model.weekPlan.isEmpty && model.weekOverrides.isEmpty ? "Plan je week in en zet trainingen vast op een dag" : "Bekijk en pas je week aan")
                                .sa(13).foregroundColor(Tokens.text2)
                        }
                        Spacer(minLength: 0)
                        Icon.chevronRight(16).foregroundColor(Tokens.text3)
                    }
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Divider().background(Tokens.line)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Melding bij vergeten workout").sa(16, .medium).foregroundColor(Tokens.text)
                        Text("Na 1,5 uur zonder set vraagt de app of je wilt afsluiten, op de tijd van je laatste set").sa(13).foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                    SAToggle(isOn: model.staleReminder, onColor: ac.accentLine, label: "Melding bij vergeten workout") {
                        model.staleReminder.toggle()
                        if !model.staleReminder { Notifier.cancelStale() }
                        model.save()
                    }
                }
                .frame(minHeight: 64)
            }
            .padding(.horizontal, 16).padding(.vertical, 4)
            .glassCard(radius: Radius.button)

            SectionLabel(text: "Herinneringen").padding(.top, 24).padding(.bottom, 10)
            CreatineRow()

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


// MARK: - Creatine

func clockText(_ minutes: Int) -> String {
    String(format: "%02d:%02d", minutes / 60, minutes % 60)
}

func timeBinding(_ value: Int, _ set: @escaping (Int) -> Void) -> Binding<Date> {
    Binding<Date>(
        get: { Calendar.current.date(bySettingHour: value / 60, minute: value % 60, second: 0, of: Date()) ?? Date() },
        set: { d in
            let c = Calendar.current.dateComponents([.hour, .minute], from: d)
            set((c.hour ?? 0) * 60 + (c.minute ?? 0))
        }
    )
}

/// Rij in Profiel die het aparte creatine-scherm opent.
private struct CreatineRow: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        Button { model.screen = .creatine } label: {
            HStack(spacing: 14) {
                Icon.bell(20).foregroundColor(ac.accentText)
                    .frame(width: 44, height: 44).background(Circle().fill(ac.accentSoft))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Creatine").sa(17, .semibold).foregroundColor(Tokens.text)
                    Text(model.creaSummary).sa(13).foregroundColor(Tokens.text2).lineLimit(2)
                }
                Spacer(minLength: 0)
                Icon.chevronRight(18).foregroundColor(Tokens.text2)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .glassCard(radius: Radius.button)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
