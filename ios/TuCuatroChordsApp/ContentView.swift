import SwiftUI

struct ContentView: View {
    @StateObject private var store = ChordStore()

    @State private var instrument = "cuatro"
    @State private var chord = "A"
    @State private var position = "1st"
    @State private var showingChordPicker = false

    private var availableChords: [String] {
        store.chords(for: instrument)
    }

    private var availablePositions: [String] {
        store.positions(for: instrument, chord: chord)
    }

    private var shape: ChordShape {
        store.library.shape(instrument: instrument, chord: chord, position: position)
            ?? ChordShape(encoded: "0.2.3.2")
    }

    private var accent: Color {
        switch instrument.lowercased() {
        case "cuatro":
            return Color(red: 254 / 255, green: 160 / 255, blue: 47 / 255)
        case "guitar":
            return Color(red: 74 / 255, green: 144 / 255, blue: 226 / 255)
        default:
            return Color(red: 254 / 255, green: 160 / 255, blue: 47 / 255)
        }
    }

    var body: some View {
        ZStack {
            Color(red: 18 / 255, green: 17 / 255, blue: 15 / 255)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    brandLine
                        .padding(.top, 16)

                    instrumentSelector
                        .padding(.top, 14)

                    chordSearch
                        .padding(.top, 16)

                    chordIdentity
                        .padding(.top, 28)

                    ChordDiagram(
                        shape: shape,
                        position: position,
                        accent: accent,
                        instrument: instrument
                    )
                    .frame(height: 320)
                    .padding(.top, 24)

                    if !availablePositions.isEmpty {
                        positionSelector
                            .padding(.top, 22)
                    }

                    syncFooter
                        .padding(.top, 28)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 28)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
        .task {
            await store.refresh()
            normalizeSelection()
        }
        .onChange(of: instrument) { _ in
            if let first = availableChords.first {
                chord = first
            }
            position = store.positions(for: instrument, chord: chord).first ?? "1st"
        }
        .onChange(of: chord) { _ in
            position = availablePositions.first ?? "1st"
        }
        .sheet(isPresented: $showingChordPicker) {
            ChordPickerSheet(
                chords: availableChords,
                selection: $chord,
                accent: accent
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var brandLine: some View {
        Text("TUCUATRO CHORDS")
            .font(.system(size: 13, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(Color(red: 245 / 255, green: 241 / 255, blue: 232 / 255).opacity(0.72))
    }

    private var instrumentSelector: some View {
        Menu {
            ForEach(store.instruments, id: \.self) { item in
                Button(displayName(for: item)) {
                    instrument = item
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: instrumentSymbol)
                    .font(.headline)
                    .foregroundStyle(accent)

                Text(instrumentDisplayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(cream)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption.bold())
                    .foregroundStyle(warmGray)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var chordSearch: some View {
        Button {
            showingChordPicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(warmGray)

                Text("Search chords")
                    .font(.system(size: 16))
                    .foregroundStyle(warmGray)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Search chords")
        .accessibilityValue(chord)
    }

    private var chordIdentity: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chord)
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .tracking(-1.5)
                .foregroundStyle(cream)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(instrumentDisplayName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(warmGray)
        }
    }

    private var positionSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("POSITIONS")
                .font(.system(size: 12, weight: .bold))
                .tracking(1)
                .foregroundStyle(warmGray)

            HStack(spacing: 8) {
                ForEach(Array(availablePositions.enumerated()), id: \.element) { index, item in
                    Button {
                        position = item
                    } label: {
                        Text("\(index + 1)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(position == item ? Color(red: 24 / 255, green: 22 / 255, blue: 19 / 255) : cream)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(position == item ? accent : surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Position \(index + 1)")
                }
            }
        }
    }

    private var syncFooter: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)

            Text(footerStatusText)
                .font(.system(size: 12))
                .foregroundStyle(quietGray)

            Spacer()

            Text(shortVersion)
                .font(.system(size: 12))
                .foregroundStyle(quietGray)
        }
    }

    private var footerStatusText: String {
        switch store.syncState {
        case .idle:
            return "Offline library ready"
        case .checking:
            return "Checking for updates"
        case .current:
            return "Library current"
        case .updated:
            return "Library updated"
        case .offline:
            return "Offline library ready"
        case .failed:
            return "Using offline library"
        }
    }

    private var statusColor: Color {
        switch store.syncState {
        case .current, .updated:
            return Color(red: 102 / 255, green: 184 / 255, blue: 120 / 255)
        case .checking:
            return accent
        case .idle, .offline, .failed:
            return quietGray
        }
    }

    private var shortVersion: String {
        let raw = store.library.version
        if raw.hasPrefix("2026.") {
            return "v" + String(raw.prefix(7))
        }
        return raw == "prototype" ? "local" : raw
    }

    private var instrumentDisplayName: String {
        displayName(for: instrument)
    }

    private var instrumentSymbol: String {
        switch instrument.lowercased() {
        case "guitar": return "guitars"
        case "ukulele", "cavaquinho", "cuatro": return "music.note"
        default: return "music.note"
        }
    }

    private var cream: Color {
        Color(red: 245 / 255, green: 241 / 255, blue: 232 / 255)
    }

    private var warmGray: Color {
        Color(red: 175 / 255, green: 166 / 255, blue: 155 / 255)
    }

    private var quietGray: Color {
        Color(red: 143 / 255, green: 135 / 255, blue: 126 / 255)
    }

    private var surface: Color {
        Color(red: 35 / 255, green: 32 / 255, blue: 28 / 255)
    }

    private func displayName(for value: String) -> String {
        switch value.lowercased() {
        case "cuatro": return "Venezuelan Cuatro"
        case "guitar": return "Guitar"
        case "ukulele": return "Ukulele"
        case "cavaquinho": return "Cavaquinho"
        default: return value.capitalized
        }
    }

    private func normalizeSelection() {
        if !store.instruments.contains(instrument),
           let firstInstrument = store.instruments.first {
            instrument = firstInstrument
        }

        let chords = store.chords(for: instrument)
        if !chords.contains(chord), let firstChord = chords.first {
            chord = firstChord
        }

        let positions = store.positions(for: instrument, chord: chord)
        if !positions.contains(position) {
            position = positions.first ?? "1st"
        }
    }
}

private struct ChordPickerSheet: View {
    let chords: [String]
    @Binding var selection: String
    let accent: Color

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @FocusState private var searchIsFocused: Bool

    private var filteredChords: [String] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return chords
        }
        return chords.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search chords", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($searchIsFocused)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Color.secondary.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)

                List(filteredChords, id: \.self) { chord in
                    Button {
                        selection = chord
                        dismiss()
                    } label: {
                        HStack {
                            Text(chord)
                                .foregroundStyle(.primary)
                            Spacer()
                            if chord == selection {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(accent)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Choose Chord")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                try? await Task.sleep(nanoseconds: 180_000_000)
                searchIsFocused = true
            }
        }
        .tint(accent)
    }
}

private struct ChordDiagram: View {
    let shape: ChordShape
    let position: String
    let accent: Color
    let instrument: String

    private let visibleFrets = 4

    private var isSixString: Bool {
        shape.strings.count == 6
    }

    private var diagramWidthFactor: CGFloat {
        isSixString ? 0.88 : 0.42
    }

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = proxy.size.width
            let diagramWidth = cardWidth * diagramWidthFactor
            let left = (cardWidth - diagramWidth) / 2
            let top: CGFloat = 70
            let bottom: CGFloat = 52
            let width = diagramWidth
            let height = max(proxy.size.height - top - bottom, 1)
            let stringCount = max(shape.strings.count, 2)
            let stringSpacing = width / CGFloat(stringCount - 1)
            let fretSpacing = height / CGFloat(visibleFrets)

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(red: 245 / 255, green: 241 / 255, blue: 232 / 255))

                HStack {
                    Text("POSITION \(positionNumber)")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Color(red: 111 / 255, green: 102 / 255, blue: 93 / 255))

                    Spacer()
                }
                .padding(.horizontal, 22)
                .position(x: cardWidth / 2, y: 34)

                ForEach(0..<stringCount, id: \.self) { index in
                    Path { path in
                        let x = left + CGFloat(index) * stringSpacing
                        path.move(to: CGPoint(x: x, y: top))
                        path.addLine(to: CGPoint(x: x, y: top + height))
                    }
                    .stroke(Color(red: 42 / 255, green: 39 / 255, blue: 35 / 255), lineWidth: 2)
                }

                ForEach(0...visibleFrets, id: \.self) { fret in
                    Path { path in
                        let y = top + CGFloat(fret) * fretSpacing
                        path.move(to: CGPoint(x: left, y: y))
                        path.addLine(to: CGPoint(x: left + width, y: y))
                    }
                    .stroke(
                        Color(red: 83 / 255, green: 77 / 255, blue: 70 / 255),
                        lineWidth: fret == 0 && shape.baseFret == 1 ? 5 : 1
                    )
                }

                if shape.baseFret > 1 {
                    Text("\(shape.baseFret)fr")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(red: 111 / 255, green: 102 / 255, blue: 93 / 255))
                        .position(
                            x: max(left - 24, 16),
                            y: top + fretSpacing / 2
                        )
                }

                if let barreFret = shape.barreFret {
                    Capsule()
                        .fill(accent)
                        .frame(width: width + 6, height: 12)
                        .position(
                            x: left + width / 2,
                            y: top + (CGFloat(barreFret) - 0.5) * fretSpacing
                        )
                }

                ForEach(Array(shape.strings.enumerated()), id: \.offset) { index, state in
                    let x = left + CGFloat(index) * stringSpacing

                    switch state {
                    case .muted:
                        Text("×")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(red: 42 / 255, green: 39 / 255, blue: 35 / 255))
                            .position(x: x, y: top - 22)

                    case .fret(0):
                        Circle()
                            .stroke(Color(red: 42 / 255, green: 39 / 255, blue: 35 / 255), lineWidth: 2)
                            .frame(width: 13, height: 13)
                            .position(x: x, y: top - 22)

                    case let .fret(fret):
                        let displayed = shape.displayFret(for: fret)
                        if shape.barreFret != displayed {
                            Circle()
                                .fill(accent)
                                .frame(width: 28, height: 28)
                                .position(
                                    x: x,
                                    y: top + (CGFloat(displayed) - 0.5) * fretSpacing
                                )
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Chord diagram")
    }

    private var positionNumber: String {
        switch position {
        case "1st": return "1"
        case "2nd": return "2"
        case "3rd": return "3"
        case "4th": return "4"
        case "5th": return "5"
        default: return position
        }
    }
}

#Preview {
    ContentView()
}
