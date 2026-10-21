import SwiftUI

/// "Voeding instellen": een paar vragen (zoals andere voedingsapps), daaruit rekent de app je dagdoel uit.
/// Je kunt het resultaat daarna nog aanpassen en kiezen wat je op het Voeding-scherm wilt zien.
struct NutritionSetupScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    @State private var profile = NutritionProfile()
    @State private var plan: NutritionPlan = .maintain
    @State private var targets = NutritionTargets(kcal: 2500, protein: 140, carbs: 300, fat: 70)
    @State private var layout = NutritionLayout()
    @State private var loaded = false

    private func recalc() {
        targets = NutritionTargets.calculate(profile: profile, plan: plan)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { model.screen = .home } label: {
                    HStack(spacing: 2) {
                        Icon.chevronLeft(22)
                        Text("Voeding").sa(17)
                    }
                    .foregroundColor(ac.accentText)
                    .padding(.leading, 4).padding(.trailing, 10).frame(height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 6).frame(height: 52)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Jouw doel").sa(30, .bold, tracking: -0.5).foregroundColor(Tokens.text)
                        .accessibilityAddTraits(.isHeader)
                    Text("Met een paar gegevens rekent de app uit hoeveel je per dag mag eten. Het blijft een schatting.")
                        .sa(15).foregroundColor(Tokens.text2).lineSpacing(3).padding(.top, 6)

                    SectionLabel(text: "Over jou").padding(.top, 24).padding(.bottom, 10)
                    aboutCard

                    SectionLabel(text: "Hoe actief ben je?").padding(.top, 24).padding(.bottom, 10)
                    activityCard

                    SectionLabel(text: "Wat wil je bereiken?").padding(.top, 24).padding(.bottom, 10)
                    planCard

                    SectionLabel(text: "Je dagdoel").padding(.top, 24).padding(.bottom, 10)
                    resultCard

                    SectionLabel(text: "Op je scherm").padding(.top, 24).padding(.bottom, 10)
                    layoutCard

                    PrimaryButton(title: "Opslaan", height: 56, fontSize: 18, icon: nil) {
                        Haptics.medium()
                        model.saveNutritionSetup(profile: profile, plan: plan, targets: targets, layout: layout)
                        model.screen = .home
                    }
                    .padding(.top, 28)
                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 48)
            }
        }
        .background(AppBackground())
        .onAppear {
            guard !loaded else { return }
            loaded = true
            profile = model.nutritionExtra.profile ?? NutritionProfile()
            plan = model.nutritionPlan
            layout = model.nutritionExtra.layout
            if model.nutritionExtra.profile == nil { recalc() }
            else { targets = NutritionTargets(kcal: model.kcalGoal, protein: model.proteinGoal, carbs: model.carbsGoal, fat: model.fatGoal) }
        }
    }

    // MARK: Onderdelen

    private var aboutCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(Sex.allCases) { s in
                    let on = profile.sex == s
                    Button {
                        Haptics.selection()
                        withAnimation(Motion.pop) { profile.sex = s }
                        recalc()
                    } label: {
                        Text(s.title).sa(15, .semibold).foregroundColor(on ? ac.onAccent : Tokens.text2)
                            .frame(maxWidth: .infinity).frame(height: 40)
                            .background(Capsule().fill(on ? ac.accent : Color.clear))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(4).card(Tokens.raised, radius: 24).padding(.vertical, 12)
            Divider().background(Tokens.line)
            stepRow("Leeftijd", "\(profile.age) jaar") { profile.age = min(90, max(14, profile.age + $0)); recalc() }
            Divider().background(Tokens.line)
            stepRow("Lengte", "\(profile.heightCm) cm") { profile.heightCm = min(230, max(120, profile.heightCm + $0)); recalc() }
            Divider().background(Tokens.line)
            stepRow("Gewicht", String(format: "%.1f kg", profile.weightKg).replacingOccurrences(of: ".", with: ","), step: 1) {
                profile.weightKg = min(250, max(30, profile.weightKg + Double($0) * 0.5)); recalc()
            }
        }
        .padding(.horizontal, 16)
        .glassCard(radius: Radius.button)
    }

    private func stepRow(_ title: String, _ value: String, step: Int = 1, change: @escaping (Int) -> Void) -> some View {
        HStack {
            Text(title).sa(16, .medium).foregroundColor(Tokens.text)
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                Button { Haptics.light(); withAnimation(Motion.pop) { change(-step) } } label: {
                    Icon.minus(18).foregroundColor(Tokens.text).frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain).accessibilityLabel("Minder \(title.lowercased())")
                Text(value).sa(16, .semibold, mono: true).foregroundColor(Tokens.text).frame(minWidth: 84).rollingNumber()
                Button { Haptics.light(); withAnimation(Motion.pop) { change(step) } } label: {
                    Icon.plus(18, 2.4).foregroundColor(Tokens.text).frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain).accessibilityLabel("Meer \(title.lowercased())")
            }
            .card(Tokens.raised, radius: Radius.field)
        }
        .frame(minHeight: 60)
    }

    private var activityCard: some View {
        VStack(spacing: 0) {
            ForEach(ActivityLevel.allCases) { a in
                let on = profile.activity == a
                Button {
                    Haptics.selection()
                    withAnimation(Motion.pop) { profile.activity = a }
                    recalc()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().stroke(on ? ac.accentLine : Tokens.line, lineWidth: 2)
                            if on { Circle().fill(ac.accentLine).padding(5).transition(.scale) }
                        }
                        .frame(width: 24, height: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(a.title).sa(16, .semibold).foregroundColor(Tokens.text)
                            Text(a.detail).sa(13).foregroundColor(Tokens.text2).multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
                if a != ActivityLevel.allCases.last { Divider().background(Tokens.line) }
            }
        }
        .padding(.horizontal, 16)
        .glassCard(radius: Radius.button)
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                ForEach(NutritionPlan.allCases) { p in
                    let on = plan == p
                    Button {
                        Haptics.selection()
                        withAnimation(Motion.pop) { plan = p }
                        recalc()
                    } label: {
                        Text(p.title).sa(14, .semibold).foregroundColor(on ? ac.onAccent : Tokens.text2)
                            .frame(maxWidth: .infinity).frame(height: 40)
                            .background(Capsule().fill(on ? ac.accent : Color.clear))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(4).card(Tokens.raised, radius: 24)
            Text(plan.explanation).sa(14).foregroundColor(Tokens.text2).lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: Radius.button)
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Per dag").sa(13, .medium).foregroundColor(ac.accentText)
            Text(Format.thousands(Double(targets.kcal))).sa(48, .bold, tracking: -1, mono: true).foregroundColor(Tokens.text)
                .rollingNumber()
            Text("kcal").sa(14).foregroundColor(Tokens.text2).padding(.bottom, 8)
            Divider().background(Tokens.line)
            stepRow("Calorieën", "\(targets.kcal)", step: 50) { targets.kcal = min(6000, max(1000, targets.kcal + $0)) }
            Divider().background(Tokens.line)
            stepRow("Eiwit", "\(targets.protein) g", step: 5) { targets.protein = min(400, max(30, targets.protein + $0)) }
            Divider().background(Tokens.line)
            stepRow("Koolhydraten", "\(targets.carbs) g", step: 5) { targets.carbs = min(900, max(0, targets.carbs + $0)) }
            Divider().background(Tokens.line)
            stepRow("Vetten", "\(targets.fat) g", step: 5) { targets.fat = min(300, max(10, targets.fat + $0)) }
            Text("Verander je iets hierboven, dan reken ik opnieuw uit. Hier kun je het daarna nog fijn afstellen.")
                .sa(12).foregroundColor(Tokens.text3).lineSpacing(2).padding(.vertical, 12)
        }
        .padding(.horizontal, 16).padding(.top, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: Radius.card)
    }

    private var layoutCard: some View {
        VStack(spacing: 0) {
            toggleRow("Koolhydraten", "Cirkel met je koolhydraten", isOn: layout.carbs) { layout.carbs.toggle() }
            Divider().background(Tokens.line)
            toggleRow("Vetten", "Cirkel met je vetten", isOn: layout.fat) { layout.fat.toggle() }
            Divider().background(Tokens.line)
            toggleRow("Water", "Houd bij hoeveel je drinkt", isOn: layout.water) { layout.water.toggle() }
            Divider().background(Tokens.line)
            toggleRow("Supplementen", "Creatine, omega 3 en meer", isOn: layout.supplements) { layout.supplements.toggle() }
        }
        .padding(.horizontal, 16)
        .glassCard(radius: Radius.button)
    }

    private func toggleRow(_ title: String, _ sub: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).sa(16, .medium).foregroundColor(Tokens.text)
                Text(sub).sa(13).foregroundColor(Tokens.text2)
            }
            Spacer(minLength: 0)
            SAToggle(isOn: isOn, onColor: ac.accentLine, label: title) {
                Haptics.selection()
                withAnimation(Motion.pop) { action() }
            }
        }
        .frame(minHeight: 64)
    }
}
