import AVFoundation
import Cocoa

class ViewController: NSViewController {

  let captureSession = AVCaptureSession()

  @IBOutlet var textField: NSTextField!
  @IBOutlet var label: NSTextField!
  @IBOutlet var previewView: CaptureVideoPreviewView!

  @IBOutlet var recordButton: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad()

    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.white.cgColor

    captureSession.sessionPreset = AVCaptureSessionPresetHigh
    if let videoCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo),
      let videoCaptureInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
      captureSession.canAddInput(videoCaptureInput) {
      captureSession.addInput(videoCaptureInput)

      previewView.session = captureSession
    } else {
      recordButton.isHidden = true
      previewView.isHidden = true
    }
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    view.window?.makeFirstResponder(textField)
  }

  @IBAction func toggleRecording(_ sender: Any) {
    switch recordButton.state {
    case NSOnState:
      beginRecording()
    default:
      endRecording()
    }
  }

  func beginRecording() {
    DispatchQueue.global().async {
      self.captureSession.startRunning()

      DispatchQueue.main.async {
        self.previewView.isHidden = false
      }
    }
  }

  func endRecording() {
    self.captureSession.stopRunning()
    previewView.isHidden = true
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
