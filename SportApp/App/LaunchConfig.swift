import Foundation

/// Launch-argumenten waarmee CI schermen kan fotograferen, bijvoorbeeld:
/// `-screenshotTab 2 -screenshotAppearance dark -screenshotAccent viola`.
/// Zonder `-screenshotTab` gedraagt de app zich gewoon.
struct LaunchConfig {
    var tab: AppTab?
    var appearance: AppearanceMode?
    var accent: AccentID?

    var isScreenshotRun: Bool { tab != nil }

    init(defaults: UserDefaults = .standard) {
        if defaults.object(forKey: "screenshotTab") != nil {
            tab = AppTab(rawValue: defaults.integer(forKey: "screenshotTab"))
        }
        appearance = defaults.string(forKey: "screenshotAppearance").flatMap(AppearanceMode.init(rawValue:))
        accent = defaults.string(forKey: "screenshotAccent").flatMap(AccentID.init(rawValue:))
    }
}
