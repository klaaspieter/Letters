import Foundation

public enum ExportError: Error {
  case invalidCameraVideoURL
  case invalidScreenVideoURL
  case missingScreenVideo(at: URL)
  case missingCameraVideo(at: URL)
  case generic
}

public func == (lhs: ExportError, rhs: ExportError) -> Bool {
  switch (lhs, rhs) {
  case (.invalidCameraVideoURL, .invalidCameraVideoURL): return true
  case (.invalidScreenVideoURL, .invalidScreenVideoURL): return true
  case (.generic, .generic): return true
  case (.missingScreenVideo, .missingScreenVideo): return true
  case (.missingCameraVideo, .missingCameraVideo): return true
  case (.invalidCameraVideoURL, _),
       (.invalidScreenVideoURL, _),
       (.missingScreenVideo, _),
       (.missingCameraVideo, _),
       (.generic, _):
       return false
  }
}

extension ExportError: Equatable {}
