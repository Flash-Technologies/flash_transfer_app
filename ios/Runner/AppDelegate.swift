import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(
      name: "com.flash_transfer_app.wallet_channel",
      binaryMessenger: controller.binaryMessenger)
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Check if launched from URL
    if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
      return handleURL(url: url)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle URL scheme openings (deep links from wallet apps)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return handleURL(url: url)
  }
  
  // Handle universal links
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    // Handle Universal Links
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      return handleURL(url: url)
    }
    return false
  }
  
  // Common URL handling logic
  private func handleURL(url: URL) -> Bool {
    NSLog("Received URL: \(url.absoluteString)")
    
    // Log parameters for debugging
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
       let queryItems = components.queryItems {
      for item in queryItems {
        NSLog("Query param: \(item.name) = \(item.value ?? "nil")")
      }
    }
    
    // Pass to Flutter via method channel
    methodChannel?.invokeMethod("handleDeepLink", arguments: url.absoluteString)
    
    return true
  }
}
