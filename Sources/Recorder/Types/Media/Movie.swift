import AVFoundation

struct Movie: Composable {
  let avAsset: AVAsset
  let video: Video
  let audio: Audio

  var minFrameDuration: CMTime {
    return videoTrack.minFrameDuration
  }

  var videoTrack: AVAssetTrack {
    return video.track
  }

  var audioTrack: AVAssetTrack {
    return audio.track
  }

  var naturalSize: CGSize {
    return videoTrack.naturalSize
  }

  var duration: CMTime {
    return avAsset.duration
  }

  init?(avAsset: AVAsset) {
    guard let video = Video(avAsset: avAsset) else {
      return nil
    }

    guard let audio = Audio(avAsset: avAsset) else {
      return nil
    }

    self.init(video: video, audio: audio, originalAsset: avAsset)
  }

  private init?(video: Video, audio: Audio, originalAsset: AVAsset) {
    self.avAsset = originalAsset
    self.video = video
    self.audio = audio
  }
}

