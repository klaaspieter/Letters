import Cocoa

class ViewController: NSViewController {

  var shouldRecord: Bool = false

  @IBOutlet var textField: NSTextField!
  @IBOutlet var label: NSTextField!

  @IBOutlet var recordButton: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad()

    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.white.cgColor

    shouldRecord = recordButton.state == NSOnState
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    view.window?.makeFirstResponder(textField)
  }

  @IBAction func toggleRecording(_ sender: Any) {
    shouldRecord = recordButton.state == NSOnState
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
