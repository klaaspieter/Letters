extension RecorderError: AlertConvertible {
  var alert: Alert {
    switch self {
    case .capturing(let error):
      return error.alert

    case .exporting(let error):
      return error.alert

    case .composing(let error):
       return error.alert
    }
  }
}

extension CaptureError: AlertConvertible {
  var alert: Alert {
    let title = "Something went wrong while recording"
    let recoverySuggestion: String

    switch self {
    case .invalidOutputURL,
         .invalidAsset,
         .missingOutput,
         .fileAlreadyExists,
         .noDataCaptured,
         .unknown:
      recoverySuggestion = "The recording failed due to an internal error. Please try again."

    case .missingInput:
      recoverySuggestion = "Your camera or screen could not be recorded. Please ensure no other applications are actively recording your screen or using the camera and try again."

    case .diskFull:
      recoverySuggestion = "The recording failed because your disk is full."

    case .outOfMemory:
      recoverySuggestion = "The recording failed because your system is out of memory. Quit some other applications and try again."
    }

    return Alert(title: title, recoverySuggestion: recoverySuggestion)
  }
}

extension ComposeError: AlertConvertible {
  var alert: Alert {
    return Alert(
      title: "Something went wrong while recording",
      recoverySuggestion: "The recording failed due to an internal error. Please try again."
    )
  }
}

extension ExportError: AlertConvertible {
  var alert: Alert {
    return Alert(
      title: "Something went wrong while recording",
      recoverySuggestion: "The recording failed due to an internal error. Please try again."
    )
  }
}
