import AVFoundation

struct Composition {
  let avAsset: AVAsset
  let videoComposition: AVVideoComposition?

  init(avAsset: AVAsset, videoComposition: AVVideoComposition? = .none) {
    self.avAsset = avAsset
    self.videoComposition = videoComposition
  }
}

extension Composition: Exportable {
}
