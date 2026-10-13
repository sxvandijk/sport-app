import SwiftUI

// MARK: - Tekst

private struct SAFont: ViewModifier {
    @ScaledMetric private var scaled: CGFloat
    let weight: Font.Weight
    let tracking: CGFloat
    let mono: Bool

    init(size: CGFloat, weight: Font.Weight, tracking: CGFloat, mono: Bool) {
        _scaled = ScaledMetric(wrappedValue: size, relativeTo: .body)
        self.weight = weight
        self.tracking = tracking
        self.mono = mono
    }

    func body(content: Content) -> some View {
        let base = Font.system(size: scaled, weight: weight)
        return content.font(mono ? base.monospacedDigit() : base).kerning(tracking)
    }
}

extension View {
    /// Tekststijl uit het prototype: grootte in punten, gewicht, letterafstand en vaste cijferbreedte.
    func sa(_ size: CGFloat, _ weight: Font.Weight = .regular, tracking: CGFloat = 0, mono: Bool = false) -> some View {
        modifier(SAFont(size: size, weight: weight, tracking: tracking, mono: mono))
    }
}

/// Kleine kop in hoofdletters ("MIJN SCHEMA").
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .sa(12, .semibold, tracking: 0.72)
            .foregroundColor(Tokens.text2)
    }
}

// MARK: - Vormen

/// Rechthoek met alleen bovenste hoeken rond (dock, sheet).
struct TopRounded: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Schakelaar zoals in het prototype (51 × 31)

struct SAToggle: View {
    let isOn: Bool
    var onColor: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                Capsule().fill(isOn ? onColor : Tokens.line).frame(width: 51, height: 31)
                Circle().fill(Color.white).frame(width: 27, height: 27)
                    .padding(.leading, 2)
                    .offset(x: isOn ? 20 : 0)
            }
            .frame(width: 51, height: 44)
            .animation(.easeOut(duration: 0.2), value: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "aan" : "uit")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Knoppen

struct PrimaryButton: View {
    let title: String
    var height: CGFloat = 52
    var fontSize: CGFloat = 17
    var icon: Icon?
    var enabled = true
    let action: () -> Void
    @Environment(\.accentColors) private var ac

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon { icon }
                Text(title).sa(fontSize, .bold)
            }
            .foregroundColor(ac.onAccent)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .card(ac.accent, radius: Radius.button)
            .opacity(enabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// Rij in een sheet: lichte achtergrond, afgerond.
struct SheetRowButton<Content: View>: View {
    let action: () -> Void
    @ViewBuilder var content: () -> Content
    var body: some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .card(Tokens.raised, radius: Radius.row)
        }
        .buttonStyle(.plain)
    }
}

/// Ronde kleine knop met een pictogram (44 × 44 aanraakvlak).
struct IconButton: View {
    let icon: Icon
    let label: String
    var color: Color = Tokens.text
    var width: CGFloat = 44
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            icon.foregroundColor(color).frame(width: width, height: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Eén regel uit het prototype met naam en subregel (links) en iets aan de rechterkant.
struct TitleSub: View {
    let title: String
    let sub: String
    var titleSize: CGFloat = 17
    var titleWeight: Font.Weight = .semibold
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).sa(titleSize, titleWeight).foregroundColor(Tokens.text).lineLimit(1)
            Text(sub).sa(13).foregroundColor(Tokens.text2).lineLimit(2)
        }
    }
}

// MARK: - Datum

enum DateText {
    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = format
        return f
    }

    /// "dinsdag 13 oktober"
    static func long(_ date: Date) -> String { formatter("EEEE d MMMM").string(from: date) }

    /// "oktober 2026"
    static func month(_ date: Date) -> String { formatter("LLLL yyyy").string(from: date) }

    /// "di 13 okt"
    static func short(_ date: Date) -> String {
        formatter("EEE d MMM").string(from: date).replacingOccurrences(of: ".", with: "")
    }
}
