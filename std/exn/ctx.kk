// TODO: uncomment after https://github.com/koka-lang/koka/issues/711
// module std/exn/ctx

import std/core/exn
import std/core-extras

// A module for extending exceptions with a contextual trace.
// This is similar to a stack trace, except it contains
// only explicitly annotated information.
// This module is inspired by the `anyhow` crate from rust
type msg
  Lazy(f: () -> string)
  Strict(s: string)

fun msg/show(msg: msg)
  match msg
    Strict(s) -> s
    Lazy(f) -> f()

struct error-ctx
  base: exception
  chain: list<msg>

extend type exception-info
  TraceCtx(error: error-ctx)

fun to-ctx(e: exception): error-ctx
  match e.info
    TraceCtx(error: error-ctx) -> error
    _ -> Error-ctx(e, [])

// get the root exception, removing any TraceCtx layers
pub fun root(e: exception): div exception
  match e.info
    TraceCtx(ectx: error-ctx) -> root(ectx.base)
    _ -> e

fun value/add-trace(e: exception, desc: msg): exception
  val ectx = e.to-ctx
  Exception(e.message, TraceCtx(ectx(chain = Cons(desc, ectx.chain))))

// add contextual information if action fails
pub fun lazy/error-ctx(desc: () -> string, action: () -> <exn|e> a): <exn|e> a
  with handler<exn>
    final ctl throw-exn(e) { throw-exn(e.add-trace(Lazy(desc))) }
  mask behind <exn> { action() }

// add contextual information if action fails
pub fun string/error-ctx(desc: string, action: () -> <exn|e> a): <exn|e> a
  with handler<exn>
    final ctl throw-exn(e) { throw-exn(e.add-trace(Strict(desc))) }
  mask behind <exn> { action() }

// Get a list of messages, from the outermost
// context up to the innermost exception message
pub fun ctx-list(e: exception): list<string>
  e.to-ctx.chain.map(show) ++ [e.message]

// show exception with full contextual trace
pub fun show-with-ctx(e: exception): string
  var result := "Error: "
  match e.ctx-list
    [] -> () // impossible
    Cons(outer, []) ->
      result := result ++ outer

    Cons(outer, chain) ->
      result := result ++ outer
      result := result ++ "\n\nCaused by:"
      if chain.length == 1 then
        chain.foreach fn(m)
          result := result ++ "\n  " ++ m
      else
        chain.foreach-indexed fn(i, m)
          result := result ++ "\n  " ++ (i+1).show ++ ". " ++ m
  result

// Wrap an exception effect to report it and exit the process on
// failure. Ideal for use as `with trace-handler` on the first line of
// a `main` function
pub fun error-ctx-handler(action: () -> <io|e> ()): <io-noexn|e> ()
  try(action) fn(e)
    print("Uncaught exception: ")
    println(e.show-with-ctx)
    exit(-1)

// demonstrate trace-handler
fun example()
  with error-ctx-handler
  with error-ctx("outer")
  throw("inner")
