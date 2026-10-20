import SwiftUI

/// Tab Voeding (optioneel, aan te zetten in Instellingen › Functionaliteiten).
/// Eerste versie: je doel kiezen, maaltijden van vandaag loggen en je supplementen afvinken.
struct NutritionTab: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    @State private var mealName = ""
    @State private var mealKcal = ""
    @State private var mealProtein = ""
    @FocusState private var focused: Bool

    var body: some View {
        let today = model.mealsToday
        let kcal = today.compactMap { $0.kcal }.reduce(0, +)
        let protein = today.compactMap { $0.protein }.reduce(0, +)
        VStack(alignment: .leading, spacing: 0) {
            Text(DateText.long(Date())).sa(13, .medium).foregroundColor(Tokens.text2)
                .frame(height: 44, alignment: .leading)
            ScreenTitle(text: "Voeding")

            // Doel
            SectionLabel(text: "Mijn doel").padding(.top, 20).padding(.bottom, 10)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 4) {
                    ForEach(NutritionPlan.allCases) { plan in
                        let on = model.nutritionPlan == plan
                        Button {
                            Haptics.selection()
                            withAnimation(Motion.pop) { model.nutritionPlan = plan }
                            model.save()
                        } label: {
                            Text(plan.title).sa(15, .semibold).foregroundColor(on ? ac.onAccent : Tokens.text2)
                                .frame(maxWidth: .infinity).frame(height: 40)
                                .background(Capsule().fill(on ? ac.accent : Color.clear))
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
                .padding(4)
                .card(Tokens.raised, radius: 24)
                Text(model.nutritionPlan.explanation).sa(14).foregroundColor(Tokens.text2).lineSpacing(3)
                    .id(model.nutritionPlan)
                    .transition(.opacity)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(radius: Radius.card)

            // Vandaag
            SectionLabel(text: "Vandaag").padding(.top, 24).padding(.bottom, 10)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    total(kcal, "kcal")
                    total(protein, "g eiwit")
                    total(today.count, today.count == 1 ? "maaltijd" : "maaltijden")
                }
                .animation(Motion.pop, value: today.count)

                if !today.isEmpty {
                    VStack(spacing: 0) {
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
                    .padding(.top, 12)
                }

                // Toevoegen
                VStack(spacing: 8) {
                    field("Wat at je? Bijv. Kip met rijst", text: $mealName, keyboard: .default)
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

            // Supplementen
            SectionLabel(text: "Supplementen").padding(.top, 24).padding(.bottom, 10)
            creatineCard
            Text("Herinneringen stel je in bij Instellingen › Meldingen. Die blijven ook werken als je Voeding uitzet.")
                .sa(13).foregroundColor(Tokens.text3).lineSpacing(3).padding(.top, 10)
        }
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

    private func total(_ value: Int, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Format.thousands(Double(value))).sa(24, .semibold, tracking: -0.4, mono: true).foregroundColor(Tokens.text)
                .rollingNumber()
            Text(label).sa(12).foregroundColor(Tokens.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var creatineCard: some View {
        let done = model.creaDoneToday
        return HStack(spacing: 4) {
            Button {
                Haptics.medium()
                withAnimation(Motion.pop) { model.toggleCreaDone() }
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
                .frame(width: 48, height: 52).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(done ? "Creatine vandaag gehad, tik om weg te halen" : "Creatine vandaag afvinken")
            Button { model.cameFromSettings = false; model.screen = .creatine } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Creatine").sa(16, .semibold).foregroundColor(Tokens.text)
                        Text(done ? "Vandaag gehad" : model.creaSummary).sa(13).foregroundColor(Tokens.text2).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Icon.chevronRight(16).foregroundColor(Tokens.text3)
                }
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .glassCard(radius: Radius.button)
    }
}
