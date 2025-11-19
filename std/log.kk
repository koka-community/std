import std/data/linearmap

linear effect log
  fun log(name: string, message: string): ()

fun with-logs(action: () -> <log|e> ()): e ()
  var logs := LinearMap([])
  with handler
    fun log(name, message)
      logs := logs.set(name, logs.lookup(name).default("") ++ message ++ "\n")
  action()
