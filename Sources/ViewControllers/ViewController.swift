import AVFoundation
import Cocoa

class ViewController: NSViewController {

  @IBOutlet var captureField: NSTextField!
  @IBOutlet var label: NSTextField!

  @IBOutlet var recordButton: NSButton!
  @IBOutlet var activityIndicator: NSProgressIndicator!

  @IBOutlet var placeholderLabel: NSTextField!

  var recorder: Recorder!

  override func viewDidLoad() {
    super.viewDidLoad()

    recorder = Recorder(screenRect: view.window?.frame)
    recorder.delegate = self

    captureField.alphaValue = 0.0
    view.window?.makeFirstResponder(captureField)

    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.white.cgColor

    activityIndicator.alphaValue = 0.3
  }

  @IBAction func toggleRecording(_ sender: Any) {
    switch recordButton.state {
    case .on:
      beginRecording()
    case .off, .mixed, _:
      endRecording()
    }
  }

  private func beginRecording() {
    showActivity()

    recorder.start()
  }

  private func endRecording() {
    showActivity()

    recorder.stop()
  }


  private func showActivity() {
    recordButton.alphaValue = 0.0
    activityIndicator.startAnimation(.none)
  }

  private func hideActivity() {
    activityIndicator.stopAnimation(.none)
    recordButton.alphaValue = 1.0
  }
}

extension ViewController: NSTextFieldDelegate {
  override func controlTextDidChange(_ obj: Notification) {
    placeholderLabel.isHidden = true
    label.stringValue = captureField.stringValue
    captureField.stringValue = ""
  }

  override func controlTextDidEndEditing(_ obj: Notification) {
    DispatchQueue.main.async { [weak self] in
      guard let `self` = self else { return }
      self.captureField.window?.makeFirstResponder(self.captureField)
    }
  }
}

extension ViewController: RecorderDelegate {
  func didStart(recorder: Recorder) {
    hideActivity()
  }

  func didFinish(with recording: Result<Recording, CaptureError>, in recorder: Recorder) {
    NSLog("did finish: \(recording)")
    hideActivity()
  }
}
