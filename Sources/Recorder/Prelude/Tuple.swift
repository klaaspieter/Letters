  func tuple<A, B>(_ x: A) -> (B) -> (A, B) {
    return { y in (x, y) }
  }

  func tuple<A, B, C>(_ x: A) -> (B) -> (C) -> (A, B, C) {
    return { y in { z in (x, y, z) } }
  }
