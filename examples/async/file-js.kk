import std/jsextern

extern import
  js file "file-js.js"

extern ext/read-file(path: string): io-noexn any
  js inline "readfile(#1)"

fun js/read-file(path: string): <io,async> string
  Jspromise(read-file(path)).wrap.unsafe-as-string

// In VSCode Cmd/Ctrl+Shift+P Then select Koka: Compilation target, and switch to nodejs, prior to running this
fun main()
  val res = try
    js/read-file("examples/async/file-js.kk").println
  ()
