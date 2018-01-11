import AVFoundation

protocol Asset {
  var track: AVAssetTrack { get }

  var mediaType: AVMediaType { get }

  var avAsset: AVAsset { get }

  var duration: CMTime { get }
}

extension Asset {
  var duration: CMTime {
    return avAsset.duration
  }
}
