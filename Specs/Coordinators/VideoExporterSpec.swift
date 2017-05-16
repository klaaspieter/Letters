import Letters
import Nimble
import Quick
import Result

class VideoExporterSpec: QuickSpec {
  override func spec() {
    describe(".export") {
      it("errors when cameraVideoURL is not a valid asset") {
        let exporter = VideoExporter(
          cameraVideoURL: URL(fileURLWithPath: ""),
          screenVideoURL: Bundle.main.url(forResource: "screen", withExtension: "mov")!,
          outputURL: URL(fileURLWithPath: "")
        )

        var result: Result<Void, ExportError>?
        exporter.export {
          result = $0
        }

        expect(result?.error).toEventually(equal(.invalidCameraVideoURL))
      }

      it("errors when screenVideo is not a valid asset") {
        let exporter = VideoExporter(
          cameraVideoURL: Bundle.main.url(forResource: "camera", withExtension: "mov")!,
          screenVideoURL: URL(fileURLWithPath: ""),
          outputURL: URL(fileURLWithPath: "")
        )

        var result: Result<Void, ExportError>?
        exporter.export {
          result = $0
        }

        expect(result?.error).toEventually(equal(.invalidScreenVideoURL))
      }
    }
  }
}
