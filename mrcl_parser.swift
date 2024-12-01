class Parser {
  var tokens: [Token] = []
  var pos: Int = 0

  func incrementPos() {
    self.pos += 1
  }

  func peek(_ offset: Int = 0) -> Token {
    return self.tokens[pos + offset]
  }

  func peekAndNext(_ offset: Int = 0) -> Token {
    let t = self.tokens[pos + offset]
    incrementPos()
    return t
  }

  func isEnd() -> Bool {
    return pos >= tokens.count
  }

  func consume(_ str: String) {
    let t = peek()
    if t.str == str {
      incrementPos()
    } else {
      fatalError("unexpected token / expected (\(str)) / actual (\(t.str))")
    }
  }

  // --------------------------------

  // arg: INT
  //    | IDENT
  func parseArg() -> Node {
    let t = peekAndNext()
    switch t.kind {
    case .ident: return StrNode(t.str)
    case .int  : return IntNode(Int(t.str)!)
    default:
      fatalError("unsupported")
    }
  }

  // args: (empty)
  //     | arg
  //     | args "," arg
  func parseArgs() -> List {
    let args = List()
    if peek().str == ")" {
      return args
    }

    args.add(parseArg())

    while peek().str == "," {
      consume(",")
      args.add(parseArg())
    }
    return args
  }

  // term: INT
  //     | IDENT
  //     | "(" expr ")"
  func parseExprTerm() -> Node {
    switch peek().kind {
    case .int:
      let n = Int(peekAndNext().str)!
      return IntNode(n)
    case .ident:
      let str = peekAndNext().str
      return StrNode(str)
    case .sym:
      consume("(")
      let expr = parseExpr()
      consume(")")
      return expr
    default:
      fatalError("unsupported")
    }
  }

  func isBinOp(_ token: Token) -> Bool {
    return ["+", "*", "==", "!="].contains(token.str)
  }

  // expr: term
  //     | expr BINOP term
  func parseExpr() -> Node {
    var expr = parseExprTerm()

    while isBinOp(peek()) {
      let op = peekAndNext().str
      let rhs = parseExprTerm()
      expr = ListNode(
        List.of(StrNode(op), expr, rhs)
      )
    }

    return expr
  }

  // return_stmt: "return" ";"
  //            | "return" expr ";"
  func parseReturn() -> List {
    let stmt = List.of(StrNode("return"))

    consume("return")
    if peek().str != ";" {
      stmt.add(parseExpr())
    }
    consume(";")

    // =>   ["return"]
    //    | ["return", expr]
    return stmt
  }

  // set_stmt: "set" var_name "=" expr ";"
  func parseSet() -> List {
    consume("set")
    let varName = peekAndNext().str
    consume("=")
    let expr = parseExpr()
    consume(";")

    // => ["set", var_name, expr]
    return List.of(StrNode("set"), StrNode(varName), expr)
  }

  // funcall: fn_name "(" fn_args ")"
  func parseFuncall() -> ListNode {
    let fnName = peekAndNext().str
    consume("(")
    let args = parseArgs()
    consume(")")

    let funcall = List.of(StrNode(fnName))
    funcall.addAll(args)

    // => [fn_name, ...args]
    return ListNode(funcall)
  }

  // call_stmt: "call" funcall ";"
  func parseCall() -> List {
    consume("call")
    let funcall = parseFuncall()
    consume(";")

    // => ["call", funcall]
    return List.of(StrNode("call"), funcall)
  }

  // call_set_stmt: "call_set" var_name "=" funcall ";"
  func parseCallSet() -> List {
    consume("call_set")
    let varName = peekAndNext().str
    consume("=")
    let funcall = parseFuncall()
    consume(";")

    // => ["call_set", var_name, funcall]
    return List.of(StrNode("call_set"), StrNode(varName), funcall)
  }

  // while_stmt: "while" "(" cond_expr ")" "{" stmt* "}"
  func parseWhile() -> List {
    consume("while")
    consume("(")
    let condExpr = parseExpr()
    consume(")")
    consume("{")
    let stmts = parseStmts()
    consume("}")

    // => ["while", cond_expr, ...stmts]
    let stmt = List.of(StrNode("while"), condExpr)
    stmt.addAll(stmts)
    return stmt
  }

  // when_clause: "when" "(" cond_expr ")" "{" stmt* "}"
  func parseWhenClause() -> List {
    consume("when")
    consume("(")
    let condExpr = parseExpr()
    consume(")")
    consume("{")
    let stmts = parseStmts()
    consume("}")

    // => [cond_expr, ...stmts]
    let whenClause = List.of(condExpr)
    whenClause.addAll(stmts)
    return whenClause
  }

  // case_stmt: "case" when_clause*
  func parseCase() -> List {
    let stmt = List.of(StrNode("case"))

    consume("case")

    while peek().str == "when" {
      let whenClause = parseWhenClause()
      stmt.addList(whenClause)
    }

    // => ["case", ...when_clauses]
    return stmt
  }

  func parseVmComment() -> List {
    consume("_cmt")
    consume("(")
    let comment = peekAndNext().str
    consume(")")
    consume(";")

    return List.of(StrNode("_cmt"), StrNode(comment))
  }

  func parseDebug() -> List {
    consume("_debug")
    consume("(")
    consume(")")
    consume(";")

    return List.of(StrNode("_debug"))
  }

  func parseStmt() -> List {
    switch peek().str {
    case "return"  : return parseReturn()
    case "set"     : return parseSet()
    case "call"    : return parseCall()
    case "call_set": return parseCallSet()
    case "while"   : return parseWhile()
    case "case"    : return parseCase()
    case "_cmt"    : return parseVmComment()
    case "_debug"  : return parseDebug()
    default:
      fatalError("unsupported (\(peek()))")
    }
  }

  func parseStmts() -> List {
    let stmts = List()
    while peek().str != "}" {
      if peek().str == "var" {
        stmts.addList(parseVar())
      } else {
        stmts.addList(parseStmt())
      }
    }

    return stmts
  }

  // var_stmt: "var" var_name ";"
  //         | "var" var_name expr ";"
  func parseVar() -> List {
    let stmt = List.of(StrNode("var"))

    consume("var")
    let varName = peekAndNext().str
    stmt.addStr(varName)

    if peek().str == "=" {
      consume("=")
      stmt.add(parseExpr())
    }

    consume(";")

    // =>   ["var", var_name]
    //    | ["var", var_name, expr]
    return stmt
  }

  // func_def: "func" fn_name "(" args ")" "{" stmts "}"
  func parseFuncDef() -> List {
    consume("func")
    let fnName = peekAndNext().str
    consume("(")
    let args = parseArgs()
    consume(")")
    consume("{")
    let stmts = parseStmts()
    consume("}")

    // => ["func", fn_name, args, stmts]
    return List.of(StrNode("func"), StrNode(fnName), ListNode(args), ListNode(stmts))
  }

  func parseTopStmts() -> List {
    let topStmts = List.of(StrNode("top_stmts"))
    while !isEnd() {
      let fn = parseFuncDef()
      topStmts.addList(fn)
    }

    // => ["top_stmts", ...top_stmts]
    return topStmts
  }

  func parse() {
    let lines = Utils.readStdinAllAsLines()
    self.tokens = lines.map{ Token.fromLine($0) }
    let ast = parseTopStmts()
    Json.prettyPrintList(ast)
  }
}
