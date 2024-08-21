import std/time/duration
import std/time/instant
import std/time/utc
import std/time/chrono
import std/num/ddouble

pub fun time(f: () -> <ndet,utc|e> a): <ndet,utc|e> a
  val start = now()
  val res = f()
  val end = now()
  trace("Time: start:" ++ start.show ++ " end:" ++ end.show ++ " diff:" ++ (end - start).show)
  res