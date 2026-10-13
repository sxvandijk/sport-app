import SwiftUI
import UserNotifications

/// Vangt de knoppen van de creatine-melding op.
final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationHandler()

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == Notifier.takenAction {
            DispatchQueue.main.async { Notifier.onCreatineTaken?() }
        }
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

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
            let model = AppModel(fileURL: AppModel.defaultFileURL())
            UNUserNotificationCenter.current().delegate = NotificationHandler.shared
            Notifier.registerCategories()
            Notifier.onCreatineTaken = { model.markCreaDoneFromNotification() }
            _model = StateObject(wrappedValue: model)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .onAppear { if !LaunchConfig().isScreenshotRun { model.rescheduleCreatine() } }
        }
    }
}
