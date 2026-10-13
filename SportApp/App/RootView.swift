import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case training, progress, gym, profile

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .training: return "Training"
        case .progress: return "Progressie"
        case .gym: return "Gym"
        case .profile: return "Profiel"
        }
    }

    var systemImage: String {
        switch self {
        case .training: return "dumbbell.fill"
        case .progress: return "chart.bar.fill"
        case .gym: return "mappin.circle.fill"
        case .profile: return "person.fill"
        }
    }
}

/// Zet de gekozen modus (Systeem, Donker, Licht) om in `preferredColorScheme`.
extension AppearanceMode {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: WorkoutStore
    let initialTab: AppTab

    var body: some View {
        // `preferredColorScheme` staat hier, buiten `ThemedTabs`, zodat `ThemedTabs` het effectieve schema ziet.
        ThemedTabs(initialTab: initialTab)
            .preferredColorScheme(store.settings.appearance.preferredColorScheme)
    }
}

private struct ThemedTabs: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var selection: AppTab

    init(initialTab: AppTab) {
        _selection = State(initialValue: initialTab)
    }

    var body: some View {
        let accent = AccentColors.make(accent: store.settings.accentID, scheme: colorScheme)

        TabView(selection: $selection) {
            ForEach(AppTab.allCases) { tab in
                PlaceholderScreen(tab: tab)
                    .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                    .tag(tab)
            }
        }
        .tint(accent.accentText)
        .environment(\.accentColors, accent)
    }
}
