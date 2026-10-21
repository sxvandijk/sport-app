import SwiftUI
import UIKit

/// Laadt de bijgesloten oefenfoto's (rechtenvrij, zie Resources/ExerciseImages) en houdt ze in het geheugen.
enum ExerciseImageStore {
    private static let cache = NSCache<NSString, UIImage>()

    static func has(_ name: String) -> Bool { ExerciseImageMap.files[name] != nil }

    /// `frame` 0 = beginstand, 1 = eindstand.
    static func image(_ name: String, frame: Int = 0) -> UIImage? {
        guard let file = ExerciseImageMap.files[name] else { return nil }
        let key = "\(file)_\(frame)" as NSString
        if let hit = cache.object(forKey: key) { return hit }
        guard let path = Bundle.main.path(forResource: "\(file)_\(frame)", ofType: "jpg"),
              let img = UIImage(contentsOfFile: path) else { return nil }
        cache.setObject(img, forKey: key)
        return img
    }

    /// Een passend symbool voor oefeningen zonder foto (eigen oefeningen, cardio).
    static func symbol(for name: String) -> String {
        switch Catalog.info(name).muscle {
        case "Cardio": return "figure.run"
        case "Core": return "figure.core.training"
        case "Quadriceps", "Hamstrings", "Billen", "Kuiten": return "figure.step.training"
        case "Lats", "Bovenrug", "Onderrug", "Traps": return "figure.rower"
        case "Biceps", "Triceps", "Onderarmen": return "dumbbell.fill"
        default: return "figure.strengthtraining.traditional"
        }
    }
}

/// Afbeelding bij een oefening: de foto als die er is, anders een rustig vlak met een symbool.
struct ExerciseThumb: View {
    let name: String
    var size: CGFloat = 52
    var radius: CGFloat = 14
    var frame: Int = 0
    @Environment(\.accentColors) private var ac

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Group {
            if let img = ExerciseImageStore.image(name, frame: frame) {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: size, height: size)
                    .background(Color.white)
            } else {
                ZStack {
                    ac.accentSoft
                    Image(systemName: ExerciseImageStore.symbol(for: name))
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundColor(ac.accentText)
                }
                .frame(width: size, height: size)
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Tokens.line.opacity(0.6), lineWidth: 0.5))
        .accessibilityHidden(true)
    }
}

/// Grote foto die tussen begin- en eindstand wisselt (voor de uitleg).
struct ExerciseHero: View {
    let name: String
    var height: CGFloat = 220
    @State private var frame = 0
    private let timer = Timer.publish(every: 1.1, on: .main, in: .common).autoconnect()

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
        Group {
            if let img = ExerciseImageStore.image(name, frame: frame) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(maxWidth: .infinity).frame(height: height).clipped()
                    .background(Color.white)
            } else {
                ExerciseThumb(name: name, size: height * 0.5, radius: Radius.card)
                    .frame(maxWidth: .infinity).frame(height: height)
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Tokens.line.opacity(0.6), lineWidth: 0.5))
        .onReceive(timer) { _ in
            guard ExerciseImageStore.has(name) else { return }
            withAnimation(.easeInOut(duration: 0.3)) { frame = frame == 0 ? 1 : 0 }
        }
        .accessibilityHidden(true)
    }
}
