import AVFoundation
import Cocoa

class ViewController: NSViewController {

  var cameraSession: AVCaptureSession?
  let cameraOutput = AVCaptureMovieFileOutput()
  var cameraVideoURL: URL?

  var screenSession:  AVCaptureSession?
  let screenInput = AVCaptureScreenInput(displayID: CGMainDisplayID())
  let screenOutput = AVCaptureMovieFileOutput()
  var screenVideoURL: URL?

  var activeExporter: VideoExporter?

  @IBOutlet var captureField: NSTextField!
  @IBOutlet var label: NSTextField!

  @IBOutlet var recordButton: NSButton!
  @IBOutlet var activityIndicator: NSProgressIndicator!

  let fileManager = FileManager.default

  func showActivity() {
    recordButton.alphaValue = 0.0
    activityIndicator.startAnimation(.none)
  }

  func hideActivity() {
    recordButton.alphaValue = 1.0
    activityIndicator.stopAnimation(.none)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    captureField.alphaValue = 0.0
    view.window?.makeFirstResponder(captureField)

    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.white.cgColor

    cameraSession = makeCameraSession()
    screenSession = makeScreenSession()

    if cameraSession == nil || screenSession == nil {
      recordButton.isHidden = true
    }
    activityIndicator.alphaValue = 0.3
  }

  private func makeDefaultSession(
    withMovieOutput output: AVCaptureMovieFileOutput
  ) -> AVCaptureSession? {
    let session = AVCaptureSession()
    session.sessionPreset = AVCaptureSessionPresetHigh

    guard session.canAddOutput(output) else { return .none }
    session.addOutput(output)

    return session
  }

  private func makeCameraSession() -> AVCaptureSession? {
    guard let session = makeDefaultSession(withMovieOutput: cameraOutput) else {
      return .none
    }

    guard let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo),
      let cameraInput = try? AVCaptureDeviceInput(device: camera),
      session.canAddInput(cameraInput)
    else {
      return .none
    }

    guard
      let microphone = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio),
      let microphoneInput = try? AVCaptureDeviceInput(device: microphone),
      session.canAddInput(microphoneInput)
    else {
      return .none
    }

    session.addInput(cameraInput)
    session.addInput(microphoneInput)

    return session
  }

  private func makeScreenSession() -> AVCaptureSession? {
    guard let session = makeDefaultSession(withMovieOutput: screenOutput) else {
      return .none
    }

    guard let screenInput = screenInput,
      session.canAddInput(screenInput)
    else {
      return .none
    }

    session.addInput(screenInput)

    return session
  }

  @IBAction func toggleRecording(_ sender: Any) {
    switch recordButton.state {
    case NSOnState:
      beginRecording()
    default:
      endRecording()
    }
  }

  func makeTemporaryURL() -> URL? {
    let directoryURL = fileManager.temporaryDirectory.appendingPathComponent("me.annema.letters")
    do {
      try self.fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true,
        attributes: .none
      )
    } catch {
      return .none
    }

    return directoryURL
      .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
      .appendingPathExtension("mov")
  }

  func beginRecording() {
    showActivity()

    DispatchQueue.global().async {
      self.cameraSession?.startRunning()
      self.screenSession?.startRunning()

      DispatchQueue.main.async {
        if let window = self.view.window {
          self.screenInput?.cropRect = window.frame
        }

        self.cameraOutput.startRecording(
          toOutputFileURL: self.makeTemporaryURL(),
          recordingDelegate: self
        )

        self.screenOutput.startRecording(
          toOutputFileURL: self.makeTemporaryURL(),
          recordingDelegate: self
        )

        self.hideActivity()
      }
    }
  }

  func endRecording() {
    cameraOutput.stopRecording()
    screenOutput.stopRecording()

    DispatchQueue.global().async {
      self.cameraSession?.stopRunning()
      self.screenSession?.stopRunning()
    }
  }

  fileprivate func safeVideo(cameraVideoURL: URL, screenVideoURL: URL) {
    showActivity()
    NSLog("Start exporting camera: \(cameraVideoURL), screen: \(screenVideoURL)")

    precondition(activeExporter == nil, "An export is already in progress.")

    let savePanel = NSSavePanel()
    savePanel.allowedFileTypes = ["mov"]
    savePanel.allowsOtherFileTypes = false
    savePanel.nameFieldStringValue = "Untitled.mov"
    savePanel.beginSheetModal(for: self.view.window!) { [unowned self] result in
      guard let saveURL = savePanel.url,
        result == NSFileHandlingPanelOKButton else {
          self.activeExporter = .none
          return
      }

      self.activeExporter = VideoExporter(
        cameraVideoURL: cameraVideoURL,
        screenVideoURL: screenVideoURL,
        outputURL: saveURL
      )
      self.activeExporter?.export { [unowned self] in
        self.activeExporter = .none
        self.hideActivity()
      }
    }
  }
}

extension ViewController: AVCaptureFileOutputRecordingDelegate {
  func capture(
    _ captureOutput: AVCaptureFileOutput!,
    didFinishRecordingToOutputFileAt outputFileURL: URL!,
    fromConnections connections: [Any]!,
    error: Error!
  ) {
    NSLog("Did finish recording: \(outputFileURL)")

    if captureOutput == cameraOutput {
      cameraVideoURL = outputFileURL
    } else if captureOutput == screenOutput {
      screenVideoURL = outputFileURL
    }

    guard let cameraVideoURL = cameraVideoURL,
      let screenVideoURL = screenVideoURL else {
        return
    }

    DispatchQueue.main.async {
      self.safeVideo(cameraVideoURL: cameraVideoURL, screenVideoURL: screenVideoURL)

      // Reset the view controller state so that recording
      // again won't render a movie with data from the previous recording.
      self.cameraVideoURL = .none
      self.screenVideoURL = .none
    }
  }
}

extension ViewController: NSTextFieldDelegate {
  override func controlTextDidChange(_ obj: Notification) {
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
