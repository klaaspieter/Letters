import AVFoundation

enum CompositionError: Swift.Error {
  case invalid(asset: AVMediaType)
  case unknown
}
