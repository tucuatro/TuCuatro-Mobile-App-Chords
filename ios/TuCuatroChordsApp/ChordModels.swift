import Foundation

struct ChordLibrary: Codable {
    let version: String
    let updatedAt: String
    let sourceHash: String
    let instruments: [String: [String: String]]
    let positions: [String: [String: [String: String]]]

    enum CodingKeys: String, CodingKey {
        case version
        case updatedAt = "updated_at"
        case sourceHash = "source_hash"
        case instruments
        case positions
    }

    func shape(instrument: String, chord: String, position: String = "1st") -> ChordShape? {
        let encoded = positions[instrument]?[chord]?[position]
            ?? instruments[instrument]?[chord]
        return encoded.map { ChordShape(encoded: $0) }
    }
}

struct ChordShape: Equatable {
    enum StringState: Equatable {
        case muted
        case fret(Int)
    }

    let strings: [StringState]

    init(encoded: String) {
        strings = encoded.split(separator: ".").compactMap { token in
            if token.uppercased() == "X" {
                return .muted
            }
            guard let fret = Int(token) else { return nil }
            return .fret(fret)
        }
    }

    var pressedFrets: [Int] {
        strings.compactMap {
            guard case let .fret(fret) = $0, fret > 0 else { return nil }
            return fret
        }
    }

    /// Mirrors the Web renderer: only shift a shape when it cannot fit in the
    /// 0...4 window and the lowest pressed fret is above fret 2.
    var baseFret: Int {
        let pressed = pressedFrets
        guard let minimum = pressed.min(), let maximum = pressed.max(),
              maximum > 4, minimum > 2 else { return 1 }
        return minimum
    }

    func displayFret(for fret: Int) -> Int {
        guard fret > 0 else { return fret }
        let shifted = baseFret > 1 ? fret - baseFret + 1 : fret
        return min(max(shifted, 1), 4)
    }

    /// Fret on which Web would infer a visual barre after applying the
    /// higher-position shift. Nil means no barre.
    var barreFret: Int? {
        let values: [Int?] = strings.map { state in
            switch state {
            case .muted:
                return nil
            case let .fret(fret):
                guard fret > 0 else { return 0 }
                return displayFret(for: fret)
            }
        }

        let pressed = values.compactMap { $0 }.filter { $0 > 0 }
        guard let minimum = pressed.min() else { return nil }

        let hasOpenString = values.contains { $0 == 0 }
        if hasOpenString { return nil }

        let countAtMinimum = pressed.filter { $0 == minimum }.count
        let hasHigherFret = pressed.contains { $0 > minimum }

        if strings.count == 4 {
            if countAtMinimum == 4 { return minimum }
            if countAtMinimum >= 3 { return minimum }
            if countAtMinimum >= 2 && hasHigherFret { return minimum }
            return nil
        }

        if strings.count == 6 {
            let firstMuted: Bool
            let lastMuted: Bool

            if case .muted = strings.first { firstMuted = true } else { firstMuted = false }
            if case .muted = strings.last { lastMuted = true } else { lastMuted = false }
            let hasOuterMute = firstMuted || lastMuted

            if countAtMinimum >= 4 { return minimum }
            if countAtMinimum == 3 && hasHigherFret { return minimum }
            if countAtMinimum == 2 && hasHigherFret && hasOuterMute { return minimum }
        }

        return nil
    }
}

extension ChordLibrary {
    static let prototype = ChordLibrary(
        version: "prototype",
        updatedAt: "2026-09-27T00:00:00Z",
        sourceHash: "prototype",
        instruments: [
            "cuatro": [
                "A": "0.2.3.2",
                "Bb": "1.3.4.3"
            ]
        ],
        positions: [
            "cuatro": [
                "A": [
                    "1st": "0.2.3.2",
                    "2nd": "4.2.3.2",
                    "3rd": "0.7.7.5",
                    "4th": "7.7.7.5",
                    "5th": "4.2.3.5"
                ]
            ]
        ]
    )
}
