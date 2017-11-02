import Foundation

// Result
extension Bool {
  func asResult<Error>(failingWith error: Error) -> Result<Void, Error> {
    if self {
      return .success(Void())
    } else {
      return .failure(error)
    }
  }
}

func asResult<Error>(failingWith error: Error) -> (Bool) -> Result<Void, Error> {
  return { $0.asResult(failingWith: error) }
}
