import Foundation

/// Een kleur als losse waarden (0...1). Bewust geen SwiftUI, zodat de afleidingsregels uit DESIGN.md 2.1 getest kunnen worden.
struct RGB: Equatable {
    var r: Double
    var g: Double
    var b: Double

    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    init(hex: UInt32) {
        self.r = Double((hex >> 16) & 0xFF) / 255
        self.g = Double((hex >> 8) & 0xFF) / 255
        self.b = Double(hex & 0xFF) / 255
    }

    static let black = RGB(hex: 0x000000)
    static let white = RGB(hex: 0xFFFFFF)

    /// Relatieve luminantie volgens WCAG 2.x.
    var luminance: Double {
        func linear(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    /// Contrastverhouding met een andere kleur (1...21).
    func contrast(with other: RGB) -> Double {
        let a = max(luminance, other.luminance)
        let b = min(luminance, other.luminance)
        return (a + 0.05) / (b + 0.05)
    }

    /// Meng deze kleur met `target`. `fraction` 0.55 = 55 % naar `target`.
    func mixed(toward target: RGB, fraction: Double) -> RGB {
        RGB(r: r + (target.r - r) * fraction,
            g: g + (target.g - g) * fraction,
            b: b + (target.b - b) * fraction)
    }
}

/// De vijf accenttokens, afgeleid uit de gekozen accentkleur (DESIGN.md 2.1).
struct AccentPalette: Equatable {
    var accent: RGB
    var onAccent: RGB
    var accentText: RGB
    var accentLine: RGB
    var accentSoft: RGB
    /// Doorzichtigheid van `accentSoft` (0...1).
    var accentSoftAlpha: Double

    /// Een accentkleur telt als donker bij een relatieve luminantie onder 0,3.
    static let darkThreshold = 0.3

    private static let onLightAccentDarkMode = RGB(hex: 0x0D0E10)
    private static let onLightAccentLightMode = RGB(hex: 0x121316)

    static func make(accent id: AccentID, isDarkMode: Bool) -> AccentPalette {
        make(accent: RGB(hex: id.hex), isDarkMode: isDarkMode)
    }

    static func make(accent a: RGB, isDarkMode: Bool) -> AccentPalette {
        let isDarkAccent = a.luminance < darkThreshold

        switch (isDarkAccent, isDarkMode) {
        case (false, true):
            return AccentPalette(accent: a, onAccent: onLightAccentDarkMode, accentText: a,
                                 accentLine: a, accentSoft: a, accentSoftAlpha: 0.18)
        case (false, false):
            return AccentPalette(accent: a, onAccent: onLightAccentLightMode,
                                 accentText: a.mixed(toward: .black, fraction: 0.55),
                                 accentLine: a.mixed(toward: .black, fraction: 0.30),
                                 accentSoft: a, accentSoftAlpha: 0.45)
        case (true, true):
            return AccentPalette(accent: a, onAccent: .white,
                                 accentText: a.mixed(toward: .white, fraction: 0.55),
                                 accentLine: a.mixed(toward: .white, fraction: 0.35),
                                 accentSoft: a, accentSoftAlpha: 0.40)
        case (true, false):
            return AccentPalette(accent: a, onAccent: .white, accentText: a,
                                 accentLine: a, accentSoft: a, accentSoftAlpha: 0.22)
        }
    }
}
