import UIKit
import Flutter
import WidgetKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.yourname.expenses/widget",
                                       binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler { (call, result) in
      if call.method == "updateWidgetData" {
        if let args = call.arguments as? [String: Any],
           let spent = args["spent"] as? Double,
           let remaining = args["remaining"] as? Double {
            
            if let defaults = UserDefaults(suiteName: "group.com.yourname.expenses") {
                defaults.set(spent, forKey: "spentToday")
                defaults.set(remaining, forKey: "remaining")
                
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            result("Success")
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
