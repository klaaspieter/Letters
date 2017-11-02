import AVFoundation

struct Screen: Asset {
  let avAsset: AVAsset
  let track: AVAssetTrack

  var mediaType: AVMediaType {
    return .video
  }

  init?(avAsset: AVAsset) {
    guard let track = avAsset.tracks(withMediaType: .video).first else {
      return nil
    }
    self.track = track
    self.avAsset = avAsset
  }
}

