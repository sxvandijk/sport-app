import SwiftUI

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
    @EnvironmentObject private var model: AppModel

    var body: some View {
        // `preferredColorScheme` staat hier, buiten `ThemedRoot`, zodat `ThemedRoot` het effectieve schema ziet.
        ThemedRoot()
            .preferredColorScheme(model.themeMode.preferredColorScheme)
    }
}

private struct ThemedRoot: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let accent = AccentColors.make(accent: model.accent, scheme: colorScheme)
        ZStack {
            Tokens.bg.ignoresSafeArea()
            switch model.screen {
            case .home: HomeContainer()
            case .workout: WorkoutScreen()
            case .overview: OverviewScreen()
            case .editor: EditorScreen()
            case .summary: SummaryScreen()
            case .records: RecordsScreen()
            }
            SheetOverlay()
            ConfirmOverlay()
            NameOverlay()
        }
        .tint(accent.accentText)
        .environment(\.accentColors, accent)
    }
}
