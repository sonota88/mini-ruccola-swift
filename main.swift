let cmd = CommandLine.arguments[1]

switch cmd {
case "lex":
  Lexer().lex()
case "parse":
  Parser().parse()
case "codegen":
  CodeGenerator().codegen()
case "test_json":
  JsonTester().run()
default:
  fatalError("invalid command")
}
