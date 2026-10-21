import SwiftUI

/// Alle animaties op één plek, zodat de app overal hetzelfde aanvoelt (DESIGN.md 4.1).
/// Vuistregel: iets wat je aanraakt veert (spring), iets wat verschijnt glijdt uit (easeOut).
enum Motion {
    /// Knop indrukken.
    static let press = Animation.spring(response: 0.22, dampingFraction: 0.7)
    /// Tabs die opschuiven als Voeding aan of uit gaat.
    static let tabReflow = Animation.spring(response: 0.42, dampingFraction: 0.86)
    /// Kort "plopje": tabicoon, vinkje, PR-badge.
    static let pop = Animation.spring(response: 0.28, dampingFraction: 0.55)
    /// Oefeningkaarten die openen en sluiten tijdens een workout.
    static let card = Animation.spring(response: 0.46, dampingFraction: 0.88)
    /// Wisselen van tab-inhoud.
    static let tabContent = Animation.easeOut(duration: 0.22)
    /// Ringen, balken en het radardiagram die zich vullen bij openen.
    static let reveal = Animation.easeOut(duration: 0.7)

    /// Balken één voor één laten groeien.
    static func stagger(_ index: Int) -> Animation {
        reveal.delay(Double(index) * 0.05)
    }
}

/// Knop die iets indeukt bij aanraken. Voor kaarten, chips en grote knoppen.
struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

extension View {
    /// Cijfers rollen naar hun nieuwe waarde. Werkt binnen een animatie (`withAnimation`).
    func rollingNumber() -> some View {
        contentTransition(.numericText())
    }
}
