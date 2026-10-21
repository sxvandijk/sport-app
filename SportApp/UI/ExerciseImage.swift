import SwiftUI
import UIKit

/// Laadt de oefenafbeeldingen en houdt ze in het geheugen.
/// Voorrang: eigen illustraties (Resources/ExerciseArt, `art-<slug>_0/1.jpg`, gemaakt met tools/import_art.py),
/// daarna de rechtenvrije foto's (Resources/ExerciseImages).
enum ExerciseImageStore {
    private static let cache = NSCache<NSString, UIImage>()

    /// Bestandsnaam-slug: kleine letters, alles buiten a-z/0-9 wordt een streepje ("Incline Dumbbell Press" -> "incline-dumbbell-press").
    static func slug(_ name: String) -> String {
        var out = ""
        var lastDash = true
        for ch in name.lowercased() {
            if ch.isASCII, ch.isLetter || ch.isNumber { out.append(ch); lastDash = false }
            else if !lastDash { out.append("-"); lastDash = true }
        }
        if out.hasSuffix("-") { out.removeLast() }
        return out
    }

    private static func artPath(_ name: String, frame: Int) -> String? {
        Bundle.main.path(forResource: "art-\(slug(name))_\(frame)", ofType: "jpg")
    }

    /// Is dit een eigen illustratie (vierkant, volledige figuur) in plaats van een foto?
    static func isArt(_ name: String) -> Bool { artPath(name, frame: 0) != nil }

    static func has(_ name: String) -> Bool { isArt(name) || ExerciseImageMap.files[name] != nil }

    /// `frame` 0 = beginstand, 1 = eindstand.
    static func image(_ name: String, frame: Int = 0) -> UIImage? {
        let key = "\(name)_\(frame)" as NSString
        if let hit = cache.object(forKey: key) { return hit }
        var path = artPath(name, frame: frame)
        if path == nil, let file = ExerciseImageMap.files[name] {
            path = Bundle.main.path(forResource: "\(file)_\(frame)", ofType: "jpg")
        }
        guard let path, let img = UIImage(contentsOfFile: path) else { return nil }
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
                Image(uiImage: img).resizable()
                    .aspectRatio(contentMode: ExerciseImageStore.isArt(name) ? .fit : .fill)
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
