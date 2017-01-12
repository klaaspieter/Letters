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
    NSLog("Start exporting camera: \(cameraVideoURL), screen: \(screenVideoURL)")

    let cameraAsset = AVURLAsset(url: cameraVideoURL)
    let screenAsset = AVURLAsset(url: screenVideoURL)

    let composition = AVMutableComposition()

    let cameraTrack = composition.addMutableTrack(
      withMediaType: AVMediaTypeVideo,
      preferredTrackID: kCMPersistentTrackID_Invalid
    )
    try! cameraTrack.insertTimeRange(
      CMTimeRangeMake(kCMTimeZero, cameraAsset.duration),
      of: cameraAsset.tracks(withMediaType: AVMediaTypeVideo)[0],
      at: kCMTimeZero
    )

    let audioTrack = composition.addMutableTrack(
      withMediaType: AVMediaTypeAudio,
      preferredTrackID: kCMPersistentTrackID_Invalid
    )
    try! audioTrack.insertTimeRange(
      CMTimeRangeMake(kCMTimeZero, cameraAsset.duration),
      of: cameraAsset.tracks(withMediaType: AVMediaTypeAudio)[0],
      at: kCMTimeZero
    )

    let screenTrack = composition.addMutableTrack(
      withMediaType: AVMediaTypeVideo,
      preferredTrackID: kCMPersistentTrackID_Invalid

    )
    try! screenTrack.insertTimeRange(
      CMTimeRangeMake(kCMTimeZero, screenAsset.duration),
      of: screenAsset.tracks(withMediaType: AVMediaTypeVideo)[0],
      at: kCMTimeZero
    )

    let compositionInstruction = AVMutableVideoCompositionInstruction()
    compositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, cameraAsset.duration)

    let renderSize = cameraTrack.naturalSize
    let screenTrackSize = screenTrack.naturalSize

    let screenLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: screenTrack)
    screenLayerInstruction.setTransform(
      CGAffineTransform(
        translationX: (renderSize.width - (screenTrackSize.width * 0.1) - 25),
        y: renderSize.height - (screenTrackSize.height * 0.1) - 25
        ).scaledBy(x: 0.1, y: 0.1),
      at: kCMTimeZero
    )

    let cameraLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: cameraTrack)
    cameraLayerInstruction.setTransform(
      .identity,
      at: kCMTimeZero
    )

    compositionInstruction.layerInstructions = [screenLayerInstruction, cameraLayerInstruction]

    let videoComposition = AVMutableVideoComposition()
    videoComposition.instructions = [compositionInstruction]
    videoComposition.frameDuration = cameraTrack.minFrameDuration
    videoComposition.renderSize = renderSize

    let session = AVAssetExportSession(
      asset: composition,
      presetName: AVAssetExportPresetHighestQuality
      )!
    session.videoComposition = videoComposition

    let fileManager = FileManager.default
    let desktopURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    session.outputURL = desktopURL.appendingPathComponent("export.mov")

    session.outputFileType = AVFileTypeQuickTimeMovie
    session.exportAsynchronously {
      NSLog("Finished exporting to \(session.outputURL)")
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
}
