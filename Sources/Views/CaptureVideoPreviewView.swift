import AVFoundation
import Cocoa

class CaptureVideoPreviewView: NSView {
  lazy var captureLayer: AVCaptureVideoPreviewLayer = {
    let captureLayer = AVCaptureVideoPreviewLayer()
    captureLayer.frame = self.bounds
    captureLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    self.wantsLayer = true
    self.layer = captureLayer
    return captureLayer
  }()

  var session: AVCaptureSession {
    get {
      return captureLayer.session!
    }
    set {
      captureLayer.session = newValue
    }
  }

  override func setBoundsOrigin(_ newOrigin: NSPoint) {
    super.setBoundsOrigin(newOrigin)
    captureLayer.frame = bounds
  }

  override func setBoundsSize(_ newSize: NSSize) {
    super.setFrameSize(newSize)
    captureLayer.frame = bounds
  }
}
