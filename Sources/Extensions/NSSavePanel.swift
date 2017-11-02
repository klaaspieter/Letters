import Cocoa

extension NSSavePanel {
  convenience init(
    allowedFileTypes: [String] = [],
    allowsOtherFileTypes: Bool = false,
    nameFieldStringValue: String = ""
  ) {
    self.init()
    self.allowedFileTypes = allowedFileTypes
    self.allowsOtherFileTypes = allowsOtherFileTypes
    self.nameFieldStringValue = nameFieldStringValue
  }
}
