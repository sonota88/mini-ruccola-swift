class Node {
}

class IntNode : Node {
  var n: Int

  init(_ n: Int) {
    self.n = n
  }

  func get() -> Int {
    return self.n
  }
}

class StrNode : Node {
  var s: String

  init(_ s: String) {
    self.s = s
  }
}

class ListNode : Node {
  var list: List

  init(_ xs: List) {
    self.list = xs
  }
}

class List {
  var nodes: [Node]
  var count: Int {
    get {
      return self.nodes.count
    }
  }

  init(_ nodes: [Node] = []) {
    self.nodes = nodes
  }

  static func of(_ nodes: Node...) -> List {
    return List(nodes)
  }

  func add(_ node: Node) {
    self.nodes.append(node)
  }

  func addInt(_ n: Int) {
    add(IntNode(n))
  }

  func addStr(_ s: String) {
    add(StrNode(s))
  }

  func addList(_ xs: List) {
    add(ListNode(xs))
  }

  func addAll(_ list: List) {
    for x in list.nodes {
      add(x)
    }
  }

  func get(_ i: Int) -> Node {
    return self.nodes[i]
  }

  func getInt(_ i: Int) -> Int {
    switch get(i) {
    case let intNode as IntNode:
      return intNode.n;
    default:
      fatalError("not a IntNode")
    }
  }

  func getStr(_ i: Int) -> String {
    switch get(i) {
    case let strNode as StrNode:
      return strNode.s;
    default:
      fatalError("not a StrNode")
    }
  }

  func getList(_ i: Int) -> List {
    switch get(i) {
    case let listNode as ListNode:
      return listNode.list;
    default:
      fatalError("not a ListNode")
    }
  }

  func rest(_ i: Int = 1) -> List {
    let newList = List()
    for i in i..<count {
      newList.add(get(i))
    }
    return newList
  }
}

enum TokenKind: String {
  case int, str, sym, ident, kw
}

struct Token {
  let lineno: Int
  let kind: TokenKind
  let str: String

  init(_ lineno: Int, _ kind: TokenKind, _ str: String) {
    self.lineno = lineno
    self.kind = kind
    self.str = str
  }

  static func fromLine(_ line: String) -> Token {
    let xs = Json.parse(line)
    let lineno = xs.getInt(0)
    let kind   = TokenKind(rawValue: xs.getStr(1))!
    let str    = xs.getStr(2)
    return Token(lineno, kind, str)
  }
}
