import SwiftUI

struct ContentView: View {
    private let library = ChordLibrary.prototype
    @State private var position = "1st"

    private var shape: ChordShape {
        library.shape(instrument: "cuatro", chord: "A", position: position)
            ?? ChordShape(encoded: "0.2.3.2")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("A")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                    Text("Cuatro")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                ChordDiagram(shape: shape)
                    .frame(maxWidth: 330, maxHeight: 390)

                Picker("Position", selection: $position) {
                    ForEach(["1st", "2nd", "3rd", "4th", "5th"], id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .pickerStyle(.segmented)

                Text("Native prototype • offline chord data")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(24)
            .navigationTitle("TuCuatro Chords")
        }
    }
}

private struct ChordDiagram: View {
    let shape: ChordShape
    private let visibleFrets = 5

    var body: some View {
        GeometryReader { proxy in
            let left: CGFloat = 42
            let right: CGFloat = 18
            let top: CGFloat = 42
            let bottom: CGFloat = 28
            let width = max(proxy.size.width - left - right, 1)
            let height = max(proxy.size.height - top - bottom, 1)
            let stringCount = max(shape.strings.count, 2)
            let stringSpacing = width / CGFloat(stringCount - 1)
            let fretSpacing = height / CGFloat(visibleFrets)

            ZStack {
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
                    .stroke(.primary, lineWidth: fret == 0 && shape.baseFret == 1 ? 4 : 1)
                }

                if shape.baseFret > 1 {
                    Text("\(shape.baseFret)fr")
                        .font(.caption.bold())
                        .position(x: 18, y: top + fretSpacing / 2)
                }

                ForEach(Array(shape.strings.enumerated()), id: \.offset) { index, state in
                    let x = left + CGFloat(index) * stringSpacing
                    switch state {
                    case .muted:
                        Text("×")
                            .font(.title2.bold())
                            .position(x: x, y: 16)
                    case .fret(0):
                        Circle()
                            .stroke(.primary, lineWidth: 1.5)
                            .frame(width: 12, height: 12)
                            .position(x: x, y: 16)
                    case let .fret(fret):
                        let displayed = shape.displayFret(for: fret)
                        if displayed >= 1 && displayed <= visibleFrets {
                            Circle()
                                .fill(.primary)
                                .frame(width: 24, height: 24)
                                .position(x: x, y: top + (CGFloat(displayed) - 0.5) * fretSpacing)
                        }
                    }
                }
            }
        }
        .aspectRatio(0.78, contentMode: .fit)
        .accessibilityLabel("A chord diagram")
    }
}

#Preview {
    ContentView()
}
