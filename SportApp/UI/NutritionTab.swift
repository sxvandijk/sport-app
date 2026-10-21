import SwiftUI

/// Kleuren van de voedingswaarden, vast zodat ze overal hetzelfde zijn.
private enum Macro {
    static let carbs = Tokens.warm
    static let protein = Tokens.cool
    static let fat = Color(red: 0.93, green: 0.45, blue: 0.60)
}

/// Tab Voeding: een dagstrook om dagen terug te kijken, een meter met wat je nog mag eten, de cirkels met je
/// voedingswaarden, je maaltijden per moment van de dag en je supplementen. Eten log je met naam en eigen cijfers.
struct NutritionTab: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    @State private var addingKind: MealKind?
    @State private var mealName = ""
    @State private var mealKcal = ""
    @State private var mealProtein = ""
    @State private var mealCarbs = ""
    @State private var mealFat = ""
    @State private var newSupplement = ""
    @State private var showCalendar = false
    @FocusState private var focused: Bool

    private var day: Date { model.nutritionDay }
    private var isToday: Bool { Calendar.current.isDateInToday(day) }
    private var layout: NutritionLayout { model.nutritionExtra.layout }

    var body: some View {
        let meals = model.meals(on: day)
        let kcal = meals.compactMap { $0.kcal }.reduce(0, +)
        VStack(alignment: .leading, spacing: 0) {
            header
            weekStrip.padding(.top, 2)

            if model.nutritionExtra.profile == nil { setupPrompt.padding(.top, 12) }

            summaryCard(kcal: kcal).padding(.top, 10)
            macroRow(meals).padding(.top, 10)

            if !model.mealClipboard.isEmpty { pasteBar.padding(.top, 16) }

            HStack {
                SectionLabel(text: "Maaltijden")
                Spacer(minLength: 0)
                if !meals.isEmpty {
                    Button {
                        Haptics.medium()
                        model.mealClipboard = meals
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc").font(.system(size: 13, weight: .semibold))
                            Text("Kopieer dag").sa(13, .semibold)
                        }
                        .foregroundColor(ac.accentText).frame(minHeight: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 12)
            VStack(spacing: 10) {
                ForEach(MealKind.allCases) { kind in mealCard(kind) }
            }

            if layout.water { waterCard.padding(.top, 12) }

            if layout.supplements && isToday {
                SectionLabel(text: "Supplementen").padding(.top, 24).padding(.bottom, 10)
                supplementsCard
            }
        }
        .sheet(isPresented: $showCalendar) { calendarSheet }
    }

    // MARK: Kop en dagstrook

    private var dateTitle: String {
        let t = DateText.long(day)
        return t.prefix(1).uppercased() + t.dropFirst()
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                Haptics.selection()
                showCalendar = true
            } label: {
                HStack(spacing: 8) {
                    Text(dateTitle).sa(24, .bold, tracking: -0.5).foregroundColor(Tokens.text)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Icon.chevronDown(14, 2.8).foregroundColor(ac.accentText)
                }
                .frame(minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(dateTitle), open kalender")
            Spacer(minLength: 0)
            if !isToday {
                Button {
                    Haptics.selection()
                    withAnimation(Motion.tabContent) { model.nutritionDay = Date() }
                } label: {
                    Text("Vandaag").sa(13, .semibold).foregroundColor(ac.accentText)
                        .padding(.horizontal, 12).frame(height: 32)
                        .background(Capsule().fill(ac.accentSoft))
                        .frame(minHeight: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Button {
                Haptics.selection()
                model.screen = .nutritionSetup
            } label: {
                Icon.gear(20).foregroundColor(Tokens.text)
                    .frame(width: 44, height: 44)
                    .glassSurface(Circle(), interactive: true, fallback: Tokens.raised)
                    .contentShape(Circle())
            }
            .buttonStyle(PressScaleStyle(scale: 0.9))
            .accessibilityLabel("Voeding instellen")
        }
        .frame(height: 56)
    }

    private var calendarSheet: some View {
        VStack(spacing: 8) {
            DatePicker("Dag", selection: Binding(get: { model.nutritionDay }, set: { model.nutritionDay = $0 }),
                       displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(ac.accentText)
                .environment(\.locale, Locale(identifier: "nl_NL"))
            Button {
                Haptics.selection()
                model.nutritionDay = Date()
                showCalendar = false
            } label: {
                Text("Naar vandaag").sa(16, .semibold).foregroundColor(ac.accentText)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(Capsule().fill(ac.accentSoft))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 12)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var weekDays: [Date] {
        let cal = Calendar(identifier: .gregorian)
        var c = cal
        c.firstWeekday = 2
        let start = c.dateInterval(of: .weekOfYear, for: day)?.start ?? day
        return (0..<7).compactMap { c.date(byAdding: .day, value: $0, to: start) }
    }

    private var weekStrip: some View {
        let days = weekDays
        let letters = ["M", "D", "W", "D", "V", "Z", "Z"]
        return VStack(spacing: 0) {
            HStack {
                stripArrow("chevron.left", label: "Vorige week") { shift(-7) }
                Spacer(minLength: 0)
                Text(rangeText(days)).sa(13, .semibold).foregroundColor(Tokens.text2)
                Spacer(minLength: 0)
                stripArrow("chevron.right", label: "Volgende week") { shift(7) }
            }
            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, d in
                    let sel = Calendar.current.isDate(d, inSameDayAs: day)
                    let eaten = model.meals(on: d).compactMap { $0.kcal }.reduce(0, +)
                    let frac = min(1, Double(eaten) / Double(max(1, model.kcalGoal)))
                    Button {
                        Haptics.selection()
                        withAnimation(Motion.tabContent) { model.nutritionDay = d }
                    } label: {
                        VStack(spacing: 6) {
                            Text(letters[i]).sa(12, .semibold).foregroundColor(sel ? ac.accentText : Tokens.text3)
                            Text("\(Calendar.current.component(.day, from: d))").sa(17, .semibold, mono: true)
                                .foregroundColor(sel ? Tokens.text : Tokens.text2)
                            ZStack {
                                Circle().stroke(Tokens.track, lineWidth: 3)
                                Circle().trim(from: 0, to: frac)
                                    .stroke(frac >= 1 ? Tokens.danger : ac.accentLine, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                            }
                            .frame(width: 22, height: 22)
                        }
                        .frame(maxWidth: .infinity).frame(height: 76)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(sel ? ac.accentSoft : Color.clear)
                                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(sel ? ac.accentLine.opacity(0.6) : Color.clear, lineWidth: 1))
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(DateText.long(d))
                    .accessibilityAddTraits(sel ? .isSelected : [])
                }
            }
        }
    }

    private func stripArrow(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Image(systemName: symbol).font(.system(size: 13, weight: .bold)).foregroundColor(Tokens.text2)
                .frame(width: 44, height: 28).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func shift(_ days: Int) {
        let d = Calendar.current.date(byAdding: .day, value: days, to: day) ?? day
        withAnimation(Motion.tabContent) { model.nutritionDay = d }
    }

    private func rangeText(_ days: [Date]) -> String {
        guard let a = days.first, let b = days.last else { return "" }
        if Calendar.current.isDate(Date(), equalTo: a, toGranularity: .weekOfYear) { return "Deze week" }
        return DateText.short(a) + " – " + DateText.short(b)
    }

    // MARK: Doel instellen (eerste keer)

    private var setupPrompt: some View {
        Button {
            Haptics.medium()
            model.screen = .nutritionSetup
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "target").font(.system(size: 24, weight: .semibold)).foregroundColor(ac.onAccent)
                    .frame(width: 52, height: 52).primaryFill(Circle(), ac)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stel je doel in").sa(17, .bold).foregroundColor(Tokens.text)
                    Text("Beantwoord een paar vragen en krijg doelen die bij je passen").sa(13).foregroundColor(Tokens.text2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Icon.chevronRight(16).foregroundColor(Tokens.text3)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(radius: Radius.card)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle())
    }

    // MARK: Meter en cirkels

    private func summaryCard(kcal: Int) -> some View {
        let goal = model.kcalGoal
        let left = goal - kcal
        let over = left < 0
        let frac = Double(kcal) / Double(max(1, goal))
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(Format.thousands(Double(abs(left)))).sa(38, .bold, tracking: -1, mono: true)
                        .foregroundColor(over ? Tokens.danger : Tokens.text)
                        .rollingNumber()
                    Text(over ? "kcal boven je doel" : "kcal kun je nog eten").sa(14).foregroundColor(Tokens.text2)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(Format.thousands(Double(kcal))).sa(20, .semibold, mono: true).foregroundColor(ac.accentText).rollingNumber()
                    Text("van \(Format.thousands(Double(goal))) gegeten").sa(13).foregroundColor(Tokens.text2)
                }
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Tokens.track)
                    Capsule()
                        .fill(over ? AnyShapeStyle(Tokens.danger) : AnyShapeStyle(ac.gradient))
                        .frame(width: max(14, g.size.width * CGFloat(min(1, frac))))
                        .opacity(kcal > 0 ? 1 : 0)
                        .animation(Motion.reveal, value: kcal)
                }
            }
            .frame(height: 14)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: Radius.card)
    }

    private func macroRow(_ meals: [MealEntry]) -> some View {
        let p = meals.compactMap { $0.protein }.reduce(0, +)
        let c = meals.compactMap { $0.carbs }.reduce(0, +)
        let f = meals.compactMap { $0.fat }.reduce(0, +)
        return HStack(spacing: 10) {
            if layout.carbs { ring("Koolhydraten", value: c, goal: model.carbsGoal, color: Macro.carbs) }
            ring("Eiwitten", value: p, goal: model.proteinGoal, color: Macro.protein)
            if layout.fat { ring("Vetten", value: f, goal: model.fatGoal, color: Macro.fat) }
        }
    }

    private func ring(_ title: String, value: Int, goal: Int, color: Color) -> some View {
        let frac = Double(value) / Double(max(1, goal))
        return VStack(spacing: 6) {
            ZStack {
                Circle().stroke(Tokens.track, lineWidth: 7)
                Circle().trim(from: 0, to: max(0.001, min(1, frac)))
                    .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .opacity(value > 0 ? 1 : 0)
                    .animation(Motion.reveal, value: value)
                HStack(alignment: .top, spacing: 1) {
                    Text("\(Int((frac * 100).rounded()))").sa(17, .bold, mono: true).foregroundColor(color).rollingNumber()
                    Text("%").sa(9, .bold).foregroundColor(color).padding(.top, 2)
                }
            }
            .frame(width: 60, height: 60)
            Text(title).sa(12, .semibold).foregroundColor(Tokens.text).lineLimit(1).minimumScaleFactor(0.7)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("\(value)").sa(15, .bold, mono: true).foregroundColor(Tokens.text).rollingNumber()
                Text("/\(goal)g").sa(12, .regular, mono: true).foregroundColor(Tokens.text2)
            }
        }
        .padding(.vertical, 12).padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .glassCard(radius: Radius.card)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value) van \(goal) gram")
    }

    private var waterCard: some View {
        let ml = model.waterMl(on: day)
        let goal = model.waterGoalMl
        return HStack(spacing: 14) {
            Image(systemName: "drop.fill").font(.system(size: 22)).foregroundColor(Tokens.cool)
                .frame(width: 44, height: 44).background(Circle().fill(Tokens.cool.opacity(0.18)))
            VStack(alignment: .leading, spacing: 2) {
                Text("Water").sa(16, .semibold).foregroundColor(Tokens.text)
                Text(String(format: "%.2f van %.1f liter", Double(ml) / 1000, Double(goal) / 1000).replacingOccurrences(of: ".", with: ","))
                    .sa(13, .regular, mono: true).foregroundColor(Tokens.text2)
            }
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                Button { Haptics.light(); withAnimation(Motion.pop) { model.addWater(-250, on: day) } } label: {
                    Icon.minus(18).foregroundColor(Tokens.text).frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain).accessibilityLabel("Minder water")
                Button { Haptics.medium(); withAnimation(Motion.pop) { model.addWater(250, on: day) } } label: {
                    Icon.plus(18, 2.4).foregroundColor(Tokens.text).frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain).accessibilityLabel("Een glas water erbij")
            }
            .card(Tokens.raised, radius: Radius.field)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .glassCard(radius: Radius.card)
    }

    // MARK: Kopiëren en plakken

    private var pasteBar: some View {
        let n = model.mealClipboard.count
        return HStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard").font(.system(size: 18, weight: .semibold)).foregroundColor(ac.accentText)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(n) \(n == 1 ? "maaltijd" : "maaltijden") gekopieerd").sa(15, .semibold).foregroundColor(Tokens.text)
                Text("Plak ze op \(isToday ? "vandaag" : DateText.long(day))").sa(13).foregroundColor(Tokens.text2)
            }
            Spacer(minLength: 0)
            Button {
                Haptics.medium()
                withAnimation(Motion.pop) { model.pasteMeals(on: day) }
            } label: {
                Text("Plak").sa(15, .bold).foregroundColor(ac.onAccent)
                    .padding(.horizontal, 18).frame(height: 40)
                    .primaryFill(Capsule(), ac)
                    .frame(minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(PressScaleStyle())
            Button {
                withAnimation(Motion.pop) { model.mealClipboard = [] }
            } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundColor(Tokens.text3)
                    .frame(width: 36, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain).accessibilityLabel("Gekopieerde maaltijden wissen")
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .glassCard(radius: Radius.card)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: Maaltijden per moment

    private func symbol(_ kind: MealKind) -> (name: String, color: Color) {
        switch kind {
        case .breakfast: return ("sun.max.fill", Color(red: 1.0, green: 0.78, blue: 0.25))
        case .lunch: return ("fork.knife", Tokens.cool)
        case .dinner: return ("moon.stars.fill", Color(red: 0.62, green: 0.58, blue: 1.0))
        case .snack: return ("cup.and.saucer.fill", Color(red: 0.45, green: 0.85, blue: 0.62))
        }
    }

    private func mealCard(_ kind: MealKind) -> some View {
        let items = model.meals(on: day, kind: kind)
        let eaten = items.compactMap { $0.kcal }.reduce(0, +)
        let room = Int((Double(model.kcalGoal) * kind.share).rounded())
        let open = addingKind == kind
        let sym = symbol(kind)
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                Haptics.selection()
                withAnimation(Motion.tabContent) {
                    addingKind = open ? nil : kind
                    focused = false
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: sym.name).font(.system(size: 20, weight: .semibold)).foregroundColor(sym.color)
                        .frame(width: 48, height: 48).background(Circle().fill(sym.color.opacity(0.16)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(kind.title).sa(17, .bold).foregroundColor(Tokens.text)
                        Text(items.isEmpty ? "Nog niets \u{00B7} \u{00B1}\(room) kcal ruimte" : "\(eaten) kcal \u{00B7} \(items.count) \(items.count == 1 ? "item" : "items")")
                            .sa(13, .regular, mono: true).foregroundColor(Tokens.text2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: open ? "xmark" : "plus").font(.system(size: 15, weight: .bold))
                        .foregroundColor(ac.accentText)
                        .frame(width: 36, height: 36).background(Circle().fill(ac.accentSoft))
                        .contentTransition(.symbolEffect(.replace))
                }
                .padding(.horizontal, 14).frame(minHeight: 72)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(kind.title) \(open ? "sluiten" : "toevoegen")")

            if !items.isEmpty {
                VStack(spacing: 0) {
                    ForEach(items) { meal in
                        Divider().background(Tokens.line)
                        HStack(spacing: 4) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(meal.name).sa(15, .semibold).foregroundColor(Tokens.text).lineLimit(1)
                                Text(mealLine(meal)).sa(12, .regular, mono: true).foregroundColor(Tokens.text2).lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            Button {
                                Haptics.medium()
                                withAnimation(Motion.pop) { model.mealClipboard = [meal] }
                            } label: {
                                Image(systemName: "doc.on.doc").font(.system(size: 15)).foregroundColor(Tokens.text3)
                                    .frame(width: 44, height: 44).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain).accessibilityLabel("Kopieer \(meal.name)")
                            Button {
                                withAnimation(Motion.tabContent) { model.deleteMeal(meal.id) }
                            } label: {
                                Icon.trash(17).foregroundColor(Tokens.text3)
                                    .frame(width: 44, height: 44).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain).accessibilityLabel("Verwijder \(meal.name)")
                        }
                        .padding(.leading, 16).padding(.trailing, 6).frame(minHeight: 52)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }

            if open {
                Divider().background(Tokens.line)
                addForm(kind).padding(14).transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: Radius.card)
    }

    private func mealLine(_ meal: MealEntry) -> String {
        var parts: [String] = []
        if let k = meal.kcal { parts.append("\(k) kcal") }
        if let p = meal.protein { parts.append("E \(p)") }
        if layout.carbs, let c = meal.carbs { parts.append("K \(c)") }
        if layout.fat, let f = meal.fat { parts.append("V \(f)") }
        return parts.isEmpty ? Format.hhmm(meal.date) : parts.joined(separator: " \u{00B7} ")
    }

    private func addForm(_ kind: MealKind) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            let recent = model.recentMeals
            if !recent.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recent) { m in
                            Button {
                                Haptics.medium()
                                withAnimation(Motion.pop) {
                                    model.addMeal(name: m.name, kcal: m.kcal, protein: m.protein, carbs: m.carbs, fat: m.fat, kind: kind, on: day)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Icon.plus(13, 2.6)
                                    Text(m.name).sa(14, .semibold).lineLimit(1)
                                }
                                .foregroundColor(ac.accentText)
                                .padding(.horizontal, 14).frame(height: 40)
                                .background(Capsule().fill(ac.accentSoft))
                                .contentShape(Capsule())
                            }
                            .buttonStyle(PressScaleStyle())
                        }
                    }
                }
            }
            field("Wat at je bij \(kind.title.lowercased())?", text: $mealName, keyboard: .default, icon: "magnifyingglass")
            HStack(spacing: 8) {
                field("kcal", text: $mealKcal, keyboard: .numberPad)
                field("eiwit (g)", text: $mealProtein, keyboard: .numberPad)
            }
            if layout.carbs || layout.fat {
                HStack(spacing: 8) {
                    if layout.carbs { field("koolh. (g)", text: $mealCarbs, keyboard: .numberPad) }
                    if layout.fat { field("vet (g)", text: $mealFat, keyboard: .numberPad) }
                }
            }
            Button { addMeal(kind) } label: {
                Text("Toevoegen").sa(16, .bold)
                    .foregroundColor(canAdd ? ac.onAccent : Tokens.text3)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Capsule().fill(canAdd ? AnyShapeStyle(ac.gradient) : AnyShapeStyle(Tokens.raised)))
                    .contentShape(Capsule())
            }
            .buttonStyle(PressScaleStyle())
            .disabled(!canAdd)
        }
    }

    private var canAdd: Bool { !mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private func addMeal(_ kind: MealKind) {
        guard canAdd else { return }
        Haptics.medium()
        withAnimation(Motion.pop) {
            model.addMeal(name: mealName, kcal: Int(mealKcal), protein: Int(mealProtein),
                          carbs: Int(mealCarbs), fat: Int(mealFat), kind: kind, on: day)
        }
        mealName = ""; mealKcal = ""; mealProtein = ""; mealCarbs = ""; mealFat = ""
        focused = false
    }

    private func field(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType, icon: String? = nil) -> some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundColor(Tokens.text3)
            }
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .focused($focused)
                .submitLabel(.done)
                .sa(16).foregroundColor(Tokens.text)
        }
        .padding(.horizontal, 14).frame(height: 48)
        .card(Tokens.raised, radius: Radius.field)
    }

    // MARK: Supplementen

    private var supplementsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            supplementRow(title: "Creatine", sub: model.creaDoneToday ? "Vandaag gehad" : model.creaSummary,
                          done: model.creaDoneToday, toggle: { model.toggleCreaDone() }) {
                model.cameFromSettings = false
                model.screen = .creatine
            }
            ForEach(model.supplements) { s in
                Divider().background(Tokens.line)
                supplementRow(title: s.name, sub: model.supplementDoneToday(s) ? "Vandaag gehad" : model.supplementSummary(s),
                              done: model.supplementDoneToday(s), toggle: { model.toggleSupplementDone(s.id) }) {
                    model.supplementEditID = s.id
                    model.screen = .supplement
                }
            }
            Divider().background(Tokens.line)
            HStack(spacing: 8) {
                TextField("Nieuw supplement, bijv. Vitamine D", text: $newSupplement)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(addSupplement)
                    .sa(16).foregroundColor(Tokens.text)
                    .frame(height: 52)
                Button(action: addSupplement) {
                    Icon.plus(18, 2.6).foregroundColor(newSupplement.trimmingCharacters(in: .whitespaces).isEmpty ? Tokens.text3 : ac.accentText)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Supplement toevoegen")
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: Radius.card)
    }

    private func addSupplement() {
        guard !newSupplement.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Haptics.medium()
        withAnimation(Motion.tabContent) { model.addSupplement(name: newSupplement) }
        newSupplement = ""
        focused = false
    }

    private func supplementRow(title: String, sub: String, done: Bool, toggle: @escaping () -> Void, open: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Button {
                Haptics.medium()
                withAnimation(Motion.pop) { toggle() }
            } label: {
                ZStack {
                    Circle().fill(done ? ac.accentLine : Color.clear)
                    Circle().stroke(done ? Color.clear : Tokens.line, lineWidth: 2)
                    if done {
                        Icon.check(14, 3).foregroundColor(ac.onAccent)
                            .transition(.scale(scale: 0.3).combined(with: .opacity))
                    }
                }
                .frame(width: 28, height: 28)
                .frame(width: 48, height: 60).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(done ? "\(title) vandaag gehad, tik om weg te halen" : "\(title) vandaag afvinken")
            Button(action: open) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title).sa(16, .semibold).foregroundColor(Tokens.text)
                        Text(sub).sa(13).foregroundColor(Tokens.text2).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Icon.chevronRight(16).foregroundColor(Tokens.text3)
                }
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
