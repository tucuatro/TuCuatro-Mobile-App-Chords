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

    var baseFret: Int {
        let pressed = pressedFrets
        guard let minimum = pressed.min(), let maximum = pressed.max(),
              maximum > 4, minimum > 2 else { return 1 }
        return minimum
    }

    func displayFret(for fret: Int) -> Int {
        guard fret > 0, baseFret > 1 else { return fret }
        return fret - baseFret + 1
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
