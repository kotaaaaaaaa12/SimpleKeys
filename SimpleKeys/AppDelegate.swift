import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        NSSetUncaughtExceptionHandler { exception in
            let crashLog = "\(exception.name.rawValue): \(exception.reason ?? "")\n\n\(exception.callStackSymbols.joined(separator: "\n"))"
            let defaults = UserDefaults(suiteName: "group.com.simplekeys.app")
            defaults?.set(crashLog, forKey: "lastCrashLog")
            defaults?.synchronize()
        }
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
