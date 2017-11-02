import AVFoundation
import Foundation

public struct Export {
  let session: AVAssetExportSession

  private init(
    session: AVAssetExportSession,
    outputURL: URL,
    videoComposition: AVVideoComposition?
  ) {
    session.outputURL = outputURL
    session.outputFileType = .mov
    session.videoComposition = videoComposition
    self.session = session
  }

  func perform(completion: @escaping (Result<AVAsset, ExportError>) -> Void) {
    session.exportAsynchronously {
      if let error = self.session.error {
        NSLog("failed to export: \(error)")
        completion(.failure(.unknown))
      } else {
        completion(.success(self.session.asset))
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
