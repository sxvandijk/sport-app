import SwiftUI

/// De tekststijlen uit DESIGN.md hoofdstuk 3. De letter is SF Pro (systeemletter), getallen hebben vaste cijferbreedte.
enum SATextStyle {
    case largeTitle, screenTitle, scheduleTitle, exerciseOpen, topTimer, dockValue, restTimer
    case button, body, sub, sectionLabel, tabLabel

    var size: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .screenTitle: return 28
        case .scheduleTitle, .exerciseOpen, .topTimer, .restTimer: return 22
        case .dockValue: return 26
        case .button, .body: return 17
        case .sub: return 13
        case .sectionLabel: return 12
        case .tabLabel: return 11
        }
    }

    var weight: Font.Weight {
        switch self {
        case .largeTitle, .screenTitle, .scheduleTitle, .button: return .bold
        case .exerciseOpen, .topTimer, .dockValue, .restTimer, .sectionLabel, .tabLabel: return .semibold
        case .body: return .medium
        case .sub: return .regular
        }
    }

    /// Letterafstand in punten.
    var tracking: CGFloat {
        switch self {
        case .largeTitle: return -0.6
        case .screenTitle: return -0.4
        case .scheduleTitle, .exerciseOpen, .topTimer: return -0.3
        case .dockValue: return -0.5
        case .sectionLabel: return 0.72     // +0,06 em bij 12 pt
        default: return 0
        }
    }

    var usesFixedDigitWidth: Bool {
        switch self {
        case .topTimer, .dockValue, .restTimer: return true
        default: return false
        }
    }

    var isUppercase: Bool { self == .sectionLabel }

    /// Waarmee de grootte meeschaalt bij Dynamic Type.
    var relativeTo: Font.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .screenTitle: return .title
        case .scheduleTitle, .exerciseOpen, .topTimer, .restTimer, .dockValue: return .title2
        case .button, .body: return .body
        case .sub: return .footnote
        case .sectionLabel, .tabLabel: return .caption
        }
    }
}

/// Tekst in een vaste stijl. Voorbeeld: `SAText("Training", .largeTitle).foregroundColor(Tokens.text)`.
struct SAText: View {
    private let text: String
    private let style: SATextStyle
    @ScaledMetric private var size: CGFloat

    init(_ text: String, _ style: SATextStyle) {
        self.text = text
        self.style = style
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.relativeTo)
    }

    var body: some View {
        let base = Text(style.isUppercase ? text.uppercased() : text)
            .font(.system(size: size, weight: style.weight))
            .kerning(style.tracking)
        return style.usesFixedDigitWidth ? base.monospacedDigit() : base
    }
}

/// Getallen en datums volgens DESIGN.md hoofdstuk 3: komma als decimaalteken, punt bij duizendtallen.
enum SAFormat {
    private static let locale = Locale(identifier: "nl_NL")

    static func number(_ value: Double, maxFractionDigits: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// "55 kg", "7,5 kg", "48.230 kg"
    static func kilograms(_ value: Double) -> String {
        number(value) + " kg"
    }

    /// 84 → "1:24"
    static func clock(seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
