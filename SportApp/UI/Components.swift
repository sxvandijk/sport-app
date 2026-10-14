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

// MARK: - Supersets

/// Elke superset krijgt zijn eigen kleur, zodat je ze uit elkaar houdt.
enum SupersetStyle {
    static let hues: [Color] = [
        Color(.sRGB, red: 0.30, green: 0.55, blue: 1.00, opacity: 1),
        Color(.sRGB, red: 1.00, green: 0.62, blue: 0.26, opacity: 1),
        Color(.sRGB, red: 1.00, green: 0.45, blue: 0.66, opacity: 1),
        Color(.sRGB, red: 0.22, green: 0.78, blue: 0.68, opacity: 1),
        Color(.sRGB, red: 0.70, green: 0.55, blue: 1.00, opacity: 1)
    ]

    static func color(_ index: Int) -> Color { hues[((index % hues.count) + hues.count) % hues.count] }
}

/// Een blok om oefeningen die samen een superset zijn.
struct SupersetFrame<Content: View>: View {
    let index: Int
    let count: Int
    let content: Content

    init(index: Int, count: Int, @ViewBuilder content: () -> Content) {
        self.index = index
        self.count = count
        self.content = content()
    }

    var body: some View {
        let hue = SupersetStyle.color(index)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Icon.link(14, 2.4)
                Text("SUPERSET \(index + 1) \u{00B7} \(count) OEFENINGEN").sa(11, .bold, tracking: 0.66)
            }
            .foregroundColor(hue.opacity(0.75))
            .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 2)
            content
        }
        .padding(.bottom, 6)
        .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(hue.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).stroke(hue.opacity(0.28), lineWidth: 1))
        .padding(.vertical, 6)
    }
}

/// Rond nummer voor een oefening; in een superset in de kleur van die superset.
struct NumberBadge: View {
    let text: String
    var hue: Color?
    var size: CGFloat = 32

    var body: some View {
        Text(text).sa(12, .bold).foregroundColor(hue == nil ? Tokens.text2 : Color.black.opacity(0.85))
            .frame(width: size, height: size)
            .background(Circle().fill(hue ?? Tokens.raised))
    }
}


// MARK: - Verslepen (vasthouden en slepen)

struct ReorderFramesKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// Houdt bij welke rij wordt versleept en waar alle rijen staan.
/// Frames zijn de LAYOUT-posities (zonder sleep-offset), zodat er geen terugkoppeling ontstaat.
final class ReorderCoordinator: ObservableObject {
    @Published var active: UUID?
    @Published var translation: CGFloat = 0
    var frames: [UUID: CGRect] = [:]
    private var startMid: CGFloat = 0
    private var awaiting = false
    private var awaitFrom: CGFloat = 0

    func setFrames(_ new: [UUID: CGRect]) {
        frames = new
        guard let id = active else { return }
        if awaiting, let f = new[id], abs(f.midY - awaitFrom) > 0.5 { awaiting = false }
        objectWillChange.send()
    }

    func begin(_ id: UUID) {
        active = id
        startMid = frames[id]?.midY ?? 0
        translation = 0
        awaiting = false
        Haptics.light()
    }

    func update(_ t: CGFloat, move: (UUID) -> Void) {
        guard let id = active else { return }
        translation = t
        guard !awaiting, let me = frames[id] else { return }
        let visual = startMid + t
        var best: (UUID, CGFloat)?
        for (key, f) in frames where key != id {
            let crossed = (f.midY < me.midY && visual < f.midY) || (f.midY > me.midY && visual > f.midY)
            guard crossed else { continue }
            let dist = abs(f.midY - me.midY)
            if best == nil || dist < best!.1 { best = (key, dist) }
        }
        guard let target = best?.0 else { return }
        awaiting = true
        awaitFrom = me.midY
        move(target)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.awaiting = false }
    }

    func end() {
        guard active != nil else { return }
        active = nil
        translation = 0
        awaiting = false
    }

    /// Hoeveel de versleepte rij moet meeschuiven om onder je vinger te blijven.
    func offset(for id: UUID) -> CGFloat {
        guard active == id, let f = frames[id] else { return 0 }
        return startMid + translation - f.midY
    }
}

struct ReorderRow: ViewModifier {
    @Environment(\.accentColors) private var ac
    let id: UUID
    @ObservedObject var coord: ReorderCoordinator

    func body(content: Content) -> some View {
        let lifted = coord.active == id
        return ZStack {
            content
                .background(
                    RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                        .fill(lifted ? Tokens.surface : Color.clear)
                        .padding(.horizontal, lifted ? -10 : 0)
                        .padding(.vertical, lifted ? -4 : 0)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                        .stroke(ac.accentLine, lineWidth: lifted ? 2 : 0)
                        .padding(.horizontal, lifted ? -10 : 0)
                        .padding(.vertical, lifted ? -4 : 0)
                )
                .offset(y: coord.offset(for: id))
                .scaleEffect(lifted ? 1.02 : 1)
                .shadow(color: Color.black.opacity(lifted ? 0.35 : 0), radius: 12, y: 4)
        }
        .background(GeometryReader { g in
            Color.clear.preference(key: ReorderFramesKey.self, value: [id: g.frame(in: .named("reorder"))])
        })
        .zIndex(lifted ? 1 : 0)
    }
}

struct ReorderGesture: ViewModifier {
    let id: UUID
    @ObservedObject var coord: ReorderCoordinator
    let move: (UUID) -> Void
    @GestureState private var live = false

    func body(content: Content) -> some View {
        content
            .gesture(
                LongPressGesture(minimumDuration: 0.3)
                    .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("reorder")))
                    .updating($live) { value, state, _ in
                        if case .second(true, _) = value { state = true }
                    }
                    .onChanged { value in
                        if case .second(true, let drag) = value {
                            if coord.active == nil { coord.begin(id) }
                            if let d = drag { coord.update(d.translation.height, move: move) }
                        }
                    }
            )
            .onChange(of: live) { isLive in
                if !isLive { coord.end() }
            }
    }
}

extension View {
    /// Meet de rij en laat hem meebewegen tijdens het slepen.
    func reorderRow(_ id: UUID, _ coord: ReorderCoordinator) -> some View {
        modifier(ReorderRow(id: id, coord: coord))
    }

    /// Vasthouden (kort) en dan slepen.
    func reorderGesture(_ id: UUID, _ coord: ReorderCoordinator, move: @escaping (UUID) -> Void) -> some View {
        modifier(ReorderGesture(id: id, coord: coord, move: move))
    }
}


// MARK: - Eigen bevestigingsvenster

struct ConfirmOverlay: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        if let c = model.confirm {
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()
                    .onTapGesture { model.confirm = nil }
                VStack(spacing: 0) {
                    Text(c.title).sa(19, .bold).foregroundColor(Tokens.text).multilineTextAlignment(.center)
                    if !c.message.isEmpty {
                        Text(c.message).sa(14).foregroundColor(Tokens.text2).multilineTextAlignment(.center)
                            .lineLimit(4).padding(.top, 8)
                    }
                    Button {
                        let action = c.action
                        model.confirm = nil
                        action()
                    } label: {
                        Text(c.confirmTitle).sa(17, .bold).foregroundColor(Tokens.onDanger)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .card(Tokens.danger, radius: Radius.button)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                    Button { model.confirm = nil } label: {
                        Text("Annuleer").sa(17, .semibold).foregroundColor(Tokens.text)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .card(Tokens.raised, radius: Radius.button)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(22)
                .frame(maxWidth: 340)
                .card(Tokens.surface, radius: Radius.card)
                .padding(.horizontal, 24)
            }
            .transition(.opacity)
        }
    }
}
