import AVFoundation
import Foundation

public struct Export {
  let outputURL: URL
  private let session: AVAssetExportSession

  private init(
    session: AVAssetExportSession,
    outputURL: URL,
    videoComposition: AVVideoComposition?
  ) {
    session.outputURL = outputURL
    session.outputFileType = .mov
    session.videoComposition = videoComposition
    self.outputURL = outputURL
    self.session = session
  }

  func perform(completion: @escaping (Result<Export, ExportError>) -> Void) {
    session.exportAsynchronously {
      if let _ = self.session.error {
        completion(.failure(.unknown))
      } else {
        completion(.success(self))
      }
    }
  }

  static func make(
    composition: Composition,
    outputURL: URL
  ) -> Result<Export, ExportError> {
    guard let session = AVAssetExportSession(
      asset: composition.avAsset,
      presetName: AVAssetExportPresetHighestQuality
    ) else {
        return .failure(.invalidComposition)
    }

    guard outputURL.isFileURL else {
      return .failure(.invalidOutputURL)
    }

    return .success(
      Export(session: session, outputURL: outputURL, videoComposition: composition.videoComposition)
    )
  }
}
