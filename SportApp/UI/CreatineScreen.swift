import SwiftUI

/// Alles over de creatine-herinnering op een eigen pagina: aan/uit, de tijden en de dagen.
struct CreatineScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac

    private let weekOrder = [2, 3, 4, 5, 6, 7, 1]
    @State private var openDay: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    model.tab = .profile
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
                    Text("Creatine").sa(30, .bold, tracking: -0.5).foregroundColor(Tokens.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(model.creaSummary).sa(15).foregroundColor(Tokens.text2).padding(.top, 4)

                    card {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Herinnering").sa(17, .semibold).foregroundColor(Tokens.text)
                                Text("Een melding om je creatine te nemen").sa(13).foregroundColor(Tokens.text2)
                            }
                            Spacer(minLength: 0)
                            SAToggle(isOn: model.crea, onColor: ac.accentLine, label: "Creatine-herinnering") {
                                model.setCreatine(!model.crea)
                            }
                        }
                        .frame(minHeight: 64)
                        if model.crea {
                            Divider().background(Tokens.line)
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tweede herinnering").sa(17, .semibold).foregroundColor(Tokens.text)
                                    Text("Alleen als je hem nog niet had").sa(13).foregroundColor(Tokens.text2)
                                }
                                Spacer(minLength: 0)
                                SAToggle(isOn: model.creaLateOn, onColor: ac.accentLine, label: "Tweede herinnering") {
                                    model.setCreaLate(on: !model.creaLateOn)
                                }
                            }
                            .frame(minHeight: 64)
                        }
                    }
                    .padding(.top, 20)

                    if model.crea {
                        sectionLabel("Standaardtijden")
                        card {
                            HStack {
                                Text("Eerste herinnering").sa(16).foregroundColor(Tokens.text)
                                Spacer(minLength: 0)
                                DatePicker("", selection: timeBinding(model.creaTime) { model.setCreaTime($0) }, displayedComponents: .hourAndMinute)
                                    .labelsHidden().environment(\.locale, Locale(identifier: "nl_NL"))
                            }
                            .frame(minHeight: 56)
                            if model.creaLateOn {
                                Divider().background(Tokens.line)
                                HStack {
                                    Text("Tweede herinnering").sa(16).foregroundColor(Tokens.text)
                                    Spacer(minLength: 0)
                                    DatePicker("", selection: timeBinding(model.creaLateTime) { model.setCreaLateTime($0) }, displayedComponents: .hourAndMinute)
                                        .labelsHidden().environment(\.locale, Locale(identifier: "nl_NL"))
                                }
                                .frame(minHeight: 56)
                            }
                        }

                        sectionLabel("Per dag")
                        card {
                            ForEach(weekOrder, id: \.self) { d in
                                dayRow(d)
                                if d != weekOrder.last { Divider().background(Tokens.line) }
                            }
                        }
                        Text("Tik op een dag voor eigen tijden.").sa(12).foregroundColor(Tokens.text3).padding(.top, 8)

                        sectionLabel("Vandaag")
                        card {
                            Button { model.toggleCreaDone() } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(model.creaDoneToday ? ac.accentLine : Color.clear)
                                        Circle().stroke(model.creaDoneToday ? ac.accentLine : Tokens.line, lineWidth: 2)
                                        if model.creaDoneToday { Icon.check(14).foregroundColor(ac.onAccent) }
                                    }
                                    .frame(width: 24, height: 24)
                                    Text(model.creaDoneToday ? "Vandaag gehad" : "Vandaag afvinken").sa(16).foregroundColor(Tokens.text)
                                    Spacer(minLength: 0)
                                }
                                .frame(minHeight: 56)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        Text("Later: koppelen aan je weekplanning, zodat je geen melding krijgt op dagen dat je een shake na het sporten neemt.")
                            .sa(12).foregroundColor(Tokens.text3).lineSpacing(3).padding(.top, 14)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(AppBackground())
    }

    private func sectionLabel(_ text: String) -> some View {
        SectionLabel(text: text).padding(.top, 24).padding(.bottom, 8)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(.horizontal, 16).padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(radius: Radius.button)
    }

    private func dayRow(_ d: Int) -> some View {
        let on = !model.creaDayOff.contains(d)
        let own = model.creaHasOwnTimes(d)
        let open = openDay == d && on
        var sub = "Geen melding"
        if on {
            sub = clockText(model.creaTime(forWeekday: d))
            if model.creaLateOn(forWeekday: d) { sub += " \u{00B7} " + clockText(model.creaLateTime(forWeekday: d)) }
        }
        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button {
                    if on { openDay = open ? nil : d }
                } label: {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(AppModel.weekdayNames[d]).sa(16).foregroundColor(on ? Tokens.text : Tokens.text3)
                            Text(sub).sa(12, .regular, mono: true).foregroundColor(own && on ? ac.accentText : Tokens.text2)
                        }
                        Spacer(minLength: 0)
                        if on { Icon.chevronRight(14).foregroundColor(Tokens.text3).rotationEffect(.degrees(open ? 90 : 0)) }
                    }
                    .frame(minHeight: 60)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                SAToggle(isOn: on, onColor: ac.accentLine, label: "Herinnering op \(AppModel.weekdayNames[d])") {
                    model.setCreaDay(d, on: !on)
                    if on && openDay == d { openDay = nil }
                }
            }
            if open {
                Divider().background(Tokens.line)
                HStack {
                    Text("Eerste herinnering").sa(15).foregroundColor(Tokens.text)
                    Spacer(minLength: 0)
                    DatePicker("", selection: timeBinding(model.creaTime(forWeekday: d)) { model.setCreaDayTime(d, minutes: $0) }, displayedComponents: .hourAndMinute)
                        .labelsHidden().environment(\.locale, Locale(identifier: "nl_NL"))
                }
                .frame(minHeight: 50)
                if model.creaLateOn {
                    if model.creaLateOn(forWeekday: d) {
                        Divider().background(Tokens.line)
                        HStack {
                            Text("Tweede herinnering").sa(15).foregroundColor(Tokens.text)
                            Spacer(minLength: 0)
                            DatePicker("", selection: timeBinding(model.creaLateTime(forWeekday: d)) { model.setCreaDayLate(d, minutes: $0) }, displayedComponents: .hourAndMinute)
                                .labelsHidden().environment(\.locale, Locale(identifier: "nl_NL"))
                        }
                        .frame(minHeight: 50)
                    }
                    Divider().background(Tokens.line)
                    HStack {
                        Text("Tweede herinnering op deze dag").sa(15).foregroundColor(Tokens.text)
                        Spacer(minLength: 0)
                        SAToggle(isOn: model.creaLateOn(forWeekday: d), onColor: ac.accentLine, label: "Tweede herinnering op \(AppModel.weekdayNames[d])") {
                            model.setCreaDayLate(d, on: !model.creaLateOn(forWeekday: d))
                        }
                    }
                    .frame(minHeight: 50)
                }
                if own {
                    Button { model.resetCreaDay(d) } label: {
                        Text("Terug naar standaard").sa(13, .semibold).foregroundColor(ac.accentText)
                            .frame(maxWidth: .infinity, minHeight: 40).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
