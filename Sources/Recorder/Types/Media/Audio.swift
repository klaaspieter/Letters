import AVFoundation

struct Audio: Asset {
  let avAsset: AVAsset

  let track: AVAssetTrack

  var mediaType: AVMediaType {
    return .audio
  }

  init?(avAsset: AVAsset) {
    guard let track = avAsset.tracks(withMediaType: .audio).first else {
      return nil
    }
    self.track = track
    self.avAsset = avAsset
  }
}
