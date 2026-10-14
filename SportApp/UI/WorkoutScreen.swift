import SwiftUI

struct WorkoutScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @State private var openMinY: CGFloat = 0
    @State private var userScrolled = false

    var body: some View {
        if let s = model.session {
            let info = model.current()
            VStack(spacing: 0) {
                WorkoutTopBar(session: s)
                let openID = model.focusID.flatMap { s.exercise($0)?.id } ?? info.cur?.exID
                let headID = s.blocks.first(where: { $0.contains { $0.id == openID } })?.first?.id
                ScrollViewReader { proxy in
                    ScrollView {
                        WorkoutList(session: s, cur: info.cur)
                            .padding(.horizontal, 20)
                            .padding(.top, 18)
                            .padding(.bottom, 20)
                            .animation(nil, value: openID)
                    }
                    .coordinateSpace(name: "wscroll")
                    .onPreferenceChange(OpenCardKey.self) { value in
                        openMinY = value
                        if value > -20 && value < 150 { userScrolled = false }
                    }
                    .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded { _ in userScrolled = true })
                    .overlay(alignment: .bottom) {
                        if info.cur != nil && (userScrolled || openMinY < -60 || openMinY > 520) {
                            Button {
                                userScrolled = false
                                scrollToHead(proxy, headID, animated: true)
                            } label: {
                                HStack(spacing: 6) {
                                    (openMinY > 520 ? Icon.chevronDown(16) : Icon.chevronUp(16)).foregroundColor(ac.onAccent)
                                    Text("Naar huidige set").sa(14, .semibold).foregroundColor(ac.onAccent)
                                }
                                .padding(.horizontal, 16).frame(height: 40)
                                .background(Capsule().fill(ac.accentLine))
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, 10)
                        }
                    }
                    // Na een set of een andere oefening: het blok van de huidige oefening naar boven.
                    .onChange(of: info.cur?.setID) { _ in userScrolled = false; scrollToHead(proxy, headID, animated: false) }
                    .onChange(of: openID) { _ in userScrolled = false; scrollToHead(proxy, headID, animated: false) }
                    .onChange(of: model.scrollTick) { _ in userScrolled = false; scrollToHead(proxy, headID, animated: false) }
                    .onAppear { scrollToHead(proxy, headID, animated: false) }
                }
                WorkoutBottom(session: s, cur: info.cur, hasQueue: !info.queue.isEmpty)
                    .opacity(model.noteEdit == nil ? 1 : 0)
                    .allowsHitTesting(model.noteEdit == nil)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .overlay { if model.noteEdit != nil { NotePopup() } }
            .background(Tokens.bg.ignoresSafeArea())
        }
    }

    /// Zet het blok bovenaan. Een paar pogingen, omdat de lijst eerst van vorm verandert.
    private func scrollToHead(_ proxy: ScrollViewProxy, _ id: UUID?, animated: Bool) {
        guard let id = id else { return }
        for delay in [0.05, 0.3, 0.6] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if animated {
                    withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("blk-\(id.uuidString)", anchor: .top) }
                } else {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) { proxy.scrollTo("blk-\(id.uuidString)", anchor: .top) }
                }
            }
        }
    }
}

/// Waar de open oefening in beeld staat (voor de knop "Naar huidige set").
private struct OpenCardKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Bovenbalk

private struct WorkoutTopBar: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    let session: LiveSession

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    model.screen = .home
                    model.focusID = nil
                } label: {
                    Icon(paths: ["M6 9l6 6 6-6"], lineWidth: 2.2, size: 24).foregroundColor(Tokens.text)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Naar startscherm")

                HStack(spacing: 0) {
                    TimelineView(.periodic(from: Date(), by: 1)) { context in
                        stat(Format.clock(seconds: Int(context.date.timeIntervalSince(session.startAt))), "verstreken")
                    }
                    let left = session.estimatedMinutesLeft
                    stat(left > 0 ? "~\(left)" : "0", "min resterend")
                    stat(String(session.openWorkSets), "sets te gaan")
                }
                .frame(maxWidth: .infinity)

                Button {
                    model.openSheet(.menu)
                } label: {
                    Icon.more(24).foregroundColor(Tokens.text).frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Workoutmenu")
            }
            .padding(.horizontal, 6)
            .frame(height: 60)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Tokens.track)
                    Capsule().fill(ac.accentLine)
                        .frame(width: geo.size.width * CGFloat(session.progressFraction))
                        .animation(.easeOut(duration: 0.3), value: session.progressFraction)
                }
            }
            .frame(height: Size.progressLine)
            .padding(.horizontal, 20)
        }
        .background(Tokens.bg)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 0) {
            Text(value).sa(22, .semibold, tracking: -0.3, mono: true).foregroundColor(Tokens.text)
                .frame(height: 26)
            Text(label).sa(12, .medium).foregroundColor(Tokens.text2)
        }
        .frame(minWidth: 76)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Lijst met oefeningen

private struct WorkoutList: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    let session: LiveSession
    let cur: QueueItem?

    var body: some View {
        let openID = model.focusID.flatMap { session.exercise($0)?.id } ?? cur?.exID
        let count = session.exercises.count
        VStack(alignment: .leading, spacing: 0) {
            Text(session.name).sa(28, .bold, tracking: -0.4).foregroundColor(Tokens.text)
            Text("Gestart om \(Format.hhmm(session.startAt)) · \(model.gym.name) · \(count) \(count == 1 ? "oefening" : "oefeningen")")
                .sa(13).foregroundColor(Tokens.text2).padding(.top, 2).padding(.bottom, 14)
            if session.exercises.isEmpty { emptyState }

            let blocks = session.blocks
            ForEach(blocks, id: \.first!.id) { members in
                let bi = blocks.firstIndex(where: { $0.first?.id == members.first?.id }) ?? 0
                Color.clear.frame(height: 0).id("blk-\(members[0].id.uuidString)")
                blockView(members, blockIndex: bi, blocks: blocks, openID: openID)
            }
            // Ruimte onderaan, zodat ook het laatste blok bovenaan kan staan.
            Color.clear.frame(height: 420)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Text("Nog geen oefeningen").sa(17, .semibold).foregroundColor(Tokens.text)
            Text("Voeg je eerste oefening toe om te beginnen.").sa(15).foregroundColor(Tokens.text2)
                .padding(.top, 6).padding(.bottom, 20)
            Button {
                model.openSheet(.add)
            } label: {
                Text("Oefening toevoegen").sa(17, .bold).foregroundColor(ac.onAccent)
                    .padding(.horizontal, 24).frame(height: 52)
                    .card(ac.accent, radius: Radius.button)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48).padding(.horizontal, 12)
    }

    /// Hoeveelste superset dit blok is (0 = eerste), voor de kleur.
    private func supersetIndex(blockIndex: Int, blocks: [[LiveExercise]]) -> Int {
        var n = 0
        for i in 0..<blockIndex where blocks[i].count > 1 { n += 1 }
        return n
    }

    @ViewBuilder
    private func blockView(_ members: [LiveExercise], blockIndex: Int, blocks: [[LiveExercise]], openID: UUID?) -> some View {
        let isSS = members.count > 1
        if isSS {
            let idx = supersetIndex(blockIndex: blockIndex, blocks: blocks)
            SupersetFrame(index: idx, count: members.count) {
                VStack(alignment: .leading, spacing: 0) {
                    memberViews(members, hue: SupersetStyle.color(idx), openID: openID)
                }
                .padding(.horizontal, 10)
            }
        } else {
            memberViews(members, hue: nil, openID: openID)
        }
    }

    @ViewBuilder
    private func memberViews(_ members: [LiveExercise], hue: Color?, openID: UUID?) -> some View {
        ForEach(0..<members.count, id: \.self) { mi in
            let e = members[mi]
            let badge = hue != nil ? String(mi + 1) : ""
            if e.id == openID {
                OpenExerciseCard(exercise: e, badge: badge, hue: hue, cur: cur).id(e.id)
            } else {
                ClosedExerciseRow(exercise: e, badge: badge, hue: hue).id(e.id)
            }
        }
    }
}

private struct ClosedExerciseRow: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    let exercise: LiveExercise
    let badge: String
    var hue: Color?

    var body: some View {
        let allDone = !exercise.sets.isEmpty && exercise.sets.allSatisfy { $0.done }
        let summary = LiveSession.summary(of: exercise.sets, kind: Catalog.kind(exercise.name)) + (exercise.from.map { " · vervangt " + $0 } ?? "")
        Button {
            model.focus(exercise.id)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    if allDone {
                        Circle().fill(ac.accentSoft)
                        Icon.check(16).foregroundColor(ac.accentText)
                    } else if !badge.isEmpty {
                        Circle().fill(hue ?? Tokens.raised)
                        Text(badge).sa(12, .bold).foregroundColor(hue == nil ? Tokens.text2 : Color.black.opacity(0.85))
                    } else {
                        Circle().stroke(Tokens.line, lineWidth: 2)
                    }
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name).sa(17, .medium).foregroundColor(allDone ? Tokens.text2 : Tokens.text).lineLimit(1)
                    Text(summary).sa(13, .regular, mono: true).foregroundColor(Tokens.text2).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4).padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 2)
    }
}

private struct ChipButton: View {
    let icon: Icon
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                icon
                Text(title).sa(15, .medium).lineLimit(1).minimumScaleFactor(0.85)
            }
            .foregroundColor(Tokens.text)
            .frame(maxWidth: .infinity).frame(height: 44)
            .background(Capsule().fill(Tokens.raised))
        }
        .buttonStyle(.plain)
    }
}

private struct OpenExerciseCard: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    let exercise: LiveExercise
    let badge: String
    var hue: Color?
    let cur: QueueItem?

    /// "W", "1", "2", "D", "F", ... Een "Tot falen"-set telt als een genummerde set, een dropset niet.
    static func labels(for sets: [LiveSet]) -> [String] {
        var number = 0
        var out: [String] = []
        for s in sets {
            switch s.type {
            case .warmup:
                out.append("W")
            case .drop:
                out.append("D")
            case .failure:
                number += 1
                out.append("F")
            case .work:
                number += 1
                out.append(String(number))
            }
        }
        return out
    }

    private var kindUnits: (first: String, second: String) {
        switch Catalog.kind(exercise.name) {
        case .weights: return ("KG", "REPS")
        case .bodyweight: return ("+ KG", "REPS")
        case .cardio: return ("KM", "MIN")
        case .timed: return ("", "MIN")
        }
    }

    private func noteRow(_ e: NoteEntry, isNew: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isNew ? "Nieuw \u{00B7} vandaag" : "Eerder \u{00B7} " + DateText.short(e.date))
                    .sa(11, .semibold, tracking: 0.4).foregroundColor(isNew ? ac.accentText : Tokens.text3)
                Text(e.text).sa(14).foregroundColor(isNew ? Tokens.text : Tokens.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button { model.noteEdit = NoteEdit(exercise: exercise.name, entryID: e.id, text: e.text) } label: {
                Icon.edit(14).foregroundColor(Tokens.text3).frame(width: 32, height: 36).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Bewerk notitie")
            Button {
                let name = exercise.name
                model.confirm = ConfirmRequest(title: "Notitie verwijderen?", message: e.text, confirmTitle: "Verwijder") {
                    model.deleteNote(e.id, for: name)
                }
            } label: {
                Icon.close(14).foregroundColor(Tokens.text3).frame(width: 32, height: 36).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Verwijder notitie")
        }
        .padding(.leading, 12).padding(.trailing, 2).padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.field, style: .continuous).fill(isNew ? ac.accentSoft.opacity(0.45) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: Radius.field, style: .continuous).stroke(isNew ? Color.clear : Tokens.line, lineWidth: 1))
    }

    private var notesBlock: some View {
        let entries = Array((model.noteLog[exercise.name] ?? []).prefix(4))
        let start = model.session?.startAt ?? Date()
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("NOTITIES").sa(12, .semibold, tracking: 0.48).foregroundColor(Tokens.text3)
                Spacer(minLength: 0)
                Button { model.noteEdit = NoteEdit(exercise: exercise.name, entryID: nil, text: "") } label: {
                    Icon.plus(14, 2.4).foregroundColor(ac.accentText)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Tokens.raised))
                        .frame(width: 44, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Notitie toevoegen")
            }
            .padding(.leading, 4).padding(.trailing, -8)
            ForEach(entries) { e in
                noteRow(e, isNew: e.date >= start)
            }
        }
    }

    var body: some View {
        let labels = OpenExerciseCard.labels(for: exercise.sets)
        let rows: [(set: LiveSet, label: String)] = Array(zip(exercise.sets, labels)).map { (set: $0.0, label: $0.1) }

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                if !badge.isEmpty {
                    Text(badge).sa(12, .bold).foregroundColor(hue == nil ? Tokens.text2 : Color.black.opacity(0.85))
                        .padding(.horizontal, 8).frame(height: 24)
                        .card(hue ?? Tokens.raised, radius: Radius.badge)
                        .padding(.top, 2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name).sa(22, .semibold, tracking: -0.3).foregroundColor(Tokens.text)
                    Text(Catalog.meta(exercise.name) + (exercise.from.map { " · vervangt " + $0 } ?? ""))
                        .sa(13).foregroundColor(Tokens.text2)
                }
                Spacer(minLength: 0)
                Button { model.openSheet(.exmenu, exID: exercise.id) } label: {
                    Icon.more(22).foregroundColor(Tokens.text2).frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, -8).padding(.trailing, -10)
                .accessibilityLabel("Opties voor \(exercise.name)")
            }
            .padding(.horizontal, 16)

            HStack(spacing: 8) {
                ChipButton(icon: Icon.explain(18), title: "Uitleg") { model.openSheet(.explain, exID: exercise.id) }
                ChipButton(icon: Icon.swap(18), title: "Bezet") { model.openSheet(.swap, exID: exercise.id) }
                ChipButton(icon: Icon.link(18, 2), title: "Superset") { model.openSheet(.superset, exID: exercise.id) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12).padding(.bottom, 6)

            HStack(spacing: 0) {
                Text("SET").frame(width: 48, alignment: .leading)
                Text(kindUnits.first).frame(maxWidth: .infinity, alignment: .leading)
                Text(kindUnits.second).frame(maxWidth: .infinity, alignment: .leading)
                Spacer().frame(width: 40)
            }
            .sa(12, .semibold, tracking: 0.48).foregroundColor(Tokens.text3)
            .padding(.horizontal, 24).padding(.top, 6).frame(height: 28)

            ForEach(0..<rows.count, id: \.self) { i in
                SetRow(exercise: exercise, set: rows[i].set, label: rows[i].label, isCur: cur?.setID == rows[i].set.id)
                    .padding(.horizontal, 8).padding(.bottom, 2)
            }

            HStack(spacing: 8) {
                Button { model.addSet(exercise.id) } label: {
                    HStack(spacing: 6) {
                        Icon.plus(18)
                        Text("Set").sa(15, .semibold)
                    }
                    .foregroundColor(ac.accentText)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .card(Tokens.raised, radius: Radius.field)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8).padding(.top, 6)

            notesBlock
                .padding(.horizontal, 16).padding(.top, 10)

            Text("Tik op een set om hem te kiezen of aan te passen · tik op het nummer voor het type · veeg naar links om te verwijderen")
                .sa(12).foregroundColor(Tokens.text3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 2)
        }
        .padding(.top, 16).padding(.bottom, 10)
        .card(Tokens.surface, radius: Radius.card)
        .background(GeometryReader { g in
            Color.clear.preference(key: OpenCardKey.self, value: g.frame(in: .named("wscroll")).minY)
        })
        .padding(.horizontal, -8)
        .padding(.top, 4).padding(.bottom, 10)
    }
}

private struct SetRow: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    let exercise: LiveExercise
    let set: LiveSet
    let label: String
    let isCur: Bool
    @State private var dx: CGFloat = 0

    private var firstColumn: String {
        switch Catalog.kind(exercise.name) {
        case .timed: return ""
        case .bodyweight: return set.w == 0 ? "\u{2013}" : Format.weight(set.w)
        case .cardio: return Format.km(set.w)
        case .weights: return Format.weight(set.w)
        }
    }

    private var rowFill: Color {
        if set.done { return ac.accentSoft.opacity(0.42) }
        return isCur ? Tokens.raised : Tokens.surface
    }

    var body: some View {
        var typeColor: Color?
        switch set.type {
        case .warmup: typeColor = Tokens.warm
        case .drop: typeColor = Tokens.drop
        case .failure: typeColor = Tokens.danger
        case .work: typeColor = nil
        }
        let labelColor = typeColor ?? (isCur ? ac.accentText : Tokens.text2)
        let valueColor = isCur ? Tokens.text : Tokens.text2

        return ZStack(alignment: .trailing) {
            HStack(spacing: 6) {
                Icon.trash(18)
                Text("Verwijder").sa(15, .semibold)
            }
            .foregroundColor(Tokens.onDanger)
            .padding(.trailing, 16)
            .opacity(dx < 0 ? 1 : 0)

            HStack(spacing: 0) {
                Button {
                    model.openSheet(.settype, exID: exercise.id, setID: set.id)
                } label: {
                    Text(label).sa(14, .bold).foregroundColor(labelColor)
                        .frame(minWidth: 26).frame(height: 26)
                        .padding(.horizontal, 4)
                        .card(isCur ? Tokens.surface : Tokens.raised, radius: Radius.badge)
                        .frame(width: 48, height: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settype wijzigen, nu \(set.type.name)")

                Text(firstColumn).sa(17, .medium, mono: true).foregroundColor(valueColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(String(set.r)).sa(17, .medium, mono: true).foregroundColor(valueColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Group {
                    if set.done {
                        Button { model.uncompleteSet(exID: exercise.id, setID: set.id) } label: {
                            Icon.check(20).foregroundColor(ac.accentText)
                                .frame(width: 44, height: 44).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Haal vinkje weg")
                    } else if isCur {
                        Text("NU").sa(12, .bold, tracking: 0.48).foregroundColor(ac.accentText)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 44, alignment: .trailing)
            }
            .padding(.leading, 16).padding(.trailing, 8)
            .frame(height: Size.setRow)
            .card(rowFill, radius: Radius.field)
            .overlay(RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                .fill(Tokens.text.opacity(isCur ? 0.10 : 0)))
            .overlay(RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                .stroke(isCur ? ac.accentLine : Color.clear, lineWidth: 2))
            .offset(x: dx)
            .contentShape(Rectangle())
            .onTapGesture { model.selectSet(exID: exercise.id, setID: set.id) }
            .simultaneousGesture(
                DragGesture(minimumDistance: 14)
                    .onChanged { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            dx = min(0, value.translation.width)
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -90 && abs(value.translation.width) > abs(value.translation.height) {
                            dx = 0
                            model.deleteSet(exID: exercise.id, setID: set.id)
                        } else {
                            withAnimation(.easeOut(duration: 0.2)) { dx = 0 }
                        }
                    }
            )
        }
        .frame(height: Size.setRow)
        .background(RoundedRectangle(cornerRadius: Radius.field, style: .continuous).fill(dx < 0 ? Tokens.danger : Color.clear))
        .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
    }
}

// MARK: - Onderkant: melding, rust, dock

private struct WorkoutBottom: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    let session: LiveSession
    let cur: QueueItem?
    let hasQueue: Bool

    var body: some View {
        VStack(spacing: 0) {
            if let toast = model.toast {
                TimelineView(.periodic(from: Date(), by: 0.5)) { context in
                    if toast.until > context.date {
                        HStack {
                            Text(toast.text).sa(15, .medium).foregroundColor(Tokens.onInverse)
                            Spacer()
                            if toast.removed != nil {
                                Button { model.undo() } label: {
                                    Text("Ongedaan maken").sa(15, .bold).underline().foregroundColor(Tokens.onInverse)
                                        .padding(.horizontal, 12).frame(height: 44)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.leading, 16).padding(.trailing, 6)
                        .frame(height: 52)
                        .card(Tokens.inverse, radius: Radius.button)
                        .padding(.horizontal, 12).padding(.bottom, 8)
                    }
                }
            }

            if let end = model.restEnd, cur != nil {
                RestBar(end: end, total: model.restTotal)
            }

            if let cur = cur, let ex = session.exercise(cur.exID), let set = session.findSet(cur.setID) {
                Dock(session: session, exercise: ex, set: set)
            } else if hasQueue {
                VStack(spacing: 0) {
                    Text("Alle sets gedaan. Sterk werk.").sa(15).foregroundColor(Tokens.text2).padding(.bottom, 12)
                    PrimaryButton(title: "Workout afronden", height: 58, fontSize: 18) { model.finish() }
                }
                .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 12)
                .background(TopRounded(radius: Radius.sheetTop).fill(Tokens.surface).ignoresSafeArea(edges: .bottom))
            }
        }
    }
}

private struct RestBar: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    let end: Date
    let total: Int

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 0.25)) { context in
            let left = end.timeIntervalSince(context.date)
            if left <= 0 {
                HStack(spacing: 8) {
                    Icon.timer(16).foregroundColor(ac.accentText)
                    Text("Rust voorbij").sa(13, .medium).foregroundColor(Tokens.text2)
                    Text("+" + Format.clock(seconds: Int(-left))).sa(14, .semibold, mono: true).foregroundColor(ac.accentText)
                    Spacer(minLength: 0)
                    Button { model.skipRest() } label: {
                        Icon.close(14).foregroundColor(Tokens.text2).frame(width: 44, height: 36).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Sluit")
                }
                .padding(.leading, 14).padding(.trailing, 2)
                .frame(height: 36)
                .card(ac.accentSoft, radius: Radius.field)
                .padding(.horizontal, 12).padding(.bottom, 6)
            } else {
                let pct = max(0, min(1, left / Double(max(1, total))))
                ZStack(alignment: .leading) {
                    GeometryReader { geo in
                        Rectangle().fill(ac.accentSoft).frame(width: geo.size.width * CGFloat(pct))
                    }
                    HStack(spacing: 4) {
                        Icon.timer(20).foregroundColor(Tokens.text)
                        Text("Rust").sa(15, .medium).foregroundColor(Tokens.text2).padding(.leading, 4)
                        Text(Format.clock(seconds: Int(left + 0.999))).sa(22, .semibold, mono: true)
                            .foregroundColor(Tokens.text).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 8)
                        Button { model.adjustRest(-15) } label: {
                            Text("−15").sa(15, .semibold, mono: true).foregroundColor(Tokens.text).frame(width: 48, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("15 seconden minder")
                        Button { model.adjustRest(15) } label: {
                            Text("+15").sa(15, .semibold, mono: true).foregroundColor(Tokens.text).frame(width: 48, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("15 seconden meer")
                        Button { model.skipRest() } label: {
                            Text("Sla over").sa(15, .semibold).foregroundColor(Tokens.text)
                                .padding(.horizontal, 14).frame(height: 44)
                                .background(Capsule().fill(Tokens.surface))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.leading, 14).padding(.trailing, 6)
                }
                .frame(height: Size.restBar)
                .card(Tokens.raised, radius: Radius.button)
                .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
                .padding(.horizontal, 12).padding(.bottom, 8)
            }
        }
    }
}

private struct Dock: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @State private var buffer: String?
    let session: LiveSession
    let exercise: LiveExercise
    let set: LiveSet

    private var tag: (text: String, color: Color) {
        let nums = exercise.sets.filter { $0.type != .warmup && $0.type != .drop }
        let ni = (nums.firstIndex(where: { $0.id == set.id }) ?? -1) + 1
        switch set.type {
        case .warmup: return ("Warming-up", Tokens.warm)
        case .drop: return ("Dropset", Tokens.drop)
        case .failure: return ("Tot falen \u{00B7} \(ni) van \(nums.count)", Tokens.danger)
        case .work: return ("Set \(ni) van \(nums.count)", Tokens.text2)
        }
    }

    private var prevText: String {
        let kind = Catalog.kind(exercise.name)
        var prev: String
        if let pw = set.pw, let pr = set.pr {
            prev = "Vorige keer " + Format.setText(kind, pw, pr)
        } else {
            prev = "Nog geen vorige keer"
        }
        if kind == .timed { prev = set.type == .warmup ? "Warming-up" : "Op tijd" }
        if set.done { prev = "Gedaan \u{00B7} pas aan en tik op Klaar" }
        if let m = set.rmax, let lo = set.rmin, m > lo, kind != .cardio && kind != .timed { prev += " \u{00B7} doel \(lo)\u{2013}\(m) reps" }
        return prev
    }

    var body: some View {
        let t = tag
        let kind = Catalog.kind(exercise.name)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Button {
                    if model.editField == nil { model.editField = (kind == .timed) ? .reps : .weight }
                } label: {
                    Text(exercise.name).sa(15, .semibold).foregroundColor(Tokens.text).lineLimit(1)
                        .frame(minHeight: 32, alignment: .leading).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
                Text(t.text).sa(13, .semibold).foregroundColor(t.color)
                if model.editField != nil {
                    Button { model.editField = nil } label: {
                        Icon.close(16).foregroundColor(Tokens.text2)
                            .frame(width: 44, height: 36)
                            .background(Circle().fill(Tokens.raised).frame(width: 32, height: 32))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, -8)
                    .accessibilityLabel("Sluit invoer")
                }
            }
            .padding(.horizontal, 4)
            Text(prevText).sa(12, .regular, mono: true).foregroundColor(Tokens.text2)
                .padding(.horizontal, 4).padding(.top, 1)

            HStack(spacing: 10) {
                if kind != .timed { weightBox(kind) }
                repsBox(kind)
            }
            .padding(.top, 10)

            if model.editField != nil {
                Numpad(onKey: { key($0, kind) })
                    .padding(.top, 10)
                HStack(spacing: 10) {
                    Button { model.editField = nil } label: {
                        Text("Klaar met invullen").sa(16, .semibold).foregroundColor(Tokens.text)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .card(Tokens.raised, radius: Radius.button)
                    }
                    .buttonStyle(.plain)
                    PrimaryButton(title: set.done ? "Klaar" : "Set klaar", height: 52, icon: Icon.check(22)) { model.complete() }
                }
                .padding(.top, 10)
            } else {
                PrimaryButton(title: set.done ? "Klaar" : "Set klaar", height: Size.primaryButton, icon: Icon.check(22)) { model.complete() }
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 12)
        .background(TopRounded(radius: Radius.sheetTop).fill(Tokens.surface).ignoresSafeArea(edges: .bottom))
        .contentShape(Rectangle())
        .onTapGesture {
            if model.editField == nil { model.editField = (kind == .timed) ? .reps : .weight }
        }
        .animation(.easeOut(duration: 0.22), value: model.editField)
        .onChange(of: model.editField) { _ in buffer = nil }
        .onChange(of: set.id) { _ in buffer = nil }
    }

    // MARK: Invoer

    private func weightText(_ kind: ExerciseKind) -> String {
        kind == .cardio ? Format.km(set.w) : Format.weight(set.w)
    }

    private func key(_ k: NumpadKey, _ kind: ExerciseKind) {
        guard let field = model.editField else { return }
        var text = buffer ?? ""
        switch k {
        case .digit(let d):
            if text.count < 6 { text += String(d) }
        case .comma:
            if field == .weight && !text.contains(",") { text += text.isEmpty ? "0," : "," }
        case .back:
            if !text.isEmpty { text.removeLast() }
        }
        buffer = text
        let parsed = text.replacingOccurrences(of: ",", with: ".")
        if field == .weight {
            if let v = Double(parsed) { model.setCurrentValues(w: v, r: nil) } else if text.isEmpty { model.setCurrentValues(w: 0, r: nil) }
        } else if let v = Int(parsed) {
            model.setCurrentValues(w: nil, r: v)
        } else if text.isEmpty {
            model.setCurrentValues(w: nil, r: 0)
        }
    }

    private func shown(_ field: EditField, _ normal: String) -> String {
        if model.editField == field, let b = buffer { return b.isEmpty ? "0" : b }
        return normal
    }

    private func weightBox(_ kind: ExerciseKind) -> some View {
        valueBox(field: .weight, text: shown(.weight, weightText(kind)), unit: kind == .cardio ? " km" : " kg",
                 minus: "Minder gewicht", plus: "Meer gewicht",
                 onMinus: { buffer = nil; model.stepWeight(-1) }, onPlus: { buffer = nil; model.stepWeight(1) })
    }

    private func repsBox(_ kind: ExerciseKind) -> some View {
        valueBox(field: .reps, text: shown(.reps, String(set.r)), unit: (kind == .cardio || kind == .timed) ? " min" : " reps",
                 minus: "Minder reps", plus: "Meer reps",
                 onMinus: { buffer = nil; model.stepReps(-1) }, onPlus: { buffer = nil; model.stepReps(1) })
    }

    private func valueBox(field: EditField, text: String, unit: String, minus: String, plus: String,
                          onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        let active = model.editField == field
        return HStack(spacing: 0) {
            Button(action: onMinus) {
                Icon.minus(20).foregroundColor(Tokens.text).frame(width: Size.stepperButtonWidth, height: Size.stepperBar)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(minus)
            Button { model.editField = field } label: {
                HStack(spacing: 0) {
                    Text(text).sa(26, .semibold, tracking: -0.5, mono: true).foregroundColor(Tokens.text)
                    Text(unit).sa(13, .medium).foregroundColor(Tokens.text2)
                }
                .lineLimit(1).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity).frame(height: Size.stepperBar)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Vul in met het toetsenblok")
            Button(action: onPlus) {
                Icon.plus(20, 2.4).foregroundColor(Tokens.text).frame(width: Size.stepperButtonWidth, height: Size.stepperBar)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(plus)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Size.stepperBar)
        .card(Tokens.raised, radius: Radius.row)
        .overlay(RoundedRectangle(cornerRadius: Radius.row, style: .continuous).stroke(active ? ac.accentLine : Color.clear, lineWidth: 2))
    }
}

enum NumpadKey: Hashable {
    case digit(Int), comma, back
}

/// Eigen toetsenblok: 1 t/m 9, komma, 0 en wissen.
private struct Numpad: View {
    let onKey: (NumpadKey) -> Void
    private let rows: [[NumpadKey]] = [
        [.digit(1), .digit(2), .digit(3)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(7), .digit(8), .digit(9)],
        [.comma, .digit(0), .back]
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { c in
                        keyButton(rows[r][c])
                    }
                }
            }
        }
    }

    private func keyButton(_ k: NumpadKey) -> some View {
        Button { onKey(k) } label: {
            Group {
                switch k {
                case .digit(let d): Text(String(d)).sa(24, .semibold, mono: true)
                case .comma: Text(",").sa(24, .semibold, mono: true)
                case .back: Text("\u{232B}").sa(22, .semibold)
                }
            }
            .foregroundColor(Tokens.text)
            .frame(maxWidth: .infinity).frame(height: 48)
            .card(Tokens.raised, radius: Radius.field)
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Notitie-popup

private struct NotePopup: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @FocusState private var focused: Bool

    private var textBinding: Binding<String> {
        Binding(get: { model.noteEdit?.text ?? "" }, set: { model.noteEdit?.text = $0 })
    }

    var body: some View {
        let edit = model.noteEdit
        let isNew = edit?.entryID == nil
        let empty = (edit?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return ZStack(alignment: .top) {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { model.noteEdit = nil }
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isNew ? "Nieuwe notitie" : "Notitie bewerken").sa(18, .bold).foregroundColor(Tokens.text)
                    Text(edit?.exercise ?? "").sa(13).foregroundColor(Tokens.text2)
                }
                TextField("Bijv. stoelstand 4", text: textBinding, axis: .vertical)
                    .focused($focused)
                    .lineLimit(1...5)
                    .sa(17).foregroundColor(Tokens.text)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .frame(minHeight: 52, alignment: .topLeading)
                    .card(Tokens.raised, radius: Radius.field)
                HStack(spacing: 10) {
                    Button { model.noteEdit = nil } label: {
                        Text("Annuleer").sa(16, .semibold).foregroundColor(Tokens.text)
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .card(Tokens.raised, radius: Radius.button)
                    }
                    .buttonStyle(.plain)
                    Button { model.saveNoteEdit() } label: {
                        Text("Bewaar").sa(16, .bold).foregroundColor(ac.onAccent)
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .card(ac.accent, radius: Radius.button)
                            .opacity(empty ? 0.4 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(empty)
                }
            }
            .padding(18)
            .card(Tokens.surface, radius: Radius.card)
            .padding(.horizontal, 16).padding(.top, 70)
        }
        .onAppear { focused = true }
    }
}
