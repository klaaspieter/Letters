import AVFoundation

extension AVError {
  var captureError: CaptureError {
    switch self.code {

    case .fileAlreadyExists:
      return .fileAlreadyExists

    case .diskFull:
      return .diskFull

    case .noDataCaptured:
      return .noDataCaptured

    case .outOfMemory:
      return .outOfMemory

    case .unknown,
         .sessionNotRunning,
         .deviceAlreadyUsedByAnotherSession,
         .sessionConfigurationChanged,
         .deviceWasDisconnected,
         .mediaChanged,
         .maximumDurationReached,
         .maximumFileSizeReached,
         .mediaDiscontinuity,
         .maximumNumberOfSamplesForFileFormatReached,
         .deviceNotConnected,
         .deviceInUseByAnotherApplication,
         .deviceLockedForConfigurationByAnotherProcess,
         .exportFailed,
         .decodeFailed,
         .invalidSourceMedia,
         .compositionTrackSegmentsNotContiguous,
         .invalidCompositionTrackSegmentDuration,
         .invalidCompositionTrackSegmentSourceStartTime,
         .invalidCompositionTrackSegmentSourceDuration,
         .fileFormatNotRecognized,
         .fileFailedToParse,
         .maximumStillImageCaptureRequestsExceeded,
         .contentIsProtected,
         .noImageAtTime,
         .decoderNotFound,
         .encoderNotFound,
         .contentIsNotAuthorized,
         .applicationIsNotAuthorized,
         .operationNotSupportedForAsset,
         .decoderTemporarilyUnavailable,
         .encoderTemporarilyUnavailable,
         .invalidVideoComposition,
         .referenceForbiddenByReferencePolicy,
         .invalidOutputURLPathExtension,
         .screenCaptureFailed,
         .displayWasDisabled,
         .torchLevelUnavailable,
         .incompatibleAsset,
         .failedToLoadMediaData,
         .serverIncorrectlyConfigured,
         .applicationIsNotAuthorizedToUseDevice,
         .failedToParse,
         .fileTypeDoesNotSupportSampleReferences,
         .undecodableMediaData,
         .airPlayControllerRequiresInternet,
         .airPlayReceiverRequiresInternet,
         .videoCompositorFailed,
         .createContentKeyRequestFailed,
         .unsupportedOutputSettings,
         .operationNotAllowed,
         .contentIsUnavailable,
         .formatUnsupported,
         .malformedDepth,
         .contentNotUpdated,
         .noLongerPlayable,
         .noCompatibleAlternatesForExternalDisplay:
      return .unknown(self.code)
    }
  }
}
