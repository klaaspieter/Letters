import AVFoundation

struct Compose<First: Composable, Second: Composable> {
  let perform: (First, Second) -> Result<Composition, ComposeError>

    static func add(
      asset: Asset,
      range: CMTimeRange,
      to composition: AVMutableComposition
    ) -> AVMutableCompositionTrack? {
      let track = composition.addMutableTrack(
        withMediaType: asset.mediaType,
        preferredTrackID: .invalid
      )

      do {
        try track?.insertTimeRange(range, of: asset.track, at: .zero)
        return track
      } catch {
        return .none
      }
    }

  static var pictureInPicture: Compose<Movie, Screen> {
    return Compose<Movie, Screen> { movie, screen in
      let videoAssetTrack = movie.videoTrack
      let screenAssetTrack = screen.track
      let duration = videoAssetTrack.timeRange.duration
      let range = CMTimeRange(start: .zero, duration: duration)
      let renderSize = videoAssetTrack.naturalSize

      let composition = AVMutableComposition()

      guard let videoCompositionTrack = add(asset: movie.video, range: range, to: composition) else {
        return .failure(.invalid(asset: .video))
      }

      guard let screenCompositionTrack = add(asset: screen, range: range, to: composition) else {
        return .failure(.invalid(asset: .video))
      }

      guard let _ = add(asset: movie.audio, range: range, to: composition) else {
        return .failure(.invalid(asset: .audio))
      }

      // Make screen recording 20% of render size
      let naturalScreenSize = screenAssetTrack.naturalSize
      let widthRatio = renderSize.width / naturalScreenSize.width
      let heightRatio = renderSize.height / naturalScreenSize.height
      let ratio = min(min(widthRatio, heightRatio), 1)

      let scaleRatio = ratio * 0.2
      let inset = CGSize(width: renderSize.width * 0.01, height: renderSize.height * 0.01)

      let transform = screenAssetTrack.preferredTransform
        .translatedBy(
          x: renderSize.width - inset.width,
          y: renderSize.height - inset.height
        )
        .scaledBy(x: scaleRatio, y: scaleRatio)
        .translatedBy(x: -naturalScreenSize.width, y: -naturalScreenSize.height)

      let screenLayerInstruction = AVMutableVideoCompositionLayerInstruction(
        assetTrack: screenCompositionTrack
      )
      screenLayerInstruction.setTransform(
        transform,
        at: .zero
      )

      let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(
        assetTrack: videoCompositionTrack
      )
      videoLayerInstruction.setTransform(videoAssetTrack.preferredTransform, at: .zero)

      let compositionInstruction = AVMutableVideoCompositionInstruction()
      compositionInstruction.timeRange = CMTimeRange(
        start: .zero,
        duration: duration
      )
      compositionInstruction.layerInstructions = [
        screenLayerInstruction,
        videoLayerInstruction
      ]

      let videoComposition = AVMutableVideoComposition()
      videoComposition.instructions = [compositionInstruction]
      videoComposition.renderSize = renderSize
      videoComposition.frameDuration = videoAssetTrack.minFrameDuration

      return .success(Composition(avAsset: composition, videoComposition: videoComposition))
    }
  }
}
