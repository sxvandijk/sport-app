import SwiftUI

/// Het scherm bij het openen van de app: in het midden de volgende training, één tik om te beginnen.
struct StartTab: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    var body: some View {
        let next = model.nextWorkoutName()
        VStack(spacing: 0) {
            Text(DateText.long(Date())).sa(13, .medium).foregroundColor(Tokens.text2)
                .frame(height: 44)
                .frame(maxWidth: .infinity)

            CalendarCard(expandable: true)

            Spacer(minLength: 24)
            hero(next)
            Spacer(minLength: 24)
        }
        .frame(minHeight: UIScreen.main.bounds.height - 230)
    }

    @ViewBuilder
    private func hero(_ next: String?) -> some View {
        if let s = model.session {
            VStack(spacing: 8) {
                Text("Training bezig").sa(13, .semibold).foregroundColor(ac.accentText)
                Text(s.name).sa(44, .bold, tracking: -1).foregroundColor(Tokens.text)
                Text("\(s.openWorkSets) sets te gaan").sa(15).foregroundColor(Tokens.text2)
                PrimaryButton(title: "Verder met trainen", height: 64, fontSize: 19, icon: Icon.play(18)) {
                    model.screen = .workout
                }
                .padding(.top, 20)
            }
            .frame(maxWidth: .infinity)
        } else if let name = next {
            let info = model.planSummary(name)
            VStack(spacing: 8) {
                Text(model.plannedWorkout() == name ? "Gepland voor vandaag" : "Volgende training").sa(13, .semibold).foregroundColor(ac.accentText)
                Text(name).sa(52, .bold, tracking: -1.2).foregroundColor(Tokens.text)
                    .minimumScaleFactor(0.6).lineLimit(1)
                Text(info.sub).sa(15, .medium).foregroundColor(Tokens.text2)
                Text(info.muscles).sa(14).foregroundColor(Tokens.text2).multilineTextAlignment(.center)
                PrimaryButton(title: "Start \(name)", height: 64, fontSize: 19, icon: Icon.play(18)) {
                    model.ovName = name
                    model.screen = .overview
                }
                .padding(.top, 20)
                secondary("Andere training kiezen") { model.tab = .training }
                    .padding(.top, 4)
                secondary("Vrije training zonder schema") { model.askStart("") }
                secondary("Cardio starten") { model.openSheet(.add); model.cardioStart = true }
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 10) {
                Text("Nog geen schema").sa(30, .bold).foregroundColor(Tokens.text)
                Text("Kies een schema bij Training om hier je volgende training te zien.")
                    .sa(15).foregroundColor(Tokens.text2).multilineTextAlignment(.center)
                PrimaryButton(title: "Training toevoegen", height: 56, fontSize: 17) { model.newTemplate() }
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func secondary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).sa(14, .semibold).foregroundColor(Tokens.text).lineLimit(1)
                .frame(maxWidth: .infinity).frame(height: 44)
                .glassSurface(Capsule(), interactive: true, fallback: Tokens.raised)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Ready, Set, Go bij het openen van de app. Tik om over te slaan.
struct SplashOverlay: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @State private var step = 0
    private let words = ["Ready", "Set", "Go!"]

    var body: some View {
        if model.launchSplash {
            ZStack {
                Tokens.bg.ignoresSafeArea()
                AppBackground()
                VStack(spacing: 10) {
                    Text(words[step]).sa(84, .bold, tracking: -2)
                        .foregroundColor(step == 2 ? ac.accentText : Tokens.text)
                        .id(step)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                    Text("Set").sa(18, .medium).foregroundColor(Tokens.text2)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { finish() }
            .task {
                for i in 0..<3 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { step = i }
                    Haptics.light()
                    try? await Task.sleep(nanoseconds: 450_000_000)
                    if !model.launchSplash { return }
                }
                finish()
            }
            .transition(.opacity)
        }
    }

    private func finish() {
        withAnimation(.easeOut(duration: 0.25)) { model.launchSplash = false }
    }
}


