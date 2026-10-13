import SwiftUI

/// Tijdelijk scherm voor elke tab (fase 2). Toont de ontwerptokens zodat kleuren en lettertypen
/// in de simulator en op de CI-screenshots te controleren zijn. Wordt per tab vervangen in fase 3 t/m 5.
struct PlaceholderScreen: View {
    let tab: AppTab

    private var phaseText: String {
        switch tab {
        case .training: return "Komt in fase 3"
        case .progress: return "Komt in fase 5"
        case .gym, .profile: return "Komt in fase 4"
        }
    }

    var body: some View {
        ZStack {
            Tokens.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        SAText(phaseText, .sub).foregroundColor(Tokens.text2)
                        SAText(tab.title, .largeTitle).foregroundColor(Tokens.text)
                    }

                    TokenPreview()
                }
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.top, Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Een klein voorbeeldblok met de belangrijkste ontwerpelementen.
private struct TokenPreview: View {
    @Environment(\.accentColors) private var accent

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SAText("Mijn schema", .sectionLabel).foregroundColor(Tokens.text2)
            SAText("Push Pull Legs", .scheduleTitle).foregroundColor(Tokens.text)

            HStack(spacing: Spacing.xs) {
                Pill(text: "Volgende", fill: accent.accentSoft, foreground: accent.accentText)
                Pill(text: "Wissel", fill: Tokens.raised, foreground: Tokens.text)
            }

            VStack(spacing: Spacing.rowGap) {
                SetRow(label: "W", labelColor: Tokens.warm, kg: "35", reps: "12", status: "✓", highlighted: false)
                SetRow(label: "1", labelColor: Tokens.text2, kg: "55", reps: "10", status: "✓", highlighted: false)
                SetRow(label: "2", labelColor: accent.accentText, kg: "55", reps: "10", status: "NU", highlighted: true)
                SetRow(label: "D", labelColor: Tokens.drop, kg: "45", reps: "8", status: "", highlighted: false)
                SetRow(label: "F", labelColor: Tokens.danger, kg: "55", reps: "6", status: "", highlighted: false)
            }

            HStack {
                SAText("23:14", .topTimer).foregroundColor(Tokens.text)
                Spacer()
                SAText("1:24", .restTimer).foregroundColor(accent.accentText)
            }

            SAText("Set klaar", .button)
                .foregroundColor(accent.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: Size.primaryButton)
                .card(accent.accent, radius: Radius.button)
        }
        .padding(Spacing.blockInset)
        .card(Tokens.surface, radius: Radius.card)
    }
}

private struct Pill: View {
    let text: String
    let fill: Color
    let foreground: Color

    var body: some View {
        SAText(text, .sub)
            .foregroundColor(foreground)
            .padding(.horizontal, Spacing.s)
            .frame(minHeight: Size.chip)
            .background(Capsule().fill(fill))
    }
}

private struct SetRow: View {
    let label: String
    let labelColor: Color
    let kg: String
    let reps: String
    let status: String
    let highlighted: Bool

    var body: some View {
        HStack(spacing: Spacing.s) {
            SAText(label, .body).foregroundColor(labelColor).frame(width: 32, alignment: .leading)
            SAText(kg + " kg", .dockValue).foregroundColor(Tokens.text).frame(maxWidth: .infinity, alignment: .leading)
            SAText(reps + " reps", .dockValue).foregroundColor(Tokens.text).frame(maxWidth: .infinity, alignment: .leading)
            SAText(status, .sub).foregroundColor(Tokens.text2).frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.s)
        .frame(height: Size.setRow)
        .card(highlighted ? Tokens.raised : Color.clear, radius: Radius.field)
    }
}
