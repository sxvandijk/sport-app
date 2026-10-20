import SwiftUI

/// Radardiagram (spinnenweb): per as het aantal sets, met vorige week als stippellijn.
/// Hoe ronder de vorm, hoe evenwichtiger je traint.
struct RadarChart: View {
    let labels: [String]
    let values: [Int]
    /// Vorige week; `nil` = geen vergelijking.
    var compare: [Int]? = nil

    @Environment(\.accentColors) private var ac
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    private func normalized(_ v: [Int], top: Int) -> [Double] {
        v.map { Double($0) / Double(max(top, 1)) }
    }

    var body: some View {
        let top = max((values + (compare ?? [])).max() ?? 0, 1)
        let progress: Double = shown ? 1 : 0
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let chart = max(side - 84, 40)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                RadarGrid(axes: labels.count, rings: 4)
                    .stroke(Tokens.line, lineWidth: 1)
                    .frame(width: chart, height: chart)
                    .position(center)

                if let compare = compare {
                    RadarShape(values: normalized(compare, top: top), progress: progress)
                        .stroke(Tokens.text3, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round, dash: [4, 4]))
                        .frame(width: chart, height: chart)
                        .position(center)
                }

                RadarShape(values: normalized(values, top: top), progress: progress)
                    .fill(ac.accentSoft)
                    .frame(width: chart, height: chart)
                    .position(center)
                RadarShape(values: normalized(values, top: top), progress: progress)
                    .stroke(ac.accentLine, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
                    .frame(width: chart, height: chart)
                    .position(center)

                ForEach(labels.indices, id: \.self) { i in
                    let angle = RadarShape.angle(i, of: labels.count)
                    let r = chart / 2 + 26
                    VStack(spacing: 0) {
                        Text(labels[i]).sa(12, .semibold).foregroundColor(Tokens.text2)
                        Text("\(values.indices.contains(i) ? values[i] : 0)").sa(12, .bold, mono: true)
                            .foregroundColor(values.indices.contains(i) && values[i] > 0 ? Tokens.text : Tokens.text3)
                    }
                    .fixedSize()
                    .position(x: center.x + CGFloat(cos(angle)) * r, y: center.y + CGFloat(sin(angle)) * r)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sets per spiergroep")
        .accessibilityValue(zip(labels, values).map { "\($0.0) \($0.1)" }.joined(separator: ", "))
        .onAppear {
            guard !shown else { return }
            withAnimation(reduceMotion ? nil : Motion.reveal.delay(0.1)) { shown = true }
        }
    }
}

/// De gevulde vorm. `progress` laat hem vanuit het midden opbloeien.
struct RadarShape: Shape {
    var values: [Double]
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    static func angle(_ index: Int, of count: Int) -> Double {
        -Double.pi / 2 + Double(index) * 2 * Double.pi / Double(max(count, 1))
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !values.isEmpty else { return path }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for (i, value) in values.enumerated() {
            let a = Self.angle(i, of: values.count)
            let r = radius * CGFloat(max(value, 0.03) * progress)
            let p = CGPoint(x: center.x + CGFloat(cos(a)) * r, y: center.y + CGFloat(sin(a)) * r)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

/// Het web: ringen en spaken.
struct RadarGrid: Shape {
    let axes: Int
    let rings: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard axes > 2 else { return path }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for ring in 1...rings {
            let r = radius * CGFloat(ring) / CGFloat(rings)
            for i in 0..<axes {
                let a = RadarShape.angle(i, of: axes)
                let p = CGPoint(x: center.x + CGFloat(cos(a)) * r, y: center.y + CGFloat(sin(a)) * r)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
        for i in 0..<axes {
            let a = RadarShape.angle(i, of: axes)
            path.move(to: center)
            path.addLine(to: CGPoint(x: center.x + CGFloat(cos(a)) * radius, y: center.y + CGFloat(sin(a)) * radius))
        }
        return path
    }
}
