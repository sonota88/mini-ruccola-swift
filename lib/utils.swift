import Glibc // print to stderr

class Utils {
  static func readStdinAll() -> String {
    return readStdinAllAsLines().joined()
  }

  static func readStdinAllAsLines() -> [String] {
    var lines: [String] = []
    while let line = readLine(strippingNewline: false) {
      lines.append(line)
    }
    return lines
  }

  static func _print(_ str: String) {
    print(str, terminator: "")
  }

  static func print_e(_ arg: String) {
    fputs(arg, stderr)
  }

  static func puts_e(_ arg: String) {
    print_e(arg)
    print_e("\n")
  }

  static func charAt(_ str: String, _ i: Int) -> Character? {
    let index = str.index(str.startIndex, offsetBy: i)
    return str[index]
  }

  static func indexOf(_ str: Substring, _ target: String) -> Int? {
    for i in 0..<str.count {
      if let c = charAt(String(str), i) {
        if String(c) == target {
          return i
        }
      }
    }

    return nil
  }

  static func substring(_ str: String, _ posFrom: Int, _ posTo: Int? = nil) -> Substring {
    let indexFrom = str.index(str.startIndex, offsetBy: posFrom)
    if posTo != nil {
      let indexTo = str.index(str.startIndex, offsetBy: posTo!)
      return str[indexFrom..<indexTo]
    } else {
      return str[indexFrom...]
    }
  }

  static func replace(_ str: String, _ target: String, _ replacement: String) -> String {
    var tempStr = str
    tempStr.replace(target, with: replacement)
    return tempStr
  }
}

class MyRegexp {
  var matchResult: Regex<(Substring, g1: Substring)>.Match?

  func match(_ str: Substring, _ pattern: String) -> Bool {
    let re = try! Regex(pattern, as: (Substring, g1: Substring).self)
    self.matchResult = str.firstMatch(of: re)
    if let _ = self.matchResult {
      return true
    } else {
      return false
    }
  }

  func getGroup1() -> String? {
    if let m = self.matchResult {
      return String(m.g1)
    } else {
      return nil
    }
  }
}
