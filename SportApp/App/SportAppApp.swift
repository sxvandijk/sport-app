import SwiftUI

@main
struct SportAppApp: App {
    @StateObject private var model: AppModel

    init() {
        let config = LaunchConfig()
        if config.isScreenshotRun {
            // Voor screenshots: voorbeelddata in het geheugen, zodat elke run hetzelfde laat zien en niets wordt bewaard.
            let model = AppModel(fileURL: nil)
            config.apply(to: model)
            _model = StateObject(wrappedValue: model)
        } else {
            _model = StateObject(wrappedValue: AppModel(fileURL: AppModel.defaultFileURL()))
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
    }
}
