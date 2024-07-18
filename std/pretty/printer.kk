/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the Apache License, Version 2.0 ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/

module std/pretty/printer

import std/os/path
import std/os/file
import std/os/env

pub fun is-windows()
  get-os-name() == "windows"

//--------------------------------------------------------------------------
//  Printer
//--------------------------------------------------------------------------
// A printer is an abstraction for something where we can send
// character output to.
pub linear effect printer
  fun write(text: string): ()
  fun write-ln(text: string): ()
  fun flush(): ()

// A colored printer has additional coloring and formatting options
pub linear effect coloredPrinter
  fun set-color(c: color): ()
  fun set-back-color(c: color): ()
  fun set-reverse(b: bool): ()
  fun set-underline(b: bool): ()
  fun set-color-settings(s: print-color-settings): ()

//--------------------------------------------------------------------------
//  Interface
//--------------------------------------------------------------------------
// Available colors on a console. Normally, background colors are
// converted to their /dark/ variant.
pub type color
  Black
  DarkRed
  DarkGreen
  DarkYellow
  DarkBlue
  DarkMagenta
  DarkCyan
  Gray
  DarkGray
  Red
  Green
  Yellow
  Blue
  Magenta
  Cyan
  White
  ColorDefault

//--------------------------------------------------------------------------
//  Simple monochrome printer
//--------------------------------------------------------------------------}
pub val no-color-printer = handler
  fun set-color(c: color) ()
  fun set-back-color(c: color) ()
  fun set-reverse(b: bool) ()
  fun set-underline(b: bool) ()
  fun set-color-settings(s: print-color-settings) ()

// On windows, we cannot print unicode characters :-(
pub fun sanitize(s: string): <ndet> string
  match is-windows()
    False -> s
    True -> s.map() fn (x) {
        if (x > '~') then '?'
        else x
      }

pub val mono-printer = handler
  fun write(s) s.sanitize().print()
  fun write-ln(s) s.sanitize().println()
  fun flush() ()

//--------------------------------------------------------------------------
//  Simple File printer
//--------------------------------------------------------------------------}
// Use a file printer that ignores colors. Appends, or creates the file
pub fun file-printer(file-path: string, action)
  var f := read-text-file(file-path.path)
  handle action
    fun write(s) f := f ++ s
    fun write-ln(s) f := f ++ s ++ "\n"
    fun flush() try{write-text-file(file-path.path, f)}.default(())

// Use a file printer that ignores colors. Creates or overwrites the file
pub fun new-file-printer(file-path: string, action)
  var f := ""
  handle action
    fun write(s) f := f ++ s
    fun write-ln(s) f := f ++ s ++ "\n"
    fun flush() try{write-text-file(file-path.path, f)}.default(())


pub fun string-printer(action: () -> <printer|e> ()): e string
  var res := ""
  with handler
    fun write(s) res := res ++ s
    fun write-ln(s) res := res ++ s ++ "\n"
    fun flush() ()
  mask<local>{action()}
  res

// --------------------------------------------------------------------------
//  Standard ANSI escape sequences
// --------------------------------------------------------------------------}
// Use a color printer that uses ANSI escape sequences.
pub effect val color-settings: print-color-settings

pub struct print-color-settings
  fcolor: color = ColorDefault
  bcolor: color = ColorDefault
  invert: bool = False
  underline: bool = False

pub fun ansi-printer(action)
  with val color-settings = Print-color-settings()
  handle action
    fun write(s) s.print()
    fun write-ln(s) s.println()
    fun flush() ()

pub fun ansi-string-printer(action)
  with val color-settings = Print-color-settings()
  string-printer(action)

pub fun ansi-with-console(console: print-color-settings, action)
  val old = color-settings
  with finally fn()
    ansi-escape(seq-set-console(console, old)).write()
  with override val color-settings = console
  ansi-escape(reset(console)).write()
  action()

pub fun ansi-with-color(c: color, action)
  ansi-with-console(color-settings(fcolor=c), action)

pub fun ansi-escape(color-settings: string)
  "\x1B[" ++ color-settings ++ "m"

pub fun seq-reset()
  "0;"

pub fun seq-underline(u: bool): string
  if (u) then "4;" else ""

pub fun seq-reverse(r: bool): string
  if (r) then "7;" else ""

pub fun seq-bold(b: bool): string
  if (b) then "1;" else ""

pub fun seq-color(back: bool, c: color): string
  if (back) then (c.ansi-color + 10).show
  else c.ansi-color.show

pub fun reset(new: print-color-settings)
  seq-reset() ++ 
  seq-reverse(new.invert) ++ seq-underline(new.underline) ++ 
  seq-color(False, new.fcolor) ++ ";" ++ seq-color(True, new.bcolor) 

pub fun diff(a: print-color-settings, b: print-color-settings)
  val r = if (a.invert != b.invert) then seq-reverse(b.invert) else ""
  val u = if (a.underline != b.underline) then seq-underline(b.underline) else ""
  val f = if (a.fcolor != b.fcolor) then seq-color(False, b.fcolor) else ""
  val back = if (a.bcolor != b.bcolor) then seq-color(True, b.bcolor) else ""
  val f-back-sep = if (f != "" && back != "") then ";" else "";
  r ++ u ++ f ++ f-back-sep ++ back

pub fun ansi-color(c: color): int
  val idx = match c
    Black -> 0
    DarkRed -> 1
    DarkGreen -> 2
    DarkYellow -> 3
    DarkBlue -> 4
    DarkMagenta -> 5
    DarkCyan -> 6
    Gray -> 7 
    DarkGray -> 8
    Red -> 9
    Green -> 10
    Yellow -> 11
    Blue -> 12
    Magenta -> 13
    Cyan -> 14
    White -> 15
    ColorDefault -> 16
  if (idx < 8) then idx + 30
  else if (idx < 16) then 90 + idx - 8
  else 39

pub fun (==) (a: color, b: color): bool
  a.ansi-color == b.ansi-color

pub fun (!=) (a: color, b: color): bool
  a.ansi-color != b.ansi-color

pub fun seq-set-console(old: print-color-settings, new: print-color-settings)
  if (old.invert && !new.invert) then reset(new)
  else if (old.underline && !new.underline) then reset(new)
  else diff(old, new)

val consolePrinter = handler
  fun write(s) s.sanitize().print()
  fun write-ln(s) s.sanitize().println()
  fun flush() ()

pub fun htmlPrinter(action)
  var html := ""
  handle action
    fun write(s) html := s.htmlEscape()
    fun write-ln(s) html := s.htmlEscape() ++ "\n"
    fun flush() html.println()

pub fun htmlSpan(s: string): <color-settings> string
  // "<span style='" ++ prop ++ ":" ++ v ++ "'>" ++ s ++ "</span>"
  ""

pub fun htmlEscape(s: string): string
  val r = s.split("").map fn(c)
    match c
      "<" -> "&lt;"
      ">" -> "&gt;"
      "&" -> "&amp;"
      "\"" -> "&quot;"
      "\'" -> "&apos;"
      _ -> c
  r.join()

/// Test of printer features
// fun main(): <console, exn, fsys, ndet> ()
//   with consolePrinter
//   "hi\xFF".write-ln() // Will not print unicode on Windows
//   with monoPrinter
//   "hi\xAA".write-ln() // Also will get rid of unicode on Windows
//   with newFilePrinter("/tmp/tmp1.txt")
//   "new".write()
//   " file".write-ln()
//   flush()
//   with filePrinter("/tmp/tmp1.txt")
//   "hi".write()
//   " there".write-ln()
//   flush()
//   with ansiPrinter
//   with override val color-settings = Print-color-settings(invert=True)
//   "hello".ansiWithColor(Red)
//   "world".ansiWithColor(Blue)
//   with override val color-settings = Print-color-settings(underline=True)
//   "hello".ansiWithColor(Red)
//   "world".ansiWithColor(Blue)
//   with override val color-settings = Print-color-settings()
//   "hello".ansiWithColor(Red)
//   "world".ansiWithColor(Blue)
//   ansiWithConsole(Print-color-settings(fcolor=Green))
//     "hello ".write()
//     "world!".write-ln()
//   ansiWithConsole(Print-color-settings(fcolor=DarkYellow, invert=True))
//     "This is crazy, ".write()
//     ansiWithConsole(Print-color-settings(fcolor=DarkCyan, underline=True))
//       "but it's ok".write-ln()




