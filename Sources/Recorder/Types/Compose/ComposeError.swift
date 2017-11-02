import AVFoundation

enum ComposeError: Swift.Error {
  case invalid(asset: AVMediaType)
  case unknown
}
