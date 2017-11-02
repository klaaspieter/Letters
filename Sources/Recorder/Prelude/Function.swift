public func id<A>(_ x: A) -> A {
  return x
}

public func const<A, B>(_ a: A) -> (B) -> A {
  return { _ in a }
}

public func <<< <A, B, C>(_ f: @escaping (B) -> C, _ g: @escaping (A) -> B) -> (A) -> C {
  return { a in f(g(a)) }
}

public func <| <A, B> (f: (A) throws -> B, a: A) rethrows -> B {
  return try f(a)
}

public func |> <A, B> (a: A, f: (A) throws -> B) rethrows -> B {
  return try f(a)
}

public func flip<A, B, C> (_ f: @escaping (A) -> (B) -> C) -> (B) -> (A) -> C {
  return { b in
    return { a in
      return f(a)(b)
    }
  }
}
