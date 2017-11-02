enum Result<Value, Error> {
  case success(Value)
  case failure(Error)

  var value: Value? {
    switch self {
    case .success(let value): return value
    case .failure: return .none
    }
  }

  var error: Error? {
    switch self {
    case .success: return .none
    case .failure(let error): return error
    }
  }

  init(value: Value?, failWith: @autoclosure () -> Error) {
    self = value.map(Result.success) ?? .failure(failWith())
  }

  init(error: Error) {
    self = .failure(error)
  }

  init(attempt f: @autoclosure () throws -> Value) {
    do {
      self = .success(try f())
    } catch let error {
      self = .failure(error as! Error)
    }
  }

  static func create(failWith: Error, value: Value?) -> Result {
    return Result(value: value, failWith: failWith)
  }

  func map<A>(_ f: (Value) -> A) -> Result<A, Error> {
    return flatMap({ .success(f($0)) })
  }

  static func <^> <A> (_ f: (Value) -> A, x: Result<Value, Error>) -> Result<A, Error> {
    return x.map(f)
  }

  func apply<A> (_ f: Result<(Value) -> A, Error>) -> Result<A, Error> {
    return f.flatMap({ self.map($0) })
  }

  static func <*> <A> (_ f: Result<(Value) -> A, Error>, _ x: Result<Value, Error>) -> Result<A, Error> {
    return x.apply(f)
  }

  func flatMap<A>(_ f: (Value) -> Result<A, Error>) -> Result<A, Error> {
    switch self {
    case .success(let value): return f(value)
    case .failure(let error): return .failure(error)
    }
  }

  static func >>- <A> (_ f: (Value) -> Result<A, Error>, _ x: Result<Value, Error>) -> Result<A, Error> {
    return x.flatMap(f)
  }

  static func -<< <A> (_ x: Result<Value, Error>, _ f: (Value) -> Result<A, Error>) -> Result<A, Error> {
    return x.flatMap(f)
  }

  static func pure(_ x: Value) -> Result<Value, Error> {
    return .success(x)
  }

  static func <|>(lhs: Result, rhs: @autoclosure @escaping () -> Result) -> Result {
    switch lhs {
    case .failure: return rhs()
    case .success: return lhs
    }
  }

  func mapError<A>(_ f: (Error) -> A) -> Result<Value, A> {
    switch self {
    case .success(let value): return .success(value)
    case .failure(let error): return .failure(f(error))
    }
  }

  func flatMapError<A>(_ f: (Error) -> Result<Value, A>) -> Result<Value, A> {
    switch self {
    case .success(let value): return .success(value)
    case .failure(let error): return f(error)
    }
  }

  func bimap<A, B>(_ f: @escaping (Value) -> A, _ g: (Error) -> B) -> Result<A ,B> {
    return self.map(f).mapError(g)
  }
}
