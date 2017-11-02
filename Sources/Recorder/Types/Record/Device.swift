import AVFoundation

struct Device {
  let configure: () -> AVCaptureInput?

  var avInput: AVCaptureInput? {
    return configure()
  }

  static func avInput(for mediaType: AVMediaType) -> AVCaptureInput? {
    guard let device = AVCaptureDevice.default(for: mediaType) else {
      return .none
    }
    guard let input = try? AVCaptureDeviceInput(device: device) else {
      return .none
    }
    return input
  }

  static var camera: Device {
    return Device {
      avInput(for: .video)
    }
  }

  static var microphone: Device {
    return Device {
      avInput(for: .audio)
    }
  }

  static var screen: Device {
    return Device {
      return AVCaptureScreenInput(displayID: .main)
    }
  }

  static func screen(cropRect: CGRect) -> Device {
    return Device(configure: {
      let screenInput = AVCaptureScreenInput(displayID: .main)
      screenInput.cropRect = cropRect
      return screenInput
    })
  }
}
