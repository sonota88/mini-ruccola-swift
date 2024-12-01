class Lexer {
  func isKeyword(_ str: String) -> Bool {
    return [
      "func", "return", "var", "set", "call", "call_set", "while", "case", "when",
      "_cmt", "_debug"
    ].contains(str)
  }

  func printToken(_ lineno: Int, _ kind: String, _ str: String) {
    print("[\(lineno), \"\(kind)\", \"\(str)\"]")
  }

  func lex() {
    let src = Utils.readStdinAll()
    let myre = MyRegexp()
    var lineno = 1

    var pos = 0
    while pos < src.count {
      let rest = Utils.substring(src, pos)
      let c = Utils.charAt(src, pos)!

      if c == " " {
        pos += 1
      } else if c == "\n" {
        lineno += 1
        pos += 1
      } else if c == "\"" {
        let _ = myre.match(rest, #"^\"(?<g1>.*?)\""#)
        let g1 = myre.getGroup1()!
        printToken(lineno, "str", g1)
        pos += g1.count + 2
      } else if myre.match(rest, #"^(?<g1>//.*)"#) {
        let g1 = myre.getGroup1()!
        pos += g1.count
      } else if myre.match(rest, #"^(?<g1>==|!=|[(){};,=+*])"#) {
        let g1 = myre.getGroup1()!
        printToken(lineno, "sym", g1)
        pos += g1.count
      } else if myre.match(rest, #"^(?<g1>-?[0-9]+)"#) {
        let g1 = myre.getGroup1()!
        printToken(lineno, "int", g1)
        pos += g1.count
      } else if myre.match(rest, #"^(?<g1>[_a-z][_a-z0-9]*)"#) {
        let g1 = myre.getGroup1()!
        let kind = isKeyword(g1) ? "kw" : "ident"
        printToken(lineno, kind, g1)
        pos += g1.count
      } else {
        fatalError("unexpected pattern (\(rest))")
      }
    }
  }
}
