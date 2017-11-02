extension Optional {
  func `do`(_ f: (Wrapped) throws -> Void) rethrows -> Wrapped? {
    return try self.map({
      try f($0)
      return $0
    })
  }
}

// Functor
extension Optional {
  static func <^> <A> (_ f: (Wrapped) -> A, _ x: Wrapped?) -> A? {
    return x.map(f)
  }
}

// Applicative
extension Optional {
  static func pure<A>(_ x: A) -> A? {
    return .some(x)
  }

  func apply<A>(_ f: ((Wrapped) -> A)?) -> A? {
    return f.flatMap({ self.map($0) })
  }

  static func <*> <A> (_ f: ((Wrapped) -> A)?, _ x: Wrapped?) -> A? {
    return x.apply(f)
  }
}

// Result
extension Optional {
  func asResult<Error>(failingWith error: Error) -> Result<Wrapped, Error> {
    return self.map(Result.success) ?? .failure(error)
  }
}

func asResult<Wrapped, Error>(failingWith error: Error) -> (Wrapped?) -> Result<Wrapped, Error> {
  return { $0.asResult(failingWith: error) }
}
