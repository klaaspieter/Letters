import Cocoa

class WindowController: NSWindowController {
  override func windowDidLoad() {
    super.windowDidLoad()

    window?.backgroundColor = .white
    window?.setFrameAutosaveName("Window")
  }
}
