import SwiftUI

/// Kalender met je trainingen. Op het Training-tabblad klapt hij uit van één week naar een hele maand;
/// op het Progressie-tabblad staat altijd de hele maand. Met de pijltjes ga je naar eerdere maanden.
struct CalendarCard: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accentColors) private var ac
    let expandable: Bool
    var openKey: ReferenceWritableKeyPath<AppModel, Bool> = \.calOpen

    @State private var monthShift = 0
    @State private var selected: Date?

    private let weekdays = ["M", "D", "W", "D", "V", "Z", "Z"]
    private var cal: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2
        return c
    }

    private var isOpen: Bool { !expandable || model[keyPath: openKey] }

    // MARK: Gegevens

    private func entry(on day: Date) -> HistoryEntry? {
        model.history.first(where: { cal.isDate($0.date, inSameDayAs: day) })
    }

    private func monthStart(now: Date) -> Date {
        let first = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        return cal.date(byAdding: .month, value: monthShift, to: first) ?? first
    }

    /// Dagen van de getoonde weergave, per week (nil = lege plek buiten de maand).
    private func weeks(now: Date) -> [[Date?]] {
        let today = cal.startOfDay(for: now)
        if !isOpen {
            let dow = (cal.component(.weekday, from: today) + 5) % 7
            let monday = cal.date(byAdding: .day, value: -dow, to: today) ?? today
            return [(0..<7).map { cal.date(byAdding: .day, value: $0, to: monday) }]
        }
        let first = monthStart(now: now)
        let count = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        let lead = (cal.component(.weekday, from: first) + 5) % 7
        var cells: [Date?] = Array(repeating: nil, count: lead)
        for d in 0..<count { cells.append(cal.date(byAdding: .day, value: d, to: first)) }
        while cells.count % 7 != 0 { cells.append(nil) }
        var out: [[Date?]] = []
        var i = 0
        while i < cells.count {
            out.append(Array(cells[i..<(i + 7)]))
            i += 7
        }
        return out
    }

    // MARK: Weergave

    var body: some View {
        let now = Date()
        let today = cal.startOfDay(for: now)
        let rows = weeks(now: now)
        VStack(spacing: 0) {
            if expandable { summaryHeader(now: now, today: today) }
            if isOpen { monthNav(now: now) }

            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdays[i]).sa(11, .semibold).foregroundColor(Tokens.text3)
                        .frame(maxWidth: .infinity).padding(.bottom, 2)
                }
            }
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { c in
                        if let day = rows[r][c] {
                            dayCell(day, today: today)
                        } else {
                            Color.clear.frame(maxWidth: .infinity).frame(height: 42)
                        }
                    }
                }
            }
            if let sel = selected { Text(info(for: sel, today: today)).sa(13).foregroundColor(Tokens.text2)
                .padding(.horizontal, 8).padding(.top, 4).padding(.bottom, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .glassCard(radius: Radius.card)
    }

    private func info(for day: Date, today: Date) -> String {
        if let t = entry(on: day) { return DateText.short(day) + " \u{00B7} " + t.name + " \u{00B7} \(t.minutes) min" }
        if cal.isDate(day, inSameDayAs: today), let s = model.session { return "Vandaag \u{00B7} " + s.name + " loopt nog" }
        return DateText.short(day) + (day > today ? "" : " \u{00B7} rustdag")
    }

    private func summaryHeader(now: Date, today: Date) -> some View {
        var lastText = "Nog niet"
        let sorted = model.history.sorted { $0.date > $1.date }
        if let last = sorted.first {
            let off = model.dayOffset(last.date, now: now)
            if off == 0 {
                lastText = "Vandaag \u{00B7} " + last.name
            } else {
                lastText = DateText.short(last.date) + " \u{00B7} " + (off == 1 ? "gisteren" : "\(off) dagen geleden")
            }
        }
        let dow = (cal.component(.weekday, from: today) + 5) % 7
        let monday = cal.date(byAdding: .day, value: -dow, to: today) ?? today
        let weekCount = model.history.filter { $0.date >= monday }.count
        return Button {
            model[keyPath: openKey].toggle()
            selected = nil
            monthShift = 0
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Laatst getraind").sa(13).foregroundColor(Tokens.text2)
                    Text(lastText).sa(16, .semibold).foregroundColor(Tokens.text).lineLimit(1)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(weekCount)\u{00D7}").sa(20, .semibold, mono: true).foregroundColor(Tokens.text)
                    Text("deze week").sa(12).foregroundColor(Tokens.text2)
                }
                Icon.chevronDown(18).foregroundColor(Tokens.text2)
                    .rotationEffect(.degrees(model[keyPath: openKey] ? 180 : 0))
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(model[keyPath: openKey] ? "uitgeklapt" : "ingeklapt")
    }

    private func monthNav(now: Date) -> some View {
        let first = monthStart(now: now)
        return HStack(spacing: 0) {
            Button {
                monthShift -= 1
                selected = nil
            } label: {
                Icon.chevronLeft(20).foregroundColor(Tokens.text).frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Vorige maand")
            Text(DateText.month(first).capitalized).sa(16, .semibold).foregroundColor(Tokens.text)
                .frame(maxWidth: .infinity)
            Button {
                if monthShift < 0 { monthShift += 1 }
                selected = nil
            } label: {
                Icon.chevronRight(20).foregroundColor(Tokens.text).frame(width: 44, height: 44)
                    .opacity(monthShift < 0 ? 1 : 0.25).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Volgende maand")
        }
    }

    private func dayCell(_ day: Date, today: Date) -> some View {
        let trained = entry(on: day)
        let isToday = cal.isDate(day, inSameDayAs: today)
        let future = day > today
        let running = isToday && model.session != nil && trained == nil
        let isSelected = selected.map { cal.isDate($0, inSameDayAs: day) } ?? false

        var fill = Color.clear
        if trained != nil { fill = ac.accent }
        else if running { fill = ac.accentSoft }
        else if isSelected { fill = Tokens.raised }

        var textColor = Tokens.text2
        if trained != nil { textColor = ac.onAccent }
        else if future { textColor = Tokens.text3 }
        else if isToday { textColor = Tokens.text }

        let showRing = isToday && trained == nil
        let number = String(cal.component(.day, from: day))
        let bold = trained != nil || isToday

        return Button {
            selected = day
        } label: {
            Text(number).sa(14, bold ? .bold : .medium, mono: true)
                .foregroundColor(textColor)
                .frame(width: 32, height: 32)
                .background(Circle().fill(fill))
                .overlay(Circle().stroke(showRing ? ac.accentLine : Color.clear, lineWidth: 2))
                .frame(maxWidth: .infinity).frame(height: 42)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(DateText.short(day) + (trained.map { ", " + $0.name } ?? ""))
    }
}
