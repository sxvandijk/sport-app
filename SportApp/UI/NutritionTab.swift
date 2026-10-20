import SwiftUI

/// Tab Voeding: bovenin hoeveel je hebt gegeten en hoeveel er nog mag, daaronder je maaltijden en supplementen.
/// Eten log je met een naam en je eigen kcal en eiwit; een productendatabase zit er (nog) niet in.
struct NutritionTab: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    @State private var mealName = ""
    @State private var mealKcal = ""
    @State private var mealProtein = ""
    @State private var showGoals = false
    @State private var newSupplement = ""
    @FocusState private var focused: Bool

    var body: some View {
        let today = model.mealsToday
        let kcal = today.compactMap { $0.kcal }.reduce(0, +)
        let protein = today.compactMap { $0.protein }.reduce(0, +)
        VStack(alignment: .leading, spacing: 0) {
            Text(DateText.long(Date())).sa(13, .medium).foregroundColor(Tokens.text2)
                .frame(height: 44, alignment: .leading)
            ScreenTitle(text: "Voeding")

            summaryCard(kcal: kcal, protein: protein)
                .padding(.top, 16)

            // Maaltijden
            SectionLabel(text: "Vandaag gegeten").padding(.top, 24).padding(.bottom, 10)
            mealsCard(today)

            // Supplementen
            SectionLabel(text: "Supplementen").padding(.top, 24).padding(.bottom, 10)
            supplementsCard
        }
    }

    // MARK: Samenvatting en doelen

    private func summaryCard(kcal: Int, protein: Int) -> some View {
        let goal = model.kcalGoal
        let left = goal - kcal
        let over = left < 0
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(Format.thousands(Double(kcal))).sa(40, .bold, tracking: -1, mono: true).foregroundColor(Tokens.text)
                        .rollingNumber()
                    Text("kcal gegeten van \(Format.thousands(Double(goal)))").sa(13).foregroundColor(Tokens.text2)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(Format.thousands(Double(abs(left)))).sa(22, .semibold, mono: true)
                        .foregroundColor(over ? Tokens.danger : ac.accentText)
                        .rollingNumber()
                    Text(over ? "kcal te veel" : "kcal nog te eten").sa(13).foregroundColor(Tokens.text2)
                }
            }
            bar(value: Double(kcal), goal: Double(goal), color: over ? Tokens.danger : ac.accent, height: 12)

            HStack {
                Text("Eiwit").sa(15, .semibold).foregroundColor(Tokens.text)
                Spacer(minLength: 0)
                Text("\(protein) / \(model.proteinGoal) g").sa(15, .regular, mono: true).foregroundColor(Tokens.text2)
                    .rollingNumber()
            }
            bar(value: Double(protein), goal: Double(model.proteinGoal), color: ac.accentLine, height: 8)

            Button {
                Haptics.selection()
                withAnimation(Motion.tabContent) { showGoals.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Text(showGoals ? "Klaar" : "Doel aanpassen").sa(15, .semibold)
                    Icon.chevronDown(12, 2.4).rotationEffect(.degrees(showGoals ? 180 : 0))
                }
                .foregroundColor(ac.accentText)
                .frame(minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showGoals { goalEditor.transition(.opacity) }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: Radius.card)
    }

    private func bar(value: Double, goal: Double, color: Color, height: CGFloat) -> some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Tokens.raised)
                Capsule().fill(color)
                    .frame(width: max(height, g.size.width * CGFloat(min(1, goal > 0 ? value / goal : 0))))
                    .opacity(value > 0 ? 1 : 0)
                    .animation(Motion.reveal, value: value)
            }
        }
        .frame(height: height)
    }

    private var goalEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                ForEach(NutritionPlan.allCases) { plan in
                    let on = model.nutritionPlan == plan
                    Button {
                        Haptics.selection()
                        withAnimation(Motion.pop) { model.nutritionPlan = plan }
                        // Een nieuw doel zet een nieuwe beginwaarde; eigen aanpassingen gaan daarmee weg.
                        model.nutritionKcalGoal = nil
                        model.save()
                    } label: {
                        Text(plan.title).sa(14, .semibold).foregroundColor(on ? ac.onAccent : Tokens.text2)
                            .frame(maxWidth: .infinity).frame(height: 38)
                            .background(Capsule().fill(on ? ac.accent : Color.clear))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(4)
            .card(Tokens.raised, radius: 24)
            Text(model.nutritionPlan.explanation).sa(13).foregroundColor(Tokens.text2).lineSpacing(3)
            stepper("Calorieën per dag", value: model.kcalGoal, unit: "kcal", step: 50) { model.setNutritionGoals(kcal: model.kcalGoal + $0) }
            stepper("Eiwit per dag", value: model.proteinGoal, unit: "g", step: 5) { model.setNutritionGoals(protein: model.proteinGoal + $0) }
            Text("Dit zijn beginwaarden. Zet ze op wat bij jou past.").sa(12).foregroundColor(Tokens.text3)
        }
    }

    private func stepper(_ title: String, value: Int, unit: String, step: Int, change: @escaping (Int) -> Void) -> some View {
        HStack {
            Text(title).sa(15, .medium).foregroundColor(Tokens.text)
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                Button { Haptics.light(); withAnimation(Motion.pop) { change(-step) } } label: {
                    Icon.minus(18).foregroundColor(Tokens.text).frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Minder \(title.lowercased())")
                Text("\(Format.thousands(Double(value))) \(unit)").sa(15, .semibold, mono: true).foregroundColor(Tokens.text)
                    .frame(minWidth: 84).rollingNumber()
                Button { Haptics.light(); withAnimation(Motion.pop) { change(step) } } label: {
                    Icon.plus(18, 2.4).foregroundColor(Tokens.text).frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Meer \(title.lowercased())")
            }
            .card(Tokens.raised, radius: Radius.field)
        }
    }

    // MARK: Maaltijden

    private func mealsCard(_ today: [MealEntry]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if today.isEmpty {
                Text("Nog niets gelogd vandaag.").sa(15).foregroundColor(Tokens.text2).padding(.bottom, 4)
            } else {
                ForEach(today) { meal in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(meal.name).sa(16, .medium).foregroundColor(Tokens.text).lineLimit(1)
                            Text(mealLine(meal)).sa(13, .regular, mono: true).foregroundColor(Tokens.text2)
                        }
                        Spacer(minLength: 0)
                        Button {
                            withAnimation(Motion.tabContent) { model.deleteMeal(meal.id) }
                        } label: {
                            Icon.trash(18).foregroundColor(Tokens.text3)
                                .frame(width: 44, height: 44).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Verwijder \(meal.name)")
                    }
                    .frame(minHeight: 56)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    if meal.id != today.last?.id { Divider().background(Tokens.line) }
                }
            }

            let recent = model.recentMeals
            if !recent.isEmpty {
                Text("Snel opnieuw toevoegen").sa(12, .semibold, tracking: 0.4).foregroundColor(Tokens.text2).padding(.top, 14)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recent) { m in
                            Button {
                                Haptics.medium()
                                withAnimation(Motion.pop) { model.addMeal(name: m.name, kcal: m.kcal, protein: m.protein) }
                            } label: {
                                HStack(spacing: 6) {
                                    Icon.plus(14, 2.6)
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
                .padding(.top, 8)
            }

            VStack(spacing: 8) {
                field("Wat at je? Bijv. kip met rijst", text: $mealName, keyboard: .default)
                HStack(spacing: 8) {
                    field("kcal", text: $mealKcal, keyboard: .numberPad)
                    field("eiwit (g)", text: $mealProtein, keyboard: .numberPad)
                }
                Button(action: addMeal) {
                    HStack(spacing: 6) {
                        Icon.plus(18, 2.4)
                        Text("Maaltijd toevoegen").sa(16, .semibold)
                    }
                    .foregroundColor(canAdd ? ac.onAccent : Tokens.text3)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(Capsule().fill(canAdd ? ac.accent : Tokens.raised))
                    .contentShape(Capsule())
                }
                .buttonStyle(PressScaleStyle())
                .disabled(!canAdd)
            }
            .padding(.top, 14)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: Radius.card)
    }

    private var canAdd: Bool {
        !mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addMeal() {
        guard canAdd else { return }
        Haptics.medium()
        withAnimation(Motion.pop) {
            model.addMeal(name: mealName, kcal: Int(mealKcal), protein: Int(mealProtein))
        }
        mealName = ""
        mealKcal = ""
        mealProtein = ""
        focused = false
    }

    private func mealLine(_ meal: MealEntry) -> String {
        var parts = [Format.hhmm(meal.date)]
        if let k = meal.kcal { parts.append("\(k) kcal") }
        if let p = meal.protein { parts.append("\(p) g eiwit") }
        return parts.joined(separator: " \u{00B7} ")
    }

    private func field(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .focused($focused)
            .submitLabel(.done)
            .onSubmit(addMeal)
            .sa(16)
            .foregroundColor(Tokens.text)
            .padding(.horizontal, 14)
            .frame(height: 48)
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
