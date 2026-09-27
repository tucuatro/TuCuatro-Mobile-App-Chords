import Combine
import Foundation

struct ChordManifest: Codable {
    let version: String
    let updatedAt: String
    let sourceHash: String
    let chordsURL: URL

    enum CodingKeys: String, CodingKey {
        case version
        case updatedAt = "updated_at"
        case sourceHash = "source_hash"
        case chordsURL = "chords_url"
    }
}

@MainActor
final class ChordStore: ObservableObject {
    enum SyncState: Equatable {
        case idle
        case checking
        case current
        case updated
        case offline
        case failed(String)

        var label: String {
            switch self {
            case .idle: return "Offline library ready"
            case .checking: return "Checking for chord updates…"
            case .current: return "Chord library is current"
            case .updated: return "Chord library updated"
            case .offline: return "Offline mode"
            case .failed: return "Using offline library"
            }
        }
    }

    static let manifestURL = URL(
        string: "https://tucuatro.com/wp-content/uploads/tucuatro-chords-library/manifest.json"
    )!

    @Published private(set) var library: ChordLibrary
    @Published private(set) var syncState: SyncState = .idle

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        library = Self.loadInitialLibrary()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    var instruments: [String] {
        library.instruments.keys.sorted()
    }

    func chords(for instrument: String) -> [String] {
        library.instruments[instrument]?.keys
            .filter { $0 != "-" && $0 != "xx" }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending } ?? []
    }

    func positions(for instrument: String, chord: String) -> [String] {
        let preferred = ["1st", "2nd", "3rd", "4th", "5th"]
        let keys = library.positions[instrument]?[chord]?.filter { !$0.value.isEmpty }.map(\.key) ?? []
        if keys.isEmpty {
            return ["1st"]
        }
        return preferred.filter(keys.contains)
    }

    func refresh() async {
        syncState = .checking

        do {
            let (manifestData, manifestResponse) = try await URLSession.shared.data(from: Self.manifestURL)
            guard let http = manifestResponse as? HTTPURLResponse, http.statusCode == 200 else {
                syncState = .offline
                return
            }

            let manifest = try decoder.decode(ChordManifest.self, from: manifestData)
            guard manifest.sourceHash != library.sourceHash else {
                syncState = .current
                return
            }

            let (libraryData, libraryResponse) = try await URLSession.shared.data(from: manifest.chordsURL)
            guard let libraryHTTP = libraryResponse as? HTTPURLResponse, libraryHTTP.statusCode == 200 else {
                syncState = .offline
                return
            }

            let candidate = try decoder.decode(ChordLibrary.self, from: libraryData)
            guard candidate.sourceHash == manifest.sourceHash,
                  candidate.instruments["cuatro"]?.isEmpty == false else {
                syncState = .failed("Invalid remote chord library")
                return
            }

            library = candidate
            try saveCache(candidate)
            syncState = .updated
        } catch {
            syncState = .offline
        }
    }

    private static func loadInitialLibrary() -> ChordLibrary {
        let decoder = JSONDecoder()

        if let cacheURL = cacheURL(),
           let data = try? Data(contentsOf: cacheURL),
           let cached = try? decoder.decode(ChordLibrary.self, from: data),
           cached.instruments["cuatro"]?.isEmpty == false {
            return cached
        }

        if let bundledURL = Bundle.main.url(forResource: "chords-bundled", withExtension: "json"),
           let data = try? Data(contentsOf: bundledURL),
           let bundled = try? decoder.decode(ChordLibrary.self, from: data) {
            return bundled
        }

        return .prototype
    }

    private func saveCache(_ library: ChordLibrary) throws {
        guard let url = Self.cacheURL() else { return }
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try encoder.encode(library).write(to: url, options: .atomic)
    }

    private static func cacheURL() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("TuCuatroChords", isDirectory: true)
            .appendingPathComponent("chords.json")
    }
}
