public enum ExportError: Error {
  case invalidCameraVideoURL
  case invalidScreenVideoURL
  case generic
}

public func == (lhs: ExportError, rhs: ExportError) -> Bool {
  switch (lhs, rhs) {
  case (.invalidCameraVideoURL, .invalidCameraVideoURL): return true
  case (.invalidScreenVideoURL, .invalidScreenVideoURL): return true
  case (.generic, .generic): return true
  case (.invalidCameraVideoURL, _),
       (.invalidScreenVideoURL, _),
       (.generic, _):
       return false
  }
}

extension ExportError: Equatable {}
