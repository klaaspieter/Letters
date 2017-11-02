import AVFoundation
import Foundation

protocol RecorderDelegate: class {
  func didStart(recorder: Recorder)

  func didFinish(with recording: Result<Recording, CaptureError>, in recorder: Recorder)
}

class Recorder {
  private let fileOutput: AVCaptureFileOutput

  private let videoSession: Session
  private let screenSession: Session

  weak var delegate: RecorderDelegate?

  var isRecording: Bool {
    return videoSession.isRunning || screenSession.isRunning
  }

  init?(screenRect: CGRect?) {
    self.fileOutput = AVCaptureMovieFileOutput()

    self.videoSession = Session(devices: [.camera, .microphone])

    if let screenRect = screenRect {
      self.screenSession = Session(devices: [.screen(cropRect: screenRect)])
    } else {
      self.screenSession = Session(devices: [.screen])
    }
  }

  func start() {
    (tuple
      <^> Parallel<Void>({ self.videoSession.didStart = $0 })
      <*> Parallel<Void>({ self.screenSession.didStart = $0 })
    ).run({ _ in
      self.didStart()
    })

    (tuple
      <^> Parallel<Result<AVAsset, CaptureError>>({ self.videoSession.didFinish = $0 })
      <*> Parallel<Result<AVAsset, CaptureError>>({ self.screenSession.didFinish = $0 })
    ).run({
      self.didFinish(movie: $0.0, screen: $0.1)
    })

    [videoSession, screenSession].forEach({ $0.start() })
  }

  func stop() {
    [videoSession, screenSession].forEach({ $0.stop() })
  }

  fileprivate func didStart() {
    delegate?.didStart(recorder: self)
  }

  fileprivate func didFinish(
    movie: Result<AVAsset, CaptureError>,
    screen: Result<AVAsset, CaptureError>
  ) {
    let movie = (curry(Movie.init) <^> movie) -<< asResult(failingWith: .invalidAsset)
    let screen = (curry(Screen.init) <^> screen) -<< asResult(failingWith: .invalidAsset)
    let recording = curry(Recording.init) <^> movie <*> screen
    delegate?.didFinish(with: recording, in: self)
  }
}
