import UIKit
import CoreData
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Bildirim izni verildi")
            } else {
                print("Bildirim izni reddedildi: \(String(describing: error))")
            }
        }

        UNUserNotificationCenter.current().delegate = self

        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Allarrm")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        DispatchQueue.main.async {
            self.handleNotification(userInfo: userInfo)
        }
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        DispatchQueue.main.async {
            self.handleNotification(userInfo: userInfo)
        }
        completionHandler()
    }

    private func handleNotification(userInfo: [AnyHashable: Any]) {
        guard let etiket = userInfo["etiket"] as? String,
              let saatTimestamp = userInfo["saat"] as? TimeInterval,
              let gunler = userInfo["gunler"] as? [String],
              let erteleme = userInfo["erteleme"] as? Bool,
              let aktif = userInfo["aktif"] as? Bool else {
            return
        }

        let saat = Date(timeIntervalSince1970: saatTimestamp)
        let alarm = Alarm(saat: saat, etiket: etiket, gunler: gunler, erteleme: erteleme, aktif: aktif)

        if let vc = UIApplication.shared.visibleViewController as? mainViewController {
            vc.showAlarmScreen(for: alarm)
        }
    }
}

// MARK: - UIViewController erişimi
extension UIApplication {
    var visibleViewController: UIViewController? {
        guard let root = self.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        return topViewController(root)
    }

    private func topViewController(_ controller: UIViewController) -> UIViewController {
        if let nav = controller as? UINavigationController {
            return topViewController(nav.visibleViewController ?? nav)
        } else if let tab = controller as? UITabBarController {
            return topViewController(tab.selectedViewController ?? tab)
        } else if let presented = controller.presentedViewController {
            return topViewController(presented)
        } else {
            return controller
        }
    }
}
