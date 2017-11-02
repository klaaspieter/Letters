import AVFoundation

class Session {
  private let captureSession: AVCaptureSession

  private let devices: [Device]

  private let outputURL: URL

  var didStart: (() -> Void)?

  var didFinish: ((Result<AVAsset, CaptureError>) -> Void)?

  private let queue: DispatchQueue = DispatchQueue(label: "me.annema.recorder.session")

  private let fileOutput = AVCaptureMovieFileOutput()

  private var fileRecordingDelegate: FileRecordingDelegate?

  var isRunning: Bool {
    return captureSession.isRunning
  }

  init(devices: [Device]) {
    self.captureSession = AVCaptureSession(preset: .high)
    self.devices = devices
    self.outputURL = FileManager.default.uniqueTemporaryFile(pathExtension: "mov")
  }

  func start() {
    let addDevice = flip(curry(add(device:to:)))(captureSession)
    guard devices.map(addDevice).reduce(true, { $0 && $1 }) else {
      self.finish(with: .failure(.missingInput))
      return
    }

    guard add(output: fileOutput, to: captureSession) else {
      self.finish(with: .failure(.missingOutput))
      return
    }

    queue.async(execute: {
      self.captureSession.startRunning()

      let fileRecordingDelegate = FileRecordingDelegate(session: self)
      self.fileOutput.startRecording(to: self.outputURL, recordingDelegate: fileRecordingDelegate)
      self.fileRecordingDelegate = fileRecordingDelegate
    })
  }

  func stop() {
    fileOutput.stopRecording()
  }

  fileprivate func didStartRecording() {
    didStart?()
  }

  fileprivate func finish(with result: Result<AVAsset, CaptureError>) {
    let didFinish = {
      DispatchQueue.main.async(execute: {
        self.didFinish?(result)
      })
    }

    queue.async {
      self.captureSession.stopRunning()
      didFinish()
    }
  }

  private func add(device: Device, to session: AVCaptureSession) -> Bool {
    guard let avInput = device.avInput, session.canAddInput(avInput) else {
      return false
    }
    session.addInput(avInput)
    return true
  }

  private func add(output: AVCaptureOutput, to session: AVCaptureSession) -> Bool {
    guard session.canAddOutput(output) else { return false }
    session.addOutput(output)
    return true
  }
}

private class FileRecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
  unowned let session: Session

  init(session: Session) {
    self.session = session
  }

  func fileOutput(
    _ output: AVCaptureFileOutput,
    didStartRecordingTo fileURL: URL,
    from connections: [AVCaptureConnection]
  ) {
    DispatchQueue.main.async {
      self.session.didStartRecording()
    }
  }

  func fileOutput(
    _ output: AVCaptureFileOutput,
    didFinishRecordingTo outputFileURL: URL,
    from connections: [AVCaptureConnection],
    error: Swift.Error?
    ) {
    NSLog("did finish recording to: \(outputFileURL)")

    let captureError: CaptureError? = error.map({
      ($0 as? AVError) ?? AVError(.unknown)
    })?.captureError

    let result = (Result.init(error:) <^> captureError)
      ?? .success(AVAsset(url: outputFileURL))


    DispatchQueue.main.async {
      self.session.finish(with: result)
    }
  }
}
