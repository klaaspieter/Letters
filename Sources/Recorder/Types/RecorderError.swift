import Foundation

enum RecorderError: Swift.Error {
  case capturing(CaptureError)
  case composing(CompositionError)
  case exporting(ExportError)
}
