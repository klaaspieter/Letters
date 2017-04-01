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
          screenVideoURL: URL(fileURLWithPath: ""),
          outputURL: URL(fileURLWithPath: "")
        )

        var result: Result<Void, ExportError>?
        exporter.export {
          result = $0
        }

        expect(result?.error) == .invalidCameraVideoURL
      }

      it("errors when screenVideo is not a valid asset") {
        let exporter = VideoExporter(
          cameraVideoURL: URL(fileURLWithPath: ""),
          screenVideoURL: URL(fileURLWithPath: ""),
          outputURL: URL(fileURLWithPath: "")
        )

        var result: Result<Void, ExportError>?
        exporter.export {
          result = $0
        }

        expect(result?.error) == .invalidScreenVideoURL
      }
    }
  }
}
