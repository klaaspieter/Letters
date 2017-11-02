import Foundation

enum SaveError {
  case missingURL
  case cannotMove(to: URL)
}

extension SaveError: AlertConvertible {
  var alert: Alert {
    return Alert(
      title: "There was a problem saving your recording",
      recoverySuggestion: "Due to an internal error we were unable to save your recording."
    )
  }
}
