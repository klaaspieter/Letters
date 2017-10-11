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

  @IBOutlet var placeholderLabel: NSTextField!

  let fileManager = FileManager.default

  func showActivity() {
    recordButton.alphaValue = 0.0
    activityIndicator.startAnimation(.none)
  }

  func hideActivity() {
    activityIndicator.stopAnimation(.none)
    recordButton.alphaValue = 1.0
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
    session.sessionPreset = AVCaptureSession.Preset.high

    guard session.canAddOutput(output) else { return .none }
    session.addOutput(output)

    return session
  }

  private func makeCameraSession() -> AVCaptureSession? {
    guard let session = makeDefaultSession(withMovieOutput: cameraOutput) else {
      return .none
    }

    guard let camera = AVCaptureDevice.default(for: AVMediaType.video),
      let cameraInput = try? AVCaptureDeviceInput(device: camera),
      session.canAddInput(cameraInput)
    else {
      return .none
    }

    guard
      let microphone = AVCaptureDevice.default(for: AVMediaType.audio),
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

    guard session.canAddInput(screenInput) else {
      return .none
    }

    session.addInput(screenInput)

    return session
  }

  @IBAction func toggleRecording(_ sender: Any) {
    switch recordButton.state {
    case .on:
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
          self.screenInput.cropRect = window.frame
        }

        self.cameraOutput.startRecording(
          to: self.makeTemporaryURL()!,
          recordingDelegate: self
        )

        self.screenOutput.startRecording(
          to: self.makeTemporaryURL()!,
          recordingDelegate: self
        )

        DispatchQueue.main.async {
          self.hideActivity()
        }
      }
    }
  }

  func endRecording() {
    showActivity()

    cameraOutput.stopRecording()
    screenOutput.stopRecording()

    DispatchQueue.global().async {
      self.cameraSession?.stopRunning()
      self.screenSession?.stopRunning()
    }
  }

  fileprivate func safeVideo(cameraVideoURL: URL, screenVideoURL: URL) {
    NSLog("Start exporting camera: \(cameraVideoURL), screen: \(screenVideoURL)")

    precondition(activeExporter == nil, "An export is already in progress.")

    let savePanel = NSSavePanel()
    savePanel.allowedFileTypes = ["mov"]
    savePanel.allowsOtherFileTypes = false
    savePanel.nameFieldStringValue = "Untitled.mov"
    savePanel.beginSheetModal(for: self.view.window!) { [unowned self] result in
      guard let saveURL = savePanel.url,
        result.rawValue == NSFileHandlingPanelOKButton else {
          self.activeExporter = .none
          self.hideActivity()
          return
      }

      // Give the save panel a chance to disappear.
      DispatchQueue.main.async {
        self.export(cameraVideoURL: cameraVideoURL, screenVideoURL: screenVideoURL, to: saveURL)
      }
    }
  }

  fileprivate func export(cameraVideoURL: URL, screenVideoURL: URL, to exportURL: URL) {
    self.activeExporter = VideoExporter(
      cameraVideoURL: cameraVideoURL,
      screenVideoURL: screenVideoURL,
      outputURL: exportURL
    )
    self.activeExporter?.export { [unowned self] result in
      self.activeExporter = .none
      self.hideActivity()

      if let error = result.error {
        NSLog("error: \(error)")

        let alert = NSAlert(
          alert: Alert(
            title: "Your video was not exported",
            recoverySuggestion: "There was a problem exporting your video. Would you like to retry?",
            buttons: ["Retry", "Cancel"]
          )
        )

        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
          DispatchQueue.main.async {
            self.export(cameraVideoURL: cameraVideoURL, screenVideoURL: screenVideoURL, to: exportURL)
          }
        }
      }
    }
  }
}

extension ViewController: AVCaptureFileOutputRecordingDelegate {
  func fileOutput(
    _ captureOutput: AVCaptureFileOutput,
    didFinishRecordingTo outputFileURL: URL,
    from connections: [AVCaptureConnection],
    error: Error?
  ) {
    NSLog("Did finish recording: \(outputFileURL) with error: \(String(describing: error))")

    switch error {
    case .none:
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

    case .some(let error):
      self.hideActivity()

      let alert = self.alert(fromAVError: error as NSError) ?? Alert(
        title: "An unknown error occurred.",
        recoverySuggestion: "Due to an unknown error, your video was not recorded. If this error persists please send an email to letters@annema.me."
      )

      NSAlert(alert: alert).runModal()
    }
  }

  private func alert(fromAVError error: NSError) -> Alert? {
    guard error.domain == AVFoundationErrorDomain else {
      return .none
    }

    switch error.code {
    case AVError.outOfMemory.rawValue:
      return Alert(
        title: "Recording Failed",
        recoverySuggestion: "Your recording didn't finish because your system is out of memory. Quit some apps and try again."
      )
    case AVError.diskFull.rawValue:
      return Alert(
        title: "Recording Failed",
        recoverySuggestion: "Your recording didn't finish because your system is out of disk space. Clear some disk space and try again."
      )
    case AVError.noDataCaptured.rawValue:
      return Alert(title: "Recording Failed", recoverySuggestion: "No data was captured while recording. Please try typing some letters during your next recording.")
    default:
      return .none
    }
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
