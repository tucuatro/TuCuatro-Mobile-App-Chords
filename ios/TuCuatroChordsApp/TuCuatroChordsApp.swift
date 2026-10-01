import SwiftUI

@main struct TuCuatroChordsApp: App {
    var body: some Scene {
        WindowGroup {
            ChordsSplashGate()
        }
    }
}


private struct ChordsSplashGate: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContentView()

            if showSplash {
                Color(red: 0.071, green: 0.063, blue: 0.051)
                    .ignoresSafeArea()

                Image("TuCuatroMark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .accessibilityHidden(true)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 420_000_000)
            withAnimation(.easeOut(duration: 0.16)) {
                showSplash = false
            }
        }
    }
}
