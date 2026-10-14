import SwiftUI

/// Liquid Glass op iOS 26 en nieuwer; op oudere iOS (zoals iOS 16 op een iPhone 8) een rustig matglas.
/// Gebruik het alleen voor zwevende lagen (tabbalk, minibalk, sheets, popups), nooit voor de inhoud zelf.
extension View {
    @ViewBuilder
    func glassSurface<S: Shape>(_ shape: S, tint: Color? = nil, interactive: Bool = false, fallback: Color = Tokens.surface) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            let base: Glass = tint.map { Glass.regular.tint($0) } ?? Glass.regular
            self.glassEffect(interactive ? base.interactive() : base, in: shape)
        } else {
            self.legacyGlass(shape, tint: tint, fallback: fallback)
        }
        #else
        self.legacyGlass(shape, tint: tint, fallback: fallback)
        #endif
    }

    fileprivate func legacyGlass<S: Shape>(_ shape: S, tint: Color?, fallback: Color) -> some View {
        self.background(
            ZStack {
                shape.fill(fallback.opacity(0.94))
                if let tint = tint { shape.fill(tint.opacity(0.35)) }
            }
        )
        .overlay(shape.stroke(Tokens.line.opacity(0.55), lineWidth: 0.5))
    }
}

/// Rustige achtergrond met een zweem accentkleur bovenin, zodat glas iets heeft om doorheen te laten schijnen.
struct AppBackground: View {
    @Environment(\.accentColors) private var ac

    var body: some View {
        ZStack {
            Tokens.bg
            LinearGradient(colors: [ac.accentSoft.opacity(0.55), Color.clear],
                           startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.42))
        }
        .ignoresSafeArea()
    }
}
