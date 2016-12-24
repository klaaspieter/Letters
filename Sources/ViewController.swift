import AVFoundation
import Cocoa

class ViewController: NSViewController {

  let videoCaptureSession = AVCaptureSession()
  let screenCaptureSession = AVCaptureSession()
  let movieOutput = AVCaptureMovieFileOutput()
  let screenInput = AVCaptureScreenInput(displayID: CGMainDisplayID())

  @IBOutlet var textField: NSTextField!
  @IBOutlet var label: NSTextField!
  @IBOutlet var previewView: CaptureVideoPreviewView!

  @IBOutlet var recordButton: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad()

    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.white.cgColor

    if !configureVideoCaptureSession() || !configureScreenCaptureSession() {
      recordButton.isHidden = true
      previewView.isHidden = true
    }
  }

  private func configureVideoCaptureSession() -> Bool {
    videoCaptureSession.sessionPreset = AVCaptureSessionPresetHigh
    guard let videoCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo),
      let videoCaptureInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
      videoCaptureSession.canAddInput(videoCaptureInput)
    else {
      return false
    }

    videoCaptureSession.addInput(videoCaptureInput)

    return true
  }

  private func configureScreenCaptureSession() -> Bool {
    screenCaptureSession.sessionPreset = AVCaptureSessionPresetHigh

    guard let screenInput = screenInput,
      screenCaptureSession.canAddInput(screenInput),
      screenCaptureSession.canAddOutput(movieOutput)
    else {
      return false
    }

    screenCaptureSession.addInput(screenInput)
    screenCaptureSession.addOutput(movieOutput)

    return true
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
      self.videoCaptureSession.startRunning()
      self.screenCaptureSession.startRunning()

      DispatchQueue.main.async {
        self.previewView.session = self.videoCaptureSession
        if let window = self.view.window {
          self.screenInput?.cropRect = window.frame
        }

        self.previewView.isHidden = false

        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
          "Desktop/\(Date().timeIntervalSinceReferenceDate).mov"
        )
        self.movieOutput.startRecording(toOutputFileURL: url, recordingDelegate: self)
      }
    }
  }

  func endRecording() {
    self.videoCaptureSession.stopRunning()
    self.screenCaptureSession.stopRunning()
    movieOutput.stopRecording()
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

extension ViewController: AVCaptureFileOutputRecordingDelegate {
  func capture(
    _ captureOutput: AVCaptureFileOutput!,
    didFinishRecordingToOutputFileAt outputFileURL: URL!,
    fromConnections connections: [Any]!,
    error: Error!
  ) {
    print("DONE")
  }
}
