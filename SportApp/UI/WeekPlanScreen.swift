import SwiftUI

/// De week als kalender: per dag een training inplannen, alleen voor die dag of vast voor elke zelfde weekdag.
struct WeekPlanScreen: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    @State private var weekOffset = 0

    private var cal: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2
        return c
    }

    private var days: [Date] {
        let today = cal.startOfDay(for: Date())
        let start = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let first = cal.date(byAdding: .weekOfYear, value: weekOffset, to: start) ?? start
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: first) }
    }

    private func weekTitle(_ d: [Date]) -> String {
        if weekOffset == 0 { return "Deze week" }
        if weekOffset == 1 { return "Volgende week" }
        if weekOffset == -1 { return "Vorige week" }
        guard let f = d.first else { return "" }
        return "Week van " + DateText.short(f)
    }

    var body: some View {
        let week = days
        VStack(spacing: 0) {
            HStack {
                Button {
                    model.screen = model.cameFromSettings ? .settings : .home; model.cameFromSettings = false
                } label: {
                    HStack(spacing: 2) {
                        Icon.chevronLeft(22)
                        Text("Terug").sa(17)
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
                    Text("Weekplanning").sa(30, .bold, tracking: -0.5).foregroundColor(Tokens.text)
                        .accessibilityAddTraits(.isHeader)
                    Text("Tik op een dag om een training in te plannen. Alleen die dag, of vast voor elke zelfde weekdag.")
                        .sa(15).foregroundColor(Tokens.text2).lineSpacing(3).padding(.top, 4)

                    HStack {
                        Button { weekOffset -= 1 } label: {
                            Icon.chevronLeft(20).foregroundColor(Tokens.text).frame(width: 44, height: 44).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain).accessibilityLabel("Vorige week")
                        Spacer()
                        Text(weekTitle(week)).sa(16, .semibold).foregroundColor(Tokens.text)
                        Spacer()
                        Button { weekOffset += 1 } label: {
                            Icon.chevronRight(20).foregroundColor(Tokens.text).frame(width: 44, height: 44).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain).accessibilityLabel("Volgende week")
                    }
                    .padding(.top, 16)

                    VStack(spacing: 8) {
                        ForEach(week, id: \.self) { d in dayRow(d) }
                    }
                    .padding(.top, 4)

                    if weekOffset != 0 {
                        Button { weekOffset = 0 } label: {
                            Text("Terug naar deze week").sa(15, .semibold).foregroundColor(ac.accentText)
                                .frame(maxWidth: .infinity).frame(height: 48).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(AppBackground())
    }

    private func weekdayName(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "EEEE"
        return f.string(from: d)
    }

    private func dayRow(_ d: Date) -> some View {
        let plan = model.plan(for: d)
        let isToday = Calendar.current.isDateInToday(d)
        let done = model.history.first(where: { Calendar.current.isDate($0.date, inSameDayAs: d) })
        let dayName = weekdayName(d)
        let dayNum = Calendar.current.component(.day, from: d)
        return Menu {
            DayPlanMenuContent(date: d)
        } label: {
            HStack(spacing: 12) {
                VStack(spacing: 0) {
                    Text(String(dayName.prefix(2)).uppercased()).sa(11, .semibold).foregroundColor(isToday ? ac.onAccent : Tokens.text2)
                    Text("\(dayNum)").sa(18, .bold, mono: true).foregroundColor(isToday ? ac.onAccent : Tokens.text)
                }
                .frame(width: 48, height: 52)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(isToday ? ac.accent : Tokens.raised))
                VStack(alignment: .leading, spacing: 2) {
                    if let n = plan.name {
                        Text(n).sa(17, .semibold).foregroundColor(Tokens.text)
                        Text(plan.fixed ? "Vast elke " + dayName : "Alleen deze dag").sa(13).foregroundColor(Tokens.text2)
                    } else if plan.rest {
                        Text("Rustdag").sa(17, .semibold).foregroundColor(Tokens.text)
                        Text("Alleen deze dag").sa(13).foregroundColor(Tokens.text2)
                    } else {
                        Text("Niets gepland").sa(17).foregroundColor(Tokens.text3)
                        Text("Tik om in te plannen").sa(13).foregroundColor(Tokens.text3)
                    }
                }
                Spacer(minLength: 0)
                if let h = done {
                    HStack(spacing: 4) {
                        Icon.check(14, 2.6)
                        Text(h.name).sa(13, .semibold).lineLimit(1)
                    }
                    .foregroundColor(ac.accentText)
                    .padding(.horizontal, 10).frame(height: 30)
                    .background(Capsule().fill(ac.accentSoft))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .glassCard(radius: Radius.button)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dayName + " \(dayNum)")
    }
}


/// De keuzes om een dag in te plannen: alleen die dag, of vast voor elke zelfde weekdag.
struct DayPlanMenuContent: View {
    @EnvironmentObject private var model: AppModel
    let date: Date

    private var dayName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    var body: some View {
        let weekday = Calendar.current.component(.weekday, from: date)
        Menu("Alleen op deze dag") {
            ForEach(model.program.workouts, id: \.self) { n in
                Button(n) { model.setDayPlan(date: date, to: n) }
            }
            Button("Rustdag") { model.setDayPlan(date: date, to: "") }
            Button("Terug naar vast schema") { model.setDayPlan(date: date, to: nil) }
        }
        Menu("Vast elke " + dayName) {
            ForEach(model.program.workouts, id: \.self) { n in
                Button(n) { model.setFixedPlan(weekday: weekday, to: n) }
            }
            Button("Niets vast") { model.setFixedPlan(weekday: weekday, to: nil) }
        }
    }
}
