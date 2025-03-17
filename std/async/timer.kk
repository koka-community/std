/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/

module std/async/timer
pub import std/time/duration
pub import std/time/timestamp
import std/num/ddouble
import std/num/int64
import std/num/int32

extern import
  js file "inline/timer.js"

abstract struct timer (
  internal: any
)

// Sets a timeout for libuv / wasm / javscript / C# event loops
pub extern raw/set-timeout( cb : () -> io-noexn (), ms : int32 ) : io-noexn any
  cs "_Async.SetTimeout"
  js "setTimeout"
  c "kk_set_timeout"

// Clears a timeout for libuv / wasm / javscript / C# event loops
pub extern raw/clear-timeout( tid : any) : io-noexn ()
  cs "_Async.ClearTimeout"
  js "clearTimeout"
  c "kk_clear_timeout"

pub extern timer-init(): io-noexn timer
  js inline "_init_timer()"

// Start the timer. timeout and repeat are in milliseconds.
//
// If timeout is zero, the callback fires on the next event loop iteration.
// If repeat is non-zero, the callback fires first after timeout milliseconds and then repeatedly after repeat milliseconds.
pub extern timer-start(^t: timer, timeout: int64, repeat: int64, cb: () -> io-noexn ()): io-noexn error<()>
  js inline "_start_timer(#1,#2,#3,#4)"

pub extern timer-stop(t: timer): io-noexn ()
  js inline "_stop_timer(#1)"

// Stop the timer, and if it is repeating restart it using the repeat value as the timeout.
// If the timer has never been started before it returns UV_EINVAL
extern timer-again(^t: timer): io-noexn error<()>
  js inline ""

// Set the repeat interval value in milliseconds.
//
// The timer will be scheduled to run on the given interval,
// regardless of the callback execution duration, and will follow
// normal timer semantics in the case of a time-slice overrun.
//
// For example, if a 50ms repeating timer first runs for 17ms,
// it will be scheduled to run again 33ms later. If other tasks
// consume more than the 33ms following the first timer callback,
// then the next timer callback will run as soon as possible.
//
// NOTE: If the repeat value is set from a timer callback it does not immediately take effect.
// If the timer was non-repeating before, it will have been stopped. If it was repeating,
// then the old repeat value will have been used to schedule the next timeout
extern timer-set-repeat(^t: timer, repeat: int64): io-noexn ()
  js inline ""

extern timer-get-repeat(^t: timer): io-noexn int64
  js inline ""

// Get the timer due value or 0 if it has expired. -1 is returned on unsupported platforms
// The time is relative to uv_now()
extern timer-get-due-in(^t: timer): io-noexn int64
  js inline ""

// Creates a timer that repeats every `d` duration and calls `f` with the timer as argument.
//
// The timer stops repeating when `f` returns `False`.
pub fun timer(d: duration, f: (timer) -> io-noexn bool): io-noexn timer
  val ms = d.milli-seconds.int64
  val t = timer-init()
  t.timer-start(ms, ms) fn()
    if !f(t) then
      t.timer-stop()
    ()
  t
