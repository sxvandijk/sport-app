import SwiftUI
import UIKit

enum TabBarStyle {
    /// Tabbalk in de kleuren van het ontwerp: achtergrond `bg`, geen lijn, inactieve tabs in `text3`.
    /// De actieve tab krijgt de accentkleur via `.tint` in `RootView`.
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "bg")
        appearance.shadowColor = .clear

        let unselected = UIColor(named: "text3") ?? .gray
        let font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        let item = appearance.stackedLayoutAppearance
        item.normal.iconColor = unselected
        item.normal.titleTextAttributes = [.foregroundColor: unselected, .font: font]
        item.selected.titleTextAttributes = [.font: font]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
