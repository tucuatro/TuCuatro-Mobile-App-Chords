import SwiftUI

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var store = ChordStore()

    @State private var instrument = "cuatro"
    @State private var chord = "A"
    @State private var position = "1st"
    @State private var showingChordPicker = false

    @State private var launchTraceProgress: CGFloat = 0
    @State private var launchCurtainOpacity: Double = 1
    @State private var launchTraceOpacity: Double = 1
    @State private var launchExpressionComplete = false

    @State private var instrumentHandoffProgress: CGFloat = 0
    @State private var instrumentHandoffVisible = false
    @State private var instrumentPresentationOpacity: Double = 1
    @State private var instrumentHandoffGeneration = 0

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
            return Color(red: 254 / 255, green: 160 / 255, blue: 47 / 255) // #FEA02F
        case "guitar":
            return Color(red: 2 / 255, green: 116 / 255, blue: 190 / 255) // #0274BE
        case "ukulele":
            return Color(red: 230 / 255, green: 33 / 255, blue: 23 / 255) // #E62117
        case "cavaquinho":
            return Color(red: 139 / 255, green: 195 / 255, blue: 74 / 255) // #8BC34A
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
                        .padding(.top, 20)

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

            if !launchExpressionComplete {
                LivingCuatroLaunchOverlay(
                    progress: launchTraceProgress,
                    curtainOpacity: launchCurtainOpacity,
                    traceOpacity: launchTraceOpacity,
                    reduceMotion: reduceMotion
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .ignoresSafeArea()
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await store.refresh()
            normalizeSelection()
        }
        .task {
            await runLaunchExpression()
        }
        .onChange(of: instrument) { _ in
            if let first = availableChords.first {
                chord = first
            }
            position = store.positions(for: instrument, chord: chord).first ?? "1st"
            triggerInstrumentHandoff()
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
        HStack(spacing: 10) {
            Image("TuCuatroMark")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 34)
                .accessibilityHidden(true)

            Text("TuCuatro Chords")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(cream)

            Spacer()
        }
        .accessibilityElement(children: .combine)
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
                    .opacity(instrumentPresentationOpacity)

                Text(instrumentDisplayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(cream)
                    .lineLimit(1)
                    .opacity(instrumentPresentationOpacity)

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
        .overlay(alignment: .trailing) {
            if instrumentHandoffVisible && !reduceMotion {
                InstrumentHandoffTrace(progress: instrumentHandoffProgress)
                    .frame(width: 96, height: 28)
                    .padding(.trailing, 34)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
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
            return "Chord library available offline"
        case .checking:
            return "Checking for updates"
        case .current:
            return "Library current"
        case .updated:
            return "Library updated"
        case .offline:
            return "Chord library available offline"
        case .failed:
            return "Chord library available offline"
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

    @MainActor
    private func runLaunchExpression() async {
        if reduceMotion {
            launchTraceOpacity = 0
            withAnimation(.linear(duration: 0.12)) {
                launchCurtainOpacity = 0
            }
            try? await Task.sleep(nanoseconds: 120_000_000)
            launchExpressionComplete = true
            return
        }

        withAnimation(.timingCurve(0.22, 1.0, 0.36, 1.0, duration: 0.70)) {
            launchTraceProgress = 1
        }

        try? await Task.sleep(nanoseconds: 400_000_000)

        withAnimation(.timingCurve(0.22, 1.0, 0.36, 1.0, duration: 0.22)) {
            launchCurtainOpacity = 0
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        withAnimation(.linear(duration: 0.20)) {
            launchTraceOpacity = 0
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        launchExpressionComplete = true
    }

    private func triggerInstrumentHandoff() {
        instrumentHandoffGeneration += 1
        let generation = instrumentHandoffGeneration

        if reduceMotion {
            withAnimation(nil) {
                instrumentHandoffVisible = false
                instrumentHandoffProgress = 0
                instrumentPresentationOpacity = 0.72
            }
            withAnimation(.linear(duration: 0.08)) {
                instrumentPresentationOpacity = 1
            }
            return
        }

        withAnimation(nil) {
            instrumentHandoffVisible = true
            instrumentHandoffProgress = 0
            instrumentPresentationOpacity = 0.55
        }

        withAnimation(.linear(duration: 0.18)) {
            instrumentHandoffProgress = 1
        }

        withAnimation(.linear(duration: 0.12)) {
            instrumentPresentationOpacity = 1
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 230_000_000)
            guard generation == instrumentHandoffGeneration else { return }
            instrumentHandoffVisible = false
            instrumentHandoffProgress = 0
        }
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


private struct LivingCuatroLaunchOverlay: View {
    let progress: CGFloat
    let curtainOpacity: Double
    let traceOpacity: Double
    let reduceMotion: Bool

    private let warmBlack = Color(red: 18 / 255, green: 17 / 255, blue: 15 / 255)
    private let traceCream = Color(red: 242 / 255, green: 231 / 255, blue: 206 / 255)
    private let traceMuted = Color(red: 141 / 255, green: 133 / 255, blue: 123 / 255)

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let width = size.width
            let height = size.height

            ZStack {
                warmBlack
                    .opacity(curtainOpacity)

                if !reduceMotion {
                    ZStack {
                        ForEach(0..<4, id: \.self) { index in
                            let startX = CGFloat([0.323, 0.428, 0.533, 0.638][index]) * width
                            let endX = CGFloat([0.385, 0.464, 0.544, 0.623][index]) * width
                            let start = CGFloat([0.03, 0.07, 0.11, 0.16][index])
                            let end = CGFloat([0.38, 0.42, 0.46, 0.50][index])
                            Path { path in
                                path.move(to: CGPoint(x: startX, y: 0.15 * height))
                                path.addLine(to: CGPoint(x: endX, y: 0.64 * height))
                            }
                            .trim(from: 0, to: phase(progress, start, end))
                            .stroke(traceCream.opacity(0.88), style: StrokeStyle(lineWidth: 2.35, lineCap: .round))
                        }

                        let fretOpacity = Double(phase(progress, 0.26, 0.44)) * 0.46
                        ForEach([CGFloat(0.254), 0.305, 0.352, 0.396, 0.437], id: \.self) { normalizedY in
                            Path { path in
                                path.move(to: CGPoint(x: 0.31 * width, y: normalizedY * height))
                                path.addLine(to: CGPoint(x: 0.655 * width, y: normalizedY * height))
                            }
                            .stroke(traceMuted.opacity(fretOpacity), lineWidth: 1.25)
                        }

                        let headstockOpacity = Double(phase(progress, 0.33, 0.49)) * 0.82
                        Group {
                            Circle().position(x: 0.277 * width, y: 0.169 * height)
                            Circle().position(x: 0.267 * width, y: 0.209 * height)
                            Circle().position(x: 0.687 * width, y: 0.169 * height)
                            Circle().position(x: 0.697 * width, y: 0.209 * height)
                        }
                        .frame(width: 9, height: 9)
                        .foregroundStyle(traceCream)
                        .opacity(headstockOpacity)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(traceCream.opacity(0.8), lineWidth: 1.8)
                            .frame(width: 0.364 * width, height: 21)
                            .position(x: 0.479 * width, y: 0.645 * height)
                            .opacity(Double(phase(progress, 0.39, 0.55)))

                        let contactProgress = phase(progress, 0.33, 0.93)
                        Path { path in
                            path.move(to: CGPoint(x: 0.18 * width, y: 0.305 * height))
                            path.addLine(to: CGPoint(x: 0.34 * width, y: 0.305 * height))
                            path.addLine(to: CGPoint(x: 0.533 * width, y: 0.305 * height))
                            path.addLine(to: CGPoint(x: 0.544 * width, y: 0.633 * height))
                            path.addLine(to: CGPoint(x: 0.646 * width, y: 0.645 * height))
                        }
                        .trim(from: 0, to: contactProgress)
                        .stroke(traceCream.opacity(0.72), style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))

                        if contactProgress > 0.01 && contactProgress < 0.99 {
                            Circle()
                                .fill(traceCream)
                                .frame(width: 11, height: 11)
                                .position(contactPoint(progress: contactProgress, size: size))
                        }
                    }
                    .opacity(traceOpacity)
                }
            }
        }
    }

    private func phase(_ value: CGFloat, _ start: CGFloat, _ end: CGFloat) -> CGFloat {
        guard end > start else { return value >= end ? 1 : 0 }
        return min(max((value - start) / (end - start), 0), 1)
    }

    private func contactPoint(progress: CGFloat, size: CGSize) -> CGPoint {
        let width = size.width
        let height = size.height

        if progress < 0.25 {
            let t = progress / 0.25
            return CGPoint(
                x: lerp(0.18 * width, 0.34 * width, t),
                y: 0.305 * height
            )
        }

        if progress < 0.50 {
            let t = (progress - 0.25) / 0.25
            return CGPoint(
                x: lerp(0.34 * width, 0.533 * width, t),
                y: 0.305 * height
            )
        }

        if progress < 0.88 {
            let t = (progress - 0.50) / 0.38
            return CGPoint(
                x: lerp(0.533 * width, 0.544 * width, t),
                y: lerp(0.305 * height, 0.633 * height, t)
            )
        }

        let t = (progress - 0.88) / 0.12
        return CGPoint(
            x: lerp(0.544 * width, 0.646 * width, t),
            y: lerp(0.633 * height, 0.645 * height, t)
        )
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * min(max(t, 0), 1)
    }
}

private struct InstrumentHandoffTrace: View {
    let progress: CGFloat

    private let strokeColor = Color(red: 91 / 255, green: 85 / 255, blue: 78 / 255)
    private let pointColor = Color(red: 242 / 255, green: 231 / 255, blue: 206 / 255)

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let p0 = CGPoint(x: 0, y: size.height * 0.54)
            let p1 = CGPoint(x: size.width * 0.24, y: size.height * 0.08)
            let p2 = CGPoint(x: size.width * 0.58, y: size.height * 0.94)
            let p3 = CGPoint(x: size.width, y: size.height * 0.54)

            Path { path in
                path.move(to: p0)
                path.addCurve(to: p3, control1: p1, control2: p2)
            }
            .trim(from: 0, to: progress)
            .stroke(strokeColor.opacity(fade(progress) * 0.72), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

            if progress > 0.02 && progress < 0.98 {
                Circle()
                    .fill(pointColor)
                    .frame(width: 9, height: 9)
                    .position(cubicPoint(progress: progress, p0: p0, p1: p1, p2: p2, p3: p3))
                    .opacity(fade(progress))
            }
        }
    }

    private func fade(_ progress: CGFloat) -> Double {
        let fadeIn = min(max(progress / 0.12, 0), 1)
        let fadeOut = min(max((1 - progress) / 0.22, 0), 1)
        return Double(min(fadeIn, fadeOut))
    }

    private func cubicPoint(progress: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let t = min(max(progress, 0), 1)
        let oneMinusT = 1 - t
        let x = oneMinusT * oneMinusT * oneMinusT * p0.x
            + 3 * oneMinusT * oneMinusT * t * p1.x
            + 3 * oneMinusT * t * t * p2.x
            + t * t * t * p3.x
        let y = oneMinusT * oneMinusT * oneMinusT * p0.y
            + 3 * oneMinusT * oneMinusT * t * p1.y
            + 3 * oneMinusT * t * t * p2.y
            + t * t * t * p3.y
        return CGPoint(x: x, y: y)
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
