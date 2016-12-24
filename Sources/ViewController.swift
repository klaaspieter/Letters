import Cocoa

class ViewController: NSViewController {

  @IBOutlet var textField: NSTextField!
  @IBOutlet var label: NSTextField!

  override func viewDidLoad() {
    super.viewDidLoad()

    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.white.cgColor
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    view.window?.makeFirstResponder(textField)
  }
}

extension ViewController: NSTextFieldDelegate {
  override func controlTextDidChange(_ notification: Notification) {
    let text = textField.stringValue
    label.stringValue = text
    textField.stringValue = ""
  }

  func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
    return false
  }
}
