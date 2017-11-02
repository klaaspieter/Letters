import AVFoundation
import Foundation

enum CaptureError: Swift.Error {
  case invalidOutputURL(URL)
  case missingInput
  case missingOutput

  case invalidAsset

  case fileAlreadyExists
  case diskFull
  case outOfMemory
  case noDataCaptured

  case unknown(AVError.Code)
}
