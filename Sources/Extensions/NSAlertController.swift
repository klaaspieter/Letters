import Cocoa

extension NSAlert {
  convenience init(alert: Alert) {
    self.init()

    self.messageText = alert.title
    self.informativeText = alert.recoverySuggestion
  }
}
