class CodeGenerator {
  var labelIdMax = 0

  func asmPrologue() {
    print("  push bp")
    print("  mov bp sp")
  }

  func asmEpilogue() {
    print("  mov sp bp")
    print("  pop bp")
  }

  func lvarDisp(_ lvars: [String], _ varName: String) -> Int {
    let index = lvars.firstIndex(of: varName)!
    return -(1 + index)
  }

  func fnArgDisp(_ fnArgs: [String], _ varName: String) -> Int {
    let index = fnArgs.firstIndex(of: varName)!
    return 2 + index
  }

  func getLabelId() -> Int {
    labelIdMax += 1
    return labelIdMax
  }

  // --------------------------------

  func genExprAdd() {
    print("  pop reg_b")
    print("  pop reg_a")
    print("  add reg_a reg_b")
  }

  func genExprMult() {
    print("  pop reg_b")
    print("  pop reg_a")
    print("  mul reg_b")
  }

  func genExprEqNeq(_ fnArgs: [String], _ lvars: [String], _ expr: Node, _ isEq: Bool) {
    let labelId = getLabelId()
    let labelThen = "then_\(labelId)"
    let labelEnd = isEq ? "end_eq_\(labelId)" : "end_neq_\(labelId)"

    print("  pop reg_b")
    print("  pop reg_a")
    print("  cmp")
    print("  je \(labelThen)")

    if isEq {
      print("  mov reg_a 0")
    } else {
      print("  mov reg_a 1")
    }
    print("  jmp \(labelEnd)")

    print("label \(labelThen)")
    if isEq {
      print("  mov reg_a 1")
    } else {
      print("  mov reg_a 0")
    }

    print("label \(labelEnd)")
  }

  func genExprEq(_ fnArgs: [String], _ lvars: [String], _ expr: Node) {
    genExprEqNeq(fnArgs, lvars, expr, true)
  }

  func genExprNeq(_ fnArgs: [String], _ lvars: [String], _ expr: Node) {
    genExprEqNeq(fnArgs, lvars, expr, false)
  }

  func genExprBinary(_ fnArgs: [String], _ lvars: [String], _ expr: Node) {
    guard let listNode = expr as? ListNode else {
      fatalError("unsupported")
    }

    let list: List = listNode.list
    let op  = list.getStr(0)
    let lhs = list.get(1)
    let rhs = list.get(2)

    genExpr(fnArgs, lvars, lhs)
    print("  push reg_a")
    genExpr(fnArgs, lvars, rhs)
    print("  push reg_a")

    switch op {
    case "+" : genExprAdd()
    case "*" : genExprMult()
    case "==": genExprEq(fnArgs, lvars, expr)
    case "!=": genExprNeq(fnArgs, lvars, expr)
    default:
      fatalError("unsupported (\(op))")
    }
  }

  func genExpr(_ fnArgs: [String], _ lvars: [String], _ expr: Node) {
    switch expr {
    case let intNode as IntNode:
      print("  mov reg_a \(intNode.n)")
    case let strNode as StrNode:
      let str = strNode.s
      if lvars.contains(str) {
        let disp = lvarDisp(lvars, str)
        print("  mov reg_a [bp:\(disp)]")
      } else if fnArgs.contains(str) {
        let disp = fnArgDisp(fnArgs, str)
        print("  mov reg_a [bp:\(disp)]")
      } else {
        fatalError("unsupported (\(str))")
      }
    case is ListNode:
      genExprBinary(fnArgs, lvars, expr)
    default:
      fatalError("unsupported")
    }
  }

  func genReturn(_ fnArgs: [String], _ lvars: [String], _ stmt: List) {
    if stmt.count == 2 {
      let expr = stmt.get(1)
      genExpr(fnArgs, lvars, expr)
    }

    asmEpilogue()
    print("  ret")
  }

  func _genSet(_ fnArgs: [String], _ lvars: [String], _ varName: String, _ expr: Node) {
    genExpr(fnArgs, lvars, expr)

    if lvars.contains(varName) {
      let disp = lvarDisp(lvars, varName)
      print("  mov [bp:\(disp)] reg_a")
    } else {
      fatalError("unsupported")
    }
  }

  func genSet(_ fnArgs: [String], _ lvars: [String], _ stmt: List) {
    let varName = stmt.getStr(1)
    let expr    = stmt.get(2)
    _genSet(fnArgs, lvars, varName, expr)
  }

  func _genCall(_ fnArgs: [String], _ lvars: [String], _ funcall: List) {
    let funcallName = funcall.getStr(0)
    let funcallArgs = funcall.rest()

    for i in stride(from: funcallArgs.count - 1, through: 0, by: -1) {
      let expr = funcallArgs.get(i)
      genExpr(fnArgs, lvars, expr)
      print("  push reg_a")
    }

    _genVmComment("call  \(funcallName)")
    print("  call \(funcallName)")
    print("  add sp \(funcallArgs.count)")
  }

  func genCall(_ fnArgs: [String], _ lvars: [String], _ stmt: List) {
    let funcall = stmt.getList(1)
    _genCall(fnArgs, lvars, funcall)
  }

  func genCallSet(_ fnArgs: [String], _ lvars: [String], _ stmt: List) {
    let varName = stmt.getStr(1)
    let funcall = stmt.getList(2)

    _genCall(fnArgs, lvars, funcall)
    let disp = lvarDisp(lvars, varName)
    print("  mov [bp:\(disp)] reg_a")
  }

  func genWhile(_ fnArgs: [String], _ lvars: [String], _ stmt: List) {
    let condExpr = stmt.get(1)
    let body     = stmt.rest(2)

    let labelId = getLabelId()

    print("label while_\(labelId)")
    genExpr(fnArgs, lvars, condExpr)
    print("  mov reg_b 0")
    print("  cmp")
    print("  je end_while_\(labelId)")
    genStmts(fnArgs, lvars, body)
    print("  jmp while_\(labelId)")

    print("label end_while_\(labelId)")
  }

  func genCase(_ fnArgs: [String], _ lvars: [String], _ stmt: List) {
    let whenClauses = stmt.rest()

    let labelId = getLabelId()
    let labelEnd         = "end_case_\(labelId)"
    let labelEndWhenHead = "end_when_\(labelId)"

    var whenIdx = -1
    for i in 0..<whenClauses.count {
      let whenClause = whenClauses.getList(i)
      whenIdx += 1
      let condExpr = whenClause.get(0)
      let stmts    = whenClause.rest(1)

      genExpr(fnArgs, lvars, condExpr)
      print("  mov reg_b 0")
      print("  cmp")
      print("  je \(labelEndWhenHead)_\(whenIdx)")
      genStmts(fnArgs, lvars, stmts)
      print("  jmp \(labelEnd)")

      print("label \(labelEndWhenHead)_\(whenIdx)")
    }

    print("label \(labelEnd)")
  }

  func _genVmComment(_ comment: String) {
    let replaced = Utils.replace(comment, " ", "~")
    print("  _cmt \(replaced)")
  }

  func genVmComment(_ stmt: List) {
    let comment = stmt.getStr(1)
    _genVmComment(comment)
  }

  func genDebug() {
    print("  _debug")
  }

  func genStmt(_ fnArgs: [String], _ lvars: [String], _ stmt: List) {
    let head = stmt.getStr(0)
    switch head {
    case "return"  : genReturn( fnArgs, lvars, stmt)
    case "var"     : genVar(    fnArgs, lvars, stmt)
    case "set"     : genSet(    fnArgs, lvars, stmt)
    case "call"    : genCall(   fnArgs, lvars, stmt)
    case "call_set": genCallSet(fnArgs, lvars, stmt)
    case "while"   : genWhile(  fnArgs, lvars, stmt)
    case "case"    : genCase(   fnArgs, lvars, stmt)
    case "_cmt"    : genVmComment(stmt)
    case "_debug"  : genDebug()
    default:
      fatalError("unsupported (\(head))")
    }
  }

  func genStmts(_ fnArgs: [String], _ lvars: [String], _ stmts: List) {
    for i in 0..<stmts.count {
      let stmt = stmts.getList(i)
      genStmt(fnArgs, lvars, stmt)
    }
  }

  func genVar(_ fnArgs: [String], _ lvars: [String], _ stmt: List) {
    print("  add sp -1")

    if (stmt.count == 3) {
      let varName = stmt.getStr(1)
      let expr    = stmt.get(2)
      _genSet(fnArgs, lvars, varName, expr)
    }
  }

  func toNames(_ strList: List) -> [String] {
    var names: [String] = []
    for i in 0..<strList.count {
      let str = strList.getStr(i)
      names.append(str)
    }
    return names
  }

  func genFuncDef(_ fnDef: List) {
    let fnName = fnDef.getStr(1)
    let fnArgs = toNames(fnDef.getList(2))
    let stmts  = fnDef.getList(3)

    var lvars: [String] = [] // local variables

    print("label \(fnName)")
    asmPrologue()
    for i in 0..<stmts.count {
      let stmt = stmts.getList(i)
      let head = stmt.getStr(0)
      if head == "var" {
        let varName = stmt.getStr(1)
        lvars.append(varName)
        genVar(fnArgs, lvars, stmt)
      } else {
        genStmt(fnArgs, lvars, stmt)
      }
    }
    asmEpilogue()
    print("  ret")
  }

  func genTopStmts(_ ast: List) {
    for i in 1..<ast.count {
      let topStmt = ast.getList(i)
      genFuncDef(topStmt)
    }
  }

  func genBuiltinSetVram() {
    print("label set_vram")
    asmPrologue()
    print("  set_vram [bp:2] [bp:3]") // vram_addr value
    asmEpilogue()
    print("  ret")
  }

  func genBuiltinGetVram() {
    print("label get_vram")
    asmPrologue()
    print("  get_vram [bp:2] reg_a") // vram_addr dest
    asmEpilogue()
    print("  ret")
  }

  func codegen() {
    let ast = Json.parse(Utils.readStdinAll())

    print("  call main")
    print("  exit")
    genTopStmts(ast)

    print("#>builtins")
    genBuiltinSetVram()
    genBuiltinGetVram()
    print("#<builtins")
  }
}
