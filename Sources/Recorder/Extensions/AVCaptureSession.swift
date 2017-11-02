import AVFoundation

extension AVCaptureSession {
  convenience init(preset: AVCaptureSession.Preset) {
    self.init()
    self.sessionPreset = preset
  }
}
