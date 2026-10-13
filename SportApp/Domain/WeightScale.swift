import Foundation

/// Beschrijft welke gewichten één specifiek apparaat (machine, stang, dumbbell-rek) echt kan laden.
///
/// Dit is het hart van de "gym-specifieke gewichtsstappen": de +/- knoppen, de afronding van
/// suggesties en later de OCR-scan werken allemaal via dit type.
///
/// Twee manieren om de geldige gewichten vast te leggen:
/// 1. `minWeight` / `maxWeight` / `increment` (regelmatige stapel, bv. 5 t/m 95 in stappen van 5)
/// 2. `availableWeights` (onregelmatige stapel, bv. 15, 20, 25, 35, 45). Als deze niet leeg is,
///    wint hij van optie 1.
/// `addOnIncrement` beschrijft een pinplaatje tussen twee stapelposities (bv. +1,25 kg).
struct WeightScale: Codable, Hashable {

    enum Kind: String, Codable, CaseIterable, Hashable {
        case stack, plateLoaded, dumbbells, barbell, bodyweight

        var displayName: String {
            switch self {
            case .stack: return "Gewichtenstapel"
            case .plateLoaded: return "Plate-loaded"
            case .dumbbells: return "Dumbbells"
            case .barbell: return "Stang"
            case .bodyweight: return "Lichaamsgewicht"
            }
        }
    }

    var kind: Kind
    var minWeight: Double
    var maxWeight: Double
    var increment: Double
    var availableWeights: [Double]
    var addOnIncrement: Double?

    init(kind: Kind,
         minWeight: Double = 0,
         maxWeight: Double = 0,
         increment: Double = 2.5,
         availableWeights: [Double] = [],
         addOnIncrement: Double? = nil) {
        self.kind = kind
        self.minWeight = minWeight
        self.maxWeight = maxWeight
        self.increment = increment
        self.availableWeights = availableWeights
        self.addOnIncrement = addOnIncrement
    }

    // MARK: - Presets

    static func stack(min minWeight: Double, max maxWeight: Double, step: Double, addOn: Double? = nil) -> WeightScale {
        WeightScale(kind: .stack, minWeight: minWeight, maxWeight: maxWeight, increment: step, addOnIncrement: addOn)
    }

    static func plateLoaded(min minWeight: Double, max maxWeight: Double, step: Double) -> WeightScale {
        WeightScale(kind: .plateLoaded, minWeight: minWeight, maxWeight: maxWeight, increment: step)
    }

    static func dumbbells(min minWeight: Double = 2.5, max maxWeight: Double = 40, step: Double = 2.5) -> WeightScale {
        WeightScale(kind: .dumbbells, minWeight: minWeight, maxWeight: maxWeight, increment: step)
    }

    /// `smallestStep` = kleinste plaatjespaar (2 × 1,25 kg = 2,5 kg).
    static func barbell(barWeight: Double = 20, maxWeight: Double = 200, smallestStep: Double = 2.5) -> WeightScale {
        WeightScale(kind: .barbell, minWeight: barWeight, maxWeight: maxWeight, increment: smallestStep)
    }

    /// Extra gewicht (riem/vest) in stappen van 2,5 kg. Zonder extra gewicht blijft het 0.
    static let bodyweight = WeightScale(kind: .bodyweight, minWeight: 0, maxWeight: 0, increment: 2.5)

    /// Onbegrensd: gebruikt als een oefening geen bekend apparaat heeft.
    static let fallback = WeightScale(kind: .stack, minWeight: 0, maxWeight: 0, increment: 2.5)

    // MARK: - Geldige gewichten

    /// `true` als er een bekende lijst/bereik is. Anders zijn alle veelvouden van `increment` toegestaan.
    var isConstrained: Bool {
        !availableWeights.isEmpty || maxWeight > minWeight
    }

    func validWeights() -> [Double] {
        if !availableWeights.isEmpty {
            return Array(Set(availableWeights.map { WeightScale.clean($0) })).sorted()
        }
        guard increment > 0, maxWeight > minWeight else { return [] }

        var result: [Double] = []
        let steps = Int(((maxWeight - minWeight) / increment + 1e-9).rounded(.down))
        for i in 0...steps {
            let base = WeightScale.clean(minWeight + Double(i) * increment)
            result.append(base)
            if let addOn = addOnIncrement, addOn > 0, addOn < increment {
                let extras = Int((increment / addOn + 1e-9).rounded(.down)) - 1
                if extras >= 1 {
                    for j in 1...extras {
                        let weight = WeightScale.clean(base + Double(j) * addOn)
                        if weight <= maxWeight + 1e-9 { result.append(weight) }
                    }
                }
            }
        }
        return result
    }

    func isValid(_ weight: Double) -> Bool {
        guard isConstrained else {
            guard increment > 0 else { return true }
            let ratio = weight / increment
            return abs(ratio - ratio.rounded()) < 1e-6
        }
        return validWeights().contains { abs($0 - weight) < 1e-6 }
    }

    /// Dichtstbijzijnde geldige gewicht. Bij een gelijke afstand wint het zwaardere gewicht.
    func snap(_ weight: Double) -> Double {
        let valid = validWeights()
        guard !valid.isEmpty else {
            guard increment > 0 else { return WeightScale.clean(max(0, weight)) }
            return WeightScale.clean(max(0, (weight / increment).rounded() * increment))
        }
        var best = valid[0]
        var bestDistance = abs(valid[0] - weight)
        for candidate in valid.dropFirst() {
            let distance = abs(candidate - weight)
            if distance < bestDistance || (distance == bestDistance && candidate > best) {
                best = candidate
                bestDistance = distance
            }
        }
        return best
    }

    /// Eerstvolgende geldige gewicht boven `weight` (werkt ook als `weight` zelf niet geldig is).
    func next(after weight: Double) -> Double? {
        let eps = 1e-6
        guard isConstrained else { return WeightScale.clean(weight + increment) }
        return validWeights().first { $0 > weight + eps }
    }

    /// Eerstvolgende geldige gewicht onder `weight`.
    func previous(before weight: Double) -> Double? {
        let eps = 1e-6
        guard isConstrained else {
            guard weight > eps else { return nil }
            return max(0, WeightScale.clean(weight - increment))
        }
        return validWeights().last { $0 < weight - eps }
    }

    /// Voor de +/- knoppen. Blijft op hetzelfde gewicht staan als er geen volgende stap is.
    func step(from weight: Double, up: Bool) -> Double {
        if up { return next(after: weight) ?? weight }
        return previous(before: weight) ?? weight
    }

    // MARK: - Hulp voor de (toekomstige) scan-flow

    /// Raadt de stapgrootte uit gedetecteerde getallen (bv. [5, 10, 15, 20, 25, 35] → 5).
    /// Geeft nil als er geen duidelijk patroon is. De UI laat de gebruiker dit altijd bevestigen.
    static func inferIncrement(from values: [Double]) -> Double? {
        let sorted = Array(Set(values.map { clean($0) })).sorted()
        if sorted.count < 2 { return nil }
        if sorted.count == 2 { return clean(sorted[1] - sorted[0]) }

        var counts: [Double: Int] = [:]
        for (a, b) in zip(sorted, sorted.dropFirst()) {
            counts[clean(b - a), default: 0] += 1
        }
        guard let best = counts.max(by: { $0.value < $1.value }) else { return nil }
        let share = Double(best.value) / Double(sorted.count - 1)
        return share >= 0.5 ? best.key : nil
    }

    private static func clean(_ value: Double) -> Double {
        (value * 1000).rounded() / 1000
    }
}
