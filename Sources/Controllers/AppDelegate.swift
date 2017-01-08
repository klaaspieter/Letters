import Cocoa
import HockeySDK

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    let hockeyManager = BITHockeyManager.shared()
    hockeyManager?.configure(withIdentifier: "69db64481b22481491f9cbb70188520e")
    hockeyManager?.crashManager.isAutoSubmitCrashReport = true
    hockeyManager?.start()
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}

