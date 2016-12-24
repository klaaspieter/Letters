import AVFoundation
import Cocoa

class ViewController: NSViewController {

  let captureSession = AVCaptureSession()
  let movieFileOutput = AVCaptureMovieFileOutput()

  @IBOutlet var textField: NSTextField!
  @IBOutlet var label: NSTextField!

  @IBOutlet var recordButton: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad()

    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.white.cgColor

    captureSession.sessionPreset = AVCaptureSessionPresetHigh
    if let videoCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo),
      let videoCaptureInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
      captureSession.canAddInput(videoCaptureInput),
      captureSession.canAddOutput(movieFileOutput)
    {
      captureSession.addInput(videoCaptureInput)
      captureSession.addOutput(movieFileOutput)

    } else {
        recordButton.isHidden = true
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
      let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/recording.mov")
      self.movieFileOutput.startRecording(toOutputFileURL: url, recordingDelegate: self)
    }
  }

  func endRecording() {
    movieFileOutput.stopRecording()
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

extension ViewController: AVCaptureFileOutputRecordingDelegate {
  public func capture(
    _ captureOutput: AVCaptureFileOutput!,
    didFinishRecordingToOutputFileAt outputFileURL: URL!,
    fromConnections connections: [Any]!,
    error: Error!
  ) {
    print("error: \(error)")
  }

}
