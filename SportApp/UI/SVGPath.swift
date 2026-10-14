import SwiftUI

/// Leest een SVG-pad (`d="M6 9l6 6 6-6"`) en maakt er een SwiftUI-`Path` van, op een tekengrootte van 24 × 24.
/// Zo zijn de pictogrammen precies dezelfde als in het prototype. Ondersteund: M m L l H h V v C c A a Z z.
enum SVGPath {
    static func parse(_ d: String) -> Path {
        var scanner = Scanner(d)
        var path = Path()
        var current = CGPoint.zero
        var start = CGPoint.zero
        var command: Character = "M"
        var lastControl: CGPoint?

        while let next = scanner.nextCommandOrNumber() {
            if case .command(let c) = next {
                command = c
                if c == "Z" || c == "z" {
                    path.closeSubpath()
                    current = start
                    continue
                }
            } else if case .number = next {
                scanner.pushBack(next)
            }
            let relative = command.isLowercase
            let previousControl = lastControl
            lastControl = nil
            switch command {
            case "M", "m":
                guard let x = scanner.number(), let y = scanner.number() else { return path }
                let p = relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
                path.move(to: p)
                current = p
                start = p
                command = relative ? "l" : "L"
            case "L", "l":
                guard let x = scanner.number(), let y = scanner.number() else { return path }
                let p = relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
                path.addLine(to: p)
                current = p
            case "H", "h":
                guard let x = scanner.number() else { return path }
                let p = CGPoint(x: relative ? current.x + x : x, y: current.y)
                path.addLine(to: p)
                current = p
            case "V", "v":
                guard let y = scanner.number() else { return path }
                let p = CGPoint(x: current.x, y: relative ? current.y + y : y)
                path.addLine(to: p)
                current = p
            case "C", "c":
                guard let x1 = scanner.number(), let y1 = scanner.number(),
                      let x2 = scanner.number(), let y2 = scanner.number(),
                      let x = scanner.number(), let y = scanner.number() else { return path }
                let o = relative ? current : .zero
                let end = CGPoint(x: o.x + x, y: o.y + y)
                path.addCurve(to: end,
                              control1: CGPoint(x: o.x + x1, y: o.y + y1),
                              control2: CGPoint(x: o.x + x2, y: o.y + y2))
                lastControl = CGPoint(x: o.x + x2, y: o.y + y2)
                current = end
            case "S", "s":
                guard let x2 = scanner.number(), let y2 = scanner.number(),
                      let x = scanner.number(), let y = scanner.number() else { return path }
                let o = relative ? current : .zero
                let end = CGPoint(x: o.x + x, y: o.y + y)
                let c2 = CGPoint(x: o.x + x2, y: o.y + y2)
                var c1 = current
                if let prev = previousControl {
                    c1 = CGPoint(x: 2 * current.x - prev.x, y: 2 * current.y - prev.y)
                }
                path.addCurve(to: end, control1: c1, control2: c2)
                lastControl = c2
                current = end
            case "A", "a":
                guard let rx = scanner.number(), let ry = scanner.number(), let rot = scanner.number(),
                      let large = scanner.flag(), let sweep = scanner.flag(),
                      let x = scanner.number(), let y = scanner.number() else { return path }
                let end = relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
                addArc(to: &path, from: current, to: end, rx: rx, ry: ry, rotation: rot, large: large, sweep: sweep)
                current = end
            default:
                return path
            }
        }
        return path
    }

    // MARK: Boog → bezier (SVG-implementatienotitie F.6)

    private static func addArc(to path: inout Path, from p0: CGPoint, to p1: CGPoint,
                               rx rxIn: Double, ry ryIn: Double, rotation: Double, large: Bool, sweep: Bool) {
        var rx = abs(rxIn), ry = abs(ryIn)
        if rx == 0 || ry == 0 || (p0.x == p1.x && p0.y == p1.y) {
            path.addLine(to: p1)
            return
        }
        let phi = rotation * .pi / 180
        let cosPhi = cos(phi), sinPhi = sin(phi)
        let dx = Double(p0.x - p1.x) / 2, dy = Double(p0.y - p1.y) / 2
        let x1p = cosPhi * dx + sinPhi * dy
        let y1p = -sinPhi * dx + cosPhi * dy

        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 {
            let s = lambda.squareRoot()
            rx *= s
            ry *= s
        }

        let numerator = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
        let denominator = rx * rx * y1p * y1p + ry * ry * x1p * x1p
        var factor = denominator == 0 ? 0 : (max(0, numerator / denominator)).squareRoot()
        if large == sweep { factor = -factor }
        let cxp = factor * (rx * y1p / ry)
        let cyp = factor * -(ry * x1p / rx)
        let cx = cosPhi * cxp - sinPhi * cyp + Double(p0.x + p1.x) / 2
        let cy = sinPhi * cxp + cosPhi * cyp + Double(p0.y + p1.y) / 2

        func angle(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            let dot = ux * vx + uy * vy
            let len = (ux * ux + uy * uy).squareRoot() * (vx * vx + vy * vy).squareRoot()
            var a = acos(max(-1, min(1, dot / len)))
            if ux * vy - uy * vx < 0 { a = -a }
            return a
        }
        let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
        var delta = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
        if !sweep && delta > 0 { delta -= 2 * .pi }
        if sweep && delta < 0 { delta += 2 * .pi }

        let segments = max(1, Int(ceil(abs(delta) / (.pi / 2))))
        let step = delta / Double(segments)
        let t = 4.0 / 3.0 * tan(step / 4)
        var a1 = theta1
        for _ in 0..<segments {
            let a2 = a1 + step
            let cos1 = cos(a1), sin1 = sin(a1), cos2 = cos(a2), sin2 = sin(a2)
            func map(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: cosPhi * rx * x - sinPhi * ry * y + cx,
                        y: sinPhi * rx * x + cosPhi * ry * y + cy)
            }
            let c1 = map(cos1 - t * sin1, sin1 + t * cos1)
            let c2 = map(cos2 + t * sin2, sin2 - t * cos2)
            let e = map(cos2, sin2)
            path.addCurve(to: e, control1: c1, control2: c2)
            a1 = a2
        }
    }

    // MARK: Tokens

    private enum Token {
        case command(Character)
        case number(Double)
    }

    private struct Scanner {
        private let chars: [Character]
        private var i = 0
        private var pending: Token?

        init(_ s: String) { chars = Array(s) }

        mutating func pushBack(_ t: Token) { pending = t }

        mutating func nextCommandOrNumber() -> Token? {
            if let p = pending { pending = nil; return p }
            skipSeparators()
            guard i < chars.count else { return nil }
            let c = chars[i]
            if c.isLetter {
                i += 1
                return .command(c)
            }
            if let n = readNumber() { return .number(n) }
            return nil
        }

        mutating func number() -> Double? {
            if let p = pending {
                pending = nil
                if case .number(let n) = p { return n }
                return nil
            }
            skipSeparators()
            return readNumber()
        }

        /// Vlaggen in een boog zijn één teken (`0` of `1`) en kunnen tegen het volgende getal aan staan.
        mutating func flag() -> Bool? {
            if let p = pending {
                pending = nil
                if case .number(let n) = p { return n != 0 }
                return nil
            }
            skipSeparators()
            guard i < chars.count, chars[i] == "0" || chars[i] == "1" else { return nil }
            let v = chars[i] == "1"
            i += 1
            return v
        }

        private mutating func skipSeparators() {
            while i < chars.count, chars[i] == " " || chars[i] == "," || chars[i] == "\n" { i += 1 }
        }

        private mutating func readNumber() -> Double? {
            var s = ""
            var seenDot = false
            if i < chars.count, chars[i] == "-" || chars[i] == "+" { s.append(chars[i]); i += 1 }
            while i < chars.count {
                let c = chars[i]
                if c.isNumber { s.append(c); i += 1 }
                else if c == ".", !seenDot { seenDot = true; s.append(c); i += 1 }
                else { break }
            }
            return Double(s)
        }
    }
}

/// Een pictogram uit het prototype: één of meer paden, optioneel cirkels, getekend op een raster van 24 × 24.
struct Icon: View {
    struct Circle24 { let cx: CGFloat, cy: CGFloat, r: CGFloat }

    let paths: [String]
    var circles: [Circle24] = []
    var filled = false
    var lineWidth: CGFloat = 2
    var size: CGFloat = 24

    var body: some View {
        Canvas { context, canvasSize in
            let scale = canvasSize.width / 24
            var combined = Path()
            for d in paths { combined.addPath(SVGPath.parse(d)) }
            for c in circles {
                combined.addEllipse(in: CGRect(x: c.cx - c.r, y: c.cy - c.r, width: c.r * 2, height: c.r * 2))
            }
            let scaled = combined.applying(CGAffineTransform(scaleX: scale, y: scale))
            let color = GraphicsContext.Shading.foreground
            if filled {
                context.fill(scaled, with: color)
            } else {
                context.stroke(scaled, with: color,
                               style: StrokeStyle(lineWidth: lineWidth * scale, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Alle pictogrammen die het prototype gebruikt.
extension Icon {
    static func chevronDown(_ size: CGFloat = 18, _ w: CGFloat = 2.4) -> Icon { Icon(paths: ["M6 9l6 6 6-6"], lineWidth: w, size: size) }
    static func chevronRight(_ size: CGFloat = 22) -> Icon { Icon(paths: ["M9 6l6 6-6 6"], lineWidth: 2.4, size: size) }
    /// Twee pijltjes (omhoog/omlaag): "kies een andere".
    static func updown(_ size: CGFloat = 22) -> Icon { Icon(paths: ["M8 9l4-4 4 4", "M8 15l4 4 4-4"], lineWidth: 2.2, size: size) }
    static func chevronLeft(_ size: CGFloat = 22) -> Icon { Icon(paths: ["M15 6l-6 6 6 6"], lineWidth: 2.4, size: size) }
    static func chevronUp(_ size: CGFloat = 18) -> Icon { Icon(paths: ["M6 15l6-6 6 6"], lineWidth: 2.4, size: size) }
    static func check(_ size: CGFloat = 16, _ w: CGFloat = 2.8) -> Icon { Icon(paths: ["M5 12.5l4.5 4.5L19 7.5"], lineWidth: w, size: size) }
    static func plus(_ size: CGFloat = 18, _ w: CGFloat = 2.2) -> Icon { Icon(paths: ["M12 5v14M5 12h14"], lineWidth: w, size: size) }
    static func minus(_ size: CGFloat = 20, _ w: CGFloat = 2.4) -> Icon { Icon(paths: ["M5 12h14"], lineWidth: w, size: size) }
    static func close(_ size: CGFloat = 20) -> Icon { Icon(paths: ["M6 6l12 12M18 6L6 18"], lineWidth: 2.2, size: size) }
    static func link(_ size: CGFloat = 14, _ w: CGFloat = 2.2) -> Icon {
        Icon(paths: ["M10 14a4 4 0 0 0 5.66 0l3-3a4 4 0 0 0-5.66-5.66l-1 1M14 10a4 4 0 0 0-5.66 0l-3 3a4 4 0 0 0 5.66 5.66l1-1"], lineWidth: w, size: size)
    }
    static func swap(_ size: CGFloat = 18) -> Icon { Icon(paths: ["M4 8h14l-3.5-3.5M20 16H6l3.5 3.5"], lineWidth: 2, size: size) }
    static func trash(_ size: CGFloat = 18) -> Icon { Icon(paths: ["M5 7h14M10 11v6M14 11v6M6 7l1 12h10l1-12M9 7V4h6v3"], lineWidth: 2, size: size) }
    static func more(_ size: CGFloat = 24) -> Icon {
        Icon(paths: [], circles: [.init(cx: 5, cy: 12, r: 1.9), .init(cx: 12, cy: 12, r: 1.9), .init(cx: 19, cy: 12, r: 1.9)], filled: true, size: size)
    }
    static func play(_ size: CGFloat = 18) -> Icon { Icon(paths: ["M8 5.5v13l11-6.5z"], filled: true, size: size) }
    static func explain(_ size: CGFloat = 18) -> Icon {
        Icon(paths: ["M10 8.8v6.4l5-3.2z"], circles: [.init(cx: 12, cy: 12, r: 9)], lineWidth: 2, size: size)
    }
    static func pin(_ size: CGFloat = 16) -> Icon {
        Icon(paths: ["M12 21s-6.5-5.6-6.5-11a6.5 6.5 0 0 1 13 0c0 5.4-6.5 11-6.5 11z"], circles: [.init(cx: 12, cy: 10, r: 2.3)], lineWidth: 2.2, size: size)
    }
    static func clock(_ size: CGFloat = 18) -> Icon {
        Icon(paths: ["M12 7v5l3 2"], circles: [.init(cx: 12, cy: 12, r: 9)], lineWidth: 2, size: size)
    }
    static func timer(_ size: CGFloat = 20) -> Icon {
        Icon(paths: ["M12 9v4l2.5 2M9 2.5h6"], circles: [.init(cx: 12, cy: 13, r: 8)], lineWidth: 2, size: size)
    }
    static func machine(_ size: CGFloat = 20) -> Icon { Icon(paths: ["M5 3v18M19 3v18M5 3h14M9 8h6M9 12h6M9 16h6"], lineWidth: 2, size: size) }
    static func edit(_ size: CGFloat = 20) -> Icon { Icon(paths: ["M4 20h4L19 9l-4-4L4 16v4zM13.5 6.5l4 4"], lineWidth: 2, size: size) }
    static func duplicate(_ size: CGFloat = 20) -> Icon { Icon(paths: ["M8 8h11v11H8zM5 16V5h11"], lineWidth: 2, size: size) }
    static func star(_ size: CGFloat = 20) -> Icon { Icon(paths: ["M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8L3.5 9.7l5.9-.9z"], lineWidth: 2, size: size) }
    static func sort(_ size: CGFloat = 18) -> Icon { Icon(paths: ["M7 4v16M7 20l-3-3M7 20l3-3M17 20V4M17 4l-3 3M17 4l3 3"], lineWidth: 2.2, size: size) }
    static func skip(_ size: CGFloat = 20) -> Icon { Icon(paths: ["M5 5l9 7-9 7zM18 5v14"], lineWidth: 2, size: size) }
    static func starFilled(_ size: CGFloat = 20) -> Icon {
        Icon(paths: ["M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8L3.5 9.7l5.9-.9z"], filled: true, lineWidth: 2, size: size)
    }
    static func filter(_ size: CGFloat = 20) -> Icon { Icon(paths: ["M4 7h16M7 12h10M10 17h4"], lineWidth: 2.2, size: size) }
    static func search(_ size: CGFloat = 18) -> Icon {
        Icon(paths: ["M20 20l-3.5-3.5"], circles: [.init(cx: 11, cy: 11, r: 7)], lineWidth: 2.2, size: size)
    }

    // Tabbalk (omtrek, 24 × 24, lijn 2)
    static let tabTraining = Icon(paths: ["M6.5 6v12M17.5 6v12M3.5 9v6M20.5 9v6M6.5 12h11"])
    static let tabProgress = Icon(paths: ["M5 20v-8M12 20V5M19 20v-5"])
    static let tabGym = Icon(paths: ["M4 21V9l8-5 8 5v12M9 21v-6h6v6"])
    static let tabProfile = Icon(paths: ["M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4.5 20.5a7.5 7.5 0 0 1 15 0"])
}
