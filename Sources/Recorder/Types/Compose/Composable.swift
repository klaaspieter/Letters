import AVFoundation

protocol Composable {
  var duration: CMTime { get }

  var avAsset: AVAsset { get }

  var naturalSize: CGSize { get }
}

//extension Composable {
//  var duration: CMTime {
//    return avAsset.duration
//  }
//}

extension Screen: Composable {
  var naturalSize: CGSize {
    return track.naturalSize
  }
}
