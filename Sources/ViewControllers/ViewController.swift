import AVFoundation
import Cocoa

class ViewController: NSViewController {

  @IBOutlet var captureField: NSTextField!
  @IBOutlet var label: NSTextField!

  @IBOutlet var recordButton: NSButton!
  @IBOutlet var activityIndicator: NSProgressIndicator!

  @IBOutlet var placeholderLabel: NSTextField!

  var recorder: Recorder?

  private let fileManager = FileManager.default

  override func viewDidLoad() {
    super.viewDidLoad()

    captureField.alphaValue = 0.0
    view.window?.makeFirstResponder(captureField)

    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.white.cgColor

    activityIndicator.alphaValue = 0.3
  }

  @IBAction func toggleRecording(_ sender: Any) {
    switch recordButton.state {
    case .on:
      beginRecording()
    case .off, .mixed, _:
      endRecording()
    }
  }

  private func beginRecording() {
    showActivity()

    guard let window = view.window else { return }

    let outputDirectoryURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(
      "test",
      isDirectory: true
    )
    recorder = Recorder(screenRect: window.frame, outputDirectoryURL: outputDirectoryURL)
    recorder?.delegate = self
    recorder?.start()
  }

  private func endRecording() {
    showActivity()

    recorder?.stop()
  }

  private func didFinishExporting(_ export: Result<Export, RecorderError>) {
    hideActivity()

    switch export {
    case .success(let export):
      curry(show(error:for:)) <^> save(exportAt: export.outputURL).error <*> export
    case .failure(let error):
      show(error: error)
    }
  }

  private func showActivity() {
    recordButton.alphaValue = 0.0
    activityIndicator.startAnimation(.none)
  }

  private func hideActivity() {
    activityIndicator.stopAnimation(.none)
    recordButton.alphaValue = 1.0
  }

  private func show(error: AlertConvertible, for export: Export? = .none) {
    NSLog(
      """

      --------------------
      Recording failed

      Export:
      \(String(describing: export))

      Error:
      \(error)
      """
    )

    guard let window = view.window else { return }
    NSAlert(alert: error.alert).beginSheetModal(for: window, completionHandler: { response in
      switch response {
      case .cancel, .alertSecondButtonReturn, .alertThirdButtonReturn:
        break
      case .OK, .alertFirstButtonReturn, _:
        NSWorkspace.shared.activateFileViewerSelecting([self.fileManager.homeDirectoryForCurrentUser])
      }
    })
  }

  private func save(exportAt exportURL: URL) -> Result<URL, SaveError> {
    let savePanel = NSSavePanel(
      allowedFileTypes: ["mov"],
      allowsOtherFileTypes: false,
      nameFieldStringValue: "Untitled.mov"
    )

    guard savePanel.runModal() == .OK else {
      return .success(exportURL)
    }

    guard let saveURL = savePanel.url else {
      return .failure(.missingURL)
    }

    do {
      let _ = try fileManager.replaceItemAt(saveURL, withItemAt: exportURL)
      return .success(exportURL)
    } catch {
      return .failure(.cannotMove(to: saveURL))
    }
  }
}

extension ViewController: NSTextFieldDelegate {
  override func controlTextDidChange(_ obj: Notification) {
    placeholderLabel.isHidden = true
    label.stringValue = captureField.stringValue
    captureField.stringValue = ""
  }

  override func controlTextDidEndEditing(_ obj: Notification) {
    DispatchQueue.main.async { [weak self] in
      guard let `self` = self else { return }
      self.captureField.window?.makeFirstResponder(self.captureField)
    }
  }
}

extension ViewController: RecorderDelegate {
  func didStart(recorder: Recorder) {
    hideActivity()
  }

  func didFinish(with recording: Result<Recording, CaptureError>, in recorder: Recorder) {
    self.recorder = .none

    let completion = { result in
      DispatchQueue.main.async(execute: {
        self.didFinishExporting(result)
      })
    }

    let recording = recording.mapError(RecorderError.capturing)

    let pictureInPicture: Compose<Movie, Screen> = .pictureInPicture
    let composition = recording.map({
      pictureInPicture.perform($0.movie, $0.screen)
    }) -<< { $0.mapError(RecorderError.composing) }


    let outputURL = fileManager.uniqueTemporaryFile(pathExtension: "mov")

    let export = (curry(Export.make)
      <^> composition
      <*> .pure(outputURL)
      -<< { $0.mapError(RecorderError.exporting) })


    switch export {
    case .success(let export):
      export.perform(completion: { result in
        completion(result.mapError(RecorderError.exporting))
      })

    case .failure(let error):
      completion(.failure(error))
    }
  }
}
