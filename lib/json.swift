class Json {
  static func _print(_ str: String) {
    print(str, terminator: "")
  }

  static func printIndent(_ lv: Int) {
    for _ in 0..<lv {
      _print("  ")
    }
  }

  static func printNode(_ node: Node, _ lv: Int, _ pretty: Bool) {
    switch node {
    case let intNode as IntNode:
      if pretty { printIndent(lv) }
      _print(String(intNode.n))
    case let strNode as StrNode:
      if pretty { printIndent(lv) }
      _print("\"")
      _print(strNode.s)
      _print("\"")
    case let listNode as ListNode:
      _printList(listNode.list, lv, pretty)
    default:
      fatalError("unsupported")
    }
  }

  static func _printList(_ xs: List, _ lv: Int, _ pretty: Bool) {
    if pretty { printIndent(lv) }
    _print("[")
    if pretty { _print("\n") }

    for i in 0..<xs.count {
      let node = xs.get(i)
      printNode(node, lv + 1, pretty)
      if i <= xs.count - 2 {
        _print(",")
        if !pretty { _print(" ") }
      }
      if pretty { _print("\n") }
    }

    if pretty { printIndent(lv) }
    _print("]")
  }

  static func printList(_ xs: List) {
    _printList(xs, 0, false)
  }

  static func prettyPrintList(_ xs: List) {
    _printList(xs, 0, true)
  }

  static func parseList(_ json: String) -> (List, Int) {
    var pos = 1
    let myre = MyRegexp()
    let xs = List()

    while pos < json.count {
      let rest = Utils.substring(json, pos)
      let c = Utils.charAt(json, pos)!

      if c == "]" {
        pos += 1
        break
      }

      if c == " " || c == "," || c == "\n" {
        pos += 1
      } else if c == "[" {
        let (innerXs, size) = parseList(String(rest))
        xs.addList(innerXs)
        pos += size
      } else if c == "\"" {
        let _ = myre.match(rest, #"^\"(?<g1>.*?)\""#)
        let g1 = myre.getGroup1()!
        xs.addStr(g1)
        pos += g1.count + 2
      } else if myre.match(rest, #"^(?<g1>-?[0-9]+)"#) {
        let g1 = myre.getGroup1()!
        let n = Int(g1)!
        xs.addInt(n)
        pos += g1.count
      } else {
        pos += 1
      }
    }

    return (xs, pos)
  }

  static func parse(_ json: String) -> List {
    let (xs, _) = parseList(json)
    return xs
  }
}
