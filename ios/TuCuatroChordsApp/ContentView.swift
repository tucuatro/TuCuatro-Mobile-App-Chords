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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    libraryStatus

                    selectors

                    VStack(spacing: 4) {
                        Text(chord)
                            .font(.system(size: 50, weight: .bold, design: .rounded))

                        Text(instrumentDisplayName)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    ChordDiagram(shape: shape)
                        .frame(maxWidth: 330)
                        .frame(height: 390)
                        .padding(.horizontal, 8)

                    if availablePositions.count > 1 {
                        Picker("Position", selection: $position) {
                            ForEach(availablePositions, id: \.self) { item in
                                Text(item).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Text("Works offline • updates from TuCuatro when available")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .navigationTitle("TuCuatro Chords")
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
        }
    }

    private var libraryStatus: some View {
        HStack(spacing: 8) {
            Image(systemName: statusSymbol)
            Text(store.syncState.label)
                .lineLimit(1)
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }

    private var selectors: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(store.instruments, id: \.self) { item in
                    Button(displayName(for: item)) {
                        instrument = item
                    }
                }
            } label: {
                selectorLabel(title: "Instrument", value: instrumentDisplayName, systemImage: "guitars")
            }

            Button {
                showingChordPicker = true
            } label: {
                selectorLabel(title: "Chord", value: chord, systemImage: "music.note")
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingChordPicker) {
            ChordPickerSheet(
                chords: availableChords,
                selection: $chord
            )
            .presentationDetents([.medium, .large])
        }
    }

    private func selectorLabel(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var instrumentDisplayName: String {
        displayName(for: instrument)
    }

    private var statusSymbol: String {
        switch store.syncState {
        case .checking:
            return "arrow.triangle.2.circlepath"
        case .updated, .current:
            return "checkmark.circle"
        case .idle, .offline, .failed:
            return "iphone"
        }
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
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
            .navigationTitle("Choose Chord")
            .searchable(text: $searchText, prompt: "Search chords")
            .searchFocused($searchIsFocused)
            .task {
                try? await Task.sleep(nanoseconds: 180_000_000)
                searchIsFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct ChordDiagram: View {
    let shape: ChordShape
    private let visibleFrets = 4

    var body: some View {
        GeometryReader { proxy in
            let left: CGFloat = 46
            let right: CGFloat = 22
            let top: CGFloat = 46
            let bottom: CGFloat = 24
            let width = max(proxy.size.width - left - right, 1)
            let height = max(proxy.size.height - top - bottom, 1)
            let stringCount = max(shape.strings.count, 2)
            let stringSpacing = width / CGFloat(stringCount - 1)
            let fretSpacing = height / CGFloat(visibleFrets)

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.secondary.opacity(0.06))

                ForEach(0..<stringCount, id: \.self) { index in
                    Path { path in
                        let x = left + CGFloat(index) * stringSpacing
                        path.move(to: CGPoint(x: x, y: top))
                        path.addLine(to: CGPoint(x: x, y: top + height))
                    }
                    .stroke(.primary, lineWidth: 1.5)
                }

                ForEach(0...visibleFrets, id: \.self) { fret in
                    Path { path in
                        let y = top + CGFloat(fret) * fretSpacing
                        path.move(to: CGPoint(x: left, y: y))
                        path.addLine(to: CGPoint(x: left + width, y: y))
                    }
                    .stroke(
                        .primary,
                        lineWidth: fret == 0 && shape.baseFret == 1 ? 4 : 1
                    )
                }

                if shape.baseFret > 1 {
                    Text("\(shape.baseFret)fr")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .position(x: 23, y: top + fretSpacing / 2)
                }

                if let barreFret = shape.barreFret {
                    Capsule()
                        .fill(.primary)
                        .frame(width: stringCount == 6 ? width + 8 : width * 0.63, height: 14)
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
                            .font(.title2.bold())
                            .position(x: x, y: 20)

                    case .fret(0):
                        Circle()
                            .stroke(.primary, lineWidth: 1.5)
                            .frame(width: 12, height: 12)
                            .position(x: x, y: 20)

                    case let .fret(fret):
                        let displayed = shape.displayFret(for: fret)
                        Circle()
                            .fill(.primary)
                            .frame(width: 25, height: 25)
                            .position(
                                x: x,
                                y: top + (CGFloat(displayed) - 0.5) * fretSpacing
                            )
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Chord diagram")
    }
}

#Preview {
    ContentView()
}
