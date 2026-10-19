import SwiftUI

enum ProfileSub: String { case training, notifications, personal }

/// Rij in Profiel die naar een subscherm met instellingen gaat.
struct SettingsLink: View {
    @EnvironmentObject private var model: AppModel
    let title: String
    let sub: String
    let page: ProfileSub

    var body: some View {
        Button {
            model.profileSub = page
            model.screen = .settings
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).sa(16, .medium).foregroundColor(Tokens.text)
                    Text(sub).sa(13).foregroundColor(Tokens.text2).lineLimit(2)
                }
                Spacer(minLength: 0)
                Icon.chevronRight(16).foregroundColor(Tokens.text3)
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Subscherm van Profiel: Training, Meldingen of Persoonlijk.
struct SettingsScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    private var title: String {
        switch model.profileSub {
        case .training: return "Training"
        case .notifications: return "Meldingen"
        case .personal: return "Persoonlijk"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    model.screen = .home
                } label: {
                    HStack(spacing: 2) {
                        Icon.chevronLeft(22)
                        Text("Profiel").sa(17)
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
                    Text(title).sa(30, .bold, tracking: -0.5).foregroundColor(Tokens.text)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.bottom, 16)
                    switch model.profileSub {
                    case .training: trainingPage
                    case .notifications: notificationsPage
                    case .personal: personalPage
                    }
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var trainingPage: some View {
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
                Button { model.cameFromSettings = true; model.screen = .weekPlan } label: {
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
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
        .glassCard(radius: Radius.button)
    }

    private var notificationsPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
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
            CreatineRow().padding(.top, 10)
        }
    }

    private var personalPage: some View {
        Text("Hier komen later kg of lb, gegevens exporteren en een back-up.")
            .sa(15).foregroundColor(Tokens.text2).lineSpacing(3)
    }
}
