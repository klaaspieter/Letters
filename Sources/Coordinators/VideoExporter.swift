import AVFoundation
import Foundation
import Result

public class VideoExporter {

  private let cameraVideoURL: URL
  private let screenVideoURL: URL
  private let outputURL: URL

  private let composition: AVMutableComposition

  public init(
    cameraVideoURL: URL,
    screenVideoURL: URL,
    outputURL: URL,
    composition: AVMutableComposition = AVMutableComposition()
  ) {
    self.cameraVideoURL = cameraVideoURL
    self.screenVideoURL = screenVideoURL
    self.outputURL = outputURL
    self.composition = composition
  }

  public func export(completion: @escaping (Result<Void, ExportError>) -> Void) {
    let cameraAsset = AVURLAsset(url: cameraVideoURL)
    let screenAsset = AVURLAsset(url: screenVideoURL)

    guard cameraAsset.isComposable else {
      completion(.failure(.invalidCameraVideoURL))
      return
    }

    guard screenAsset.isComposable else {
      completion(.failure(.invalidScreenVideoURL))
      return
    }

    let cameraTrack = composition.addMutableTrack(
      withMediaType: AVMediaTypeVideo,
      preferredTrackID: kCMPersistentTrackID_Invalid
    )

    guard let cameraVideoTrack = cameraAsset.tracks(withMediaType: AVMediaTypeVideo).first else {
      completion(.failure(.missingCameraVideo(at: cameraVideoURL)))
      return
    }

    guard let cameraAudioTrack = cameraAsset.tracks(withMediaType: AVMediaTypeAudio).first else {
      completion(.failure(.missingCameraAudio(at: cameraVideoURL)))
      return
    }

    guard let screenVideoTrack = screenAsset.tracks(withMediaType: AVMediaTypeVideo).first else {
      completion(.failure(.missingScreenVideo(at: screenVideoURL)))
      return
    }

    do {
      try cameraTrack.insertTimeRange(
        CMTimeRangeMake(kCMTimeZero, cameraAsset.duration),
        of: cameraVideoTrack,
        at: kCMTimeZero
      )

      let audioTrack = composition.addMutableTrack(
        withMediaType: AVMediaTypeAudio,
        preferredTrackID: kCMPersistentTrackID_Invalid
      )
      try audioTrack.insertTimeRange(
        CMTimeRangeMake(kCMTimeZero, cameraAsset.duration),
        of: cameraAudioTrack,
        at: kCMTimeZero
      )

      let screenTrack = composition.addMutableTrack(
        withMediaType: AVMediaTypeVideo,
        preferredTrackID: kCMPersistentTrackID_Invalid

      )
      try screenTrack.insertTimeRange(
        CMTimeRangeMake(kCMTimeZero, screenAsset.duration),
        of: screenVideoTrack,
        at: kCMTimeZero
      )

      let compositionInstruction = AVMutableVideoCompositionInstruction()
      compositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, cameraAsset.duration)

      let renderSize = cameraTrack.naturalSize
      let screenTrackSize = screenTrack.naturalSize

      let screenLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: screenTrack)
      screenLayerInstruction.setTransform(
        CGAffineTransform(
          translationX: (renderSize.width - (screenTrackSize.width * 0.1) - 25),
          y: renderSize.height - (screenTrackSize.height * 0.1) - 25
          ).scaledBy(x: 0.1, y: 0.1),
        at: kCMTimeZero
      )

      let cameraLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: cameraTrack)
      cameraLayerInstruction.setTransform(
        .identity,
        at: kCMTimeZero
        )

      compositionInstruction.layerInstructions = [screenLayerInstruction, cameraLayerInstruction]

      let videoComposition = AVMutableVideoComposition()
      videoComposition.instructions = [compositionInstruction]
      videoComposition.frameDuration = cameraTrack.minFrameDuration
      videoComposition.renderSize = renderSize

      guard let session = AVAssetExportSession(
        asset: composition,
        presetName: AVAssetExportPresetHighestQuality
      ) else {
          NSLog("Cannot create AVAssetExportSession for composition: \(composition)")
          completion(.failure(.generic))
          return
      }
      session.videoComposition = videoComposition

      session.outputURL = outputURL

      session.outputFileType = AVFileTypeQuickTimeMovie
      session.exportAsynchronously {
        completion(.success())
      }
    } catch (let error) {
      NSLog("Error while exporting video composition: \(error)")
      completion(.failure(.generic))
    }
  }
}
