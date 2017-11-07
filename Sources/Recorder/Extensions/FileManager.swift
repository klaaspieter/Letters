import Foundation

extension FileManager {
  func uniqueTemporaryFile(pathExtension: String? = .none) -> URL {
    var url = temporaryDirectory.appendingPathComponent(
      ProcessInfo.processInfo.globallyUniqueString
    )

    if let pathExtension = pathExtension {
      url = url.appendingPathExtension(pathExtension)
    }

    return url
  }  
}
