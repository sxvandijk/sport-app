import SwiftUI

/// Alle vaste maten uit DESIGN.md hoofdstuk 4. Gebruik nooit losse getallen in een scherm.
enum Radius {
    static let badge: CGFloat = 8
    static let field: CGFloat = 14        // setrij, invoerveld, stepper in de schema-editor
    static let row: CGFloat = 16          // +/−-balk in de dock, rij in een sheet
    static let button: CGFloat = 18       // hoofdknop, schemablok, rij met een training
    static let card: CGFloat = 24         // open oefening, kalenderblok, minibalk
    static let sheetTop: CGFloat = 24     // bovenkant van de dock en van een sheet
    // Chips, Hervat en Wissel zijn pillen: gebruik `Capsule()`.
}

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    static let screenMargin: CGFloat = 20
    static let blockInset: CGFloat = 16
    static let sectionGap: CGFloat = 24
    static let rowGap: CGFloat = 8
}

enum Size {
    static let primaryButton: CGFloat = 52        // 52–56
    static let primaryButtonLarge: CGFloat = 56
    static let stepperBar: CGFloat = 52
    static let stepperButtonWidth: CGFloat = 48
    static let setRow: CGFloat = 48
    static let chip: CGFloat = 44
    static let minTouch: CGFloat = 44
    static let miniBar: CGFloat = 68
    static let progressLine: CGFloat = 3
    static let restBar: CGFloat = 56
}

/// De vaste kleuren staan in de Asset Catalog (Color Sets met een donkere en een lichte variant).
enum Tokens {
    static let bg = Color("bg")
    static let surface = Color("surface")
    static let raised = Color("raised")
    static let line = Color("line")
    static let track = Color("track")
    static let text = Color("text")
    static let text2 = Color("text2")
    static let text3 = Color("text3")
    static let warm = Color("warm")
    /// Blauw voor het cooling-downblok (oranje `warm` is voor warming-up).
    static let cool = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.42, green: 0.66, blue: 1.0, alpha: 1) : UIColor(red: 0.10, green: 0.41, blue: 0.86, alpha: 1)
    })
    static let drop = Color("drop")
    static let danger = Color("danger")
    static let onDanger = Color("onDanger")
    static let inverse = Color("inverse")
    static let onInverse = Color("onInverse")
    static let scrim = Color("scrim")
}

/// De afgeleide accentkleuren als SwiftUI-kleuren.
struct AccentColors: Equatable {
    var accent: Color
    var onAccent: Color
    var accentText: Color
    var accentLine: Color
    var accentSoft: Color

    init(_ palette: AccentPalette) {
        func color(_ c: RGB, opacity: Double = 1) -> Color {
            Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: opacity)
        }
        accent = color(palette.accent)
        onAccent = color(palette.onAccent)
        accentText = color(palette.accentText)
        accentLine = color(palette.accentLine)
        accentSoft = color(palette.accentSoft, opacity: palette.accentSoftAlpha)
    }

    static func make(accent id: AccentID, scheme: ColorScheme) -> AccentColors {
        AccentColors(AccentPalette.make(accent: id, isDarkMode: scheme == .dark))
    }
}

private struct AccentColorsKey: EnvironmentKey {
    static let defaultValue = AccentColors.make(accent: .olive, scheme: .dark)
}

extension EnvironmentValues {
    /// De accentkleuren voor het gekozen accent en de huidige modus. Gebruik `@Environment(\.accentColors)`.
    var accentColors: AccentColors {
        get { self[AccentColorsKey.self] }
        set { self[AccentColorsKey.self] = newValue }
    }
}

extension View {
    /// Een vlak met afgeronde hoeken (altijd `.continuous`).
    /// Standaardvlak van de app: Liquid Glass op iOS 26, rustig matglas op oudere iOS.
    func glassCard(radius: CGFloat) -> some View {
        glassSurface(RoundedRectangle(cornerRadius: radius, style: .continuous), fallback: Tokens.surface)
    }

    /// Zelfde als glassCard maar voor lichtere vlakken binnen een blad.
    func glassRaised(radius: CGFloat) -> some View {
        glassSurface(RoundedRectangle(cornerRadius: radius, style: .continuous), fallback: Tokens.raised)
    }

    func card(_ fill: Color, radius: CGFloat) -> some View {
        background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
    }
}
