import SwiftUI

/// Herinnering van één supplement (omega 3, magnesium, eigen supplementen): aan of uit en de tijd.
struct SupplementScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    private var supplement: Supplement? { model.supplement(model.supplementEditID) }

    private func timeBinding(_ s: Supplement) -> Binding<Date> {
        Binding(
            get: { Calendar.current.date(byAdding: .minute, value: s.time, to: Calendar.current.startOfDay(for: Date())) ?? Date() },
            set: { d in
                let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                model.setSupplementTime(s.id, minutes: (c.hour ?? 9) * 60 + (c.minute ?? 0))
            })
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    model.screen = .home
                } label: {
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
                if let s = supplement {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(s.name).sa(30, .bold, tracking: -0.5).foregroundColor(Tokens.text)
                            .accessibilityAddTraits(.isHeader)
                        Text(model.supplementSummary(s)).sa(15).foregroundColor(Tokens.text2).padding(.top, 4)

                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Herinnering").sa(17, .semibold).foregroundColor(Tokens.text)
                                    Text("Elke dag een melding, met een knop \"Gehad\"").sa(13).foregroundColor(Tokens.text2)
                                }
                                Spacer(minLength: 0)
                                SAToggle(isOn: s.on, onColor: ac.accentLine, label: "\(s.name)-herinnering") {
                                    model.setSupplement(s.id, on: !s.on)
                                }
                            }
                            .frame(minHeight: 64)
                            if s.on {
                                Divider().background(Tokens.line)
                                HStack {
                                    Text("Tijd").sa(17, .semibold).foregroundColor(Tokens.text)
                                    Spacer(minLength: 0)
                                    DatePicker("Tijd", selection: timeBinding(s), displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                                .frame(minHeight: 60)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 4)
                        .glassCard(radius: Radius.button)
                        .padding(.top, 20)

                        Button {
                            model.confirm = ConfirmRequest(title: "\(s.name) verwijderen?", message: "De herinnering stopt en je afgevinkte dagen verdwijnen.", confirmTitle: "Verwijder") {
                                model.deleteSupplement(s.id)
                                model.screen = .home
                            }
                        } label: {
                            Text("Supplement verwijderen").sa(16, .semibold).foregroundColor(Tokens.danger)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 40)
                }
            }
        }
        .background(AppBackground())
    }
}
