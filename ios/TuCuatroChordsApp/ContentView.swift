import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("TuCuatro Chords")
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text("Native SwiftUI is running")
                    .font(.headline)

                Text("Build diagnostic")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(28)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(24)
        }
    }
}

#Preview {
    ContentView()
}
