class JsonTester {
  func run() {
    let json = Utils.readStdinAll()
    let list = Json.parse(json)
    Json.printList(list)
  }
}
