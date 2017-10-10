import Cocoa

class WindowController: NSWindowController {
  override func windowDidLoad() {
    super.windowDidLoad()

    NSWindow.allowsAutomaticWindowTabbing = false

    window?.backgroundColor = .white
    window?.setFrameAutosaveName(NSWindow.FrameAutosaveName(rawValue: "Window"))
  }
}
