import Foundation

enum RecorderError: Swift.Error {
  case capturing(CaptureError)
  case composing(ComposeError)
  case exporting(ExportError)
}
