import SwiftUI

@main
struct SportAppApp: App {
    @StateObject private var store: WorkoutStore
    private let config: LaunchConfig

    init() {
        let config = LaunchConfig()
        self.config = config

        if config.isScreenshotRun {
            // Voor screenshots: voorbeelddata in het geheugen, zodat elke run hetzelfde laat zien en niets wordt bewaard.
            var seed = MockData.appData()
            if let appearance = config.appearance { seed.settings.appearance = appearance }
            if let accent = config.accent { seed.settings.accentID = accent }
            _store = StateObject(wrappedValue: WorkoutStore(fileURL: nil, seed: seed))
        } else {
            _store = StateObject(wrappedValue: WorkoutStore())
        }
        TabBarStyle.apply()
    }

    var body: some Scene {
        WindowGroup {
            RootView(initialTab: config.tab ?? .training)
                .environmentObject(store)
        }
    }
}
