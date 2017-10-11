struct Alert {
  let title: String
  let recoverySuggestion: String

  let buttons: [String]

  init(title: String, recoverySuggestion: String, buttons: [String] = []) {
    self.title = title
    self.recoverySuggestion = recoverySuggestion
    self.buttons = buttons
  }
}
