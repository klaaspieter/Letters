import AVFoundation

protocol Asset {
  var track: AVAssetTrack { get }

  var mediaType: AVMediaType { get }

  var avAsset: AVAsset { get }

  var duration: CMTime { get }

  init?(avAsset: AVAsset)
}

extension Asset {
  var duration: CMTime {
    return avAsset.duration
  }
}
