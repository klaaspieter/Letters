import Dispatch

final class Parallel<A> {
  private let queue = DispatchQueue(label: "Recorder.Parellel")
  private var computed: A?

  private let compute: (@escaping (A) -> Void) -> Void

  init(_ compute: @escaping (@escaping (A) -> Void) -> Void) {
    self.compute = compute
  }

  func run(_ callback: @escaping (A) -> Void) {
    queue.async {
      guard let computed = self.computed else {
        return self.compute { computed in
          self.computed = computed
          callback(computed)
        }
      }
      callback(computed)
    }
  }
}

extension Parallel {
  static func pure(_ x: A) -> Parallel<A> {
    return Parallel({ $0(x) })
  }

  func map<B>(_ f: @escaping (A) -> B) -> Parallel<B> {
    return Parallel<B> { completion in
      self.run({ completion(f($0)) })
    }
  }

  static func <^> <B> (_ f: @escaping (A) -> B, _ x: Parallel<A>) -> Parallel<B> {
    return x.map(f)
  }

  func apply<B>(_ f: Parallel<(A) -> B>) -> Parallel<B> {
    return Parallel<B> { g in
      f.run { f in if let x = self.computed { g(f(x)) } }
      self.run { x in if let f = f.computed { g(f(x)) } }
    }
  }

  static func <*> <B> (_ f: Parallel<(A) -> B>, _ x: Parallel<A>) -> Parallel<B> {
    return x.apply(f)
  }
}
