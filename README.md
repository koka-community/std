Includes Testing, Datastructures, Ansi Printer, and Pretty Printing, along with some basic core extras missing from the standard library.

The ansi printer and pretty printer were translated from Koka's Haskell compiler.

Some of this code is a stopgap measure until we have more efficient datastructures integrated into Koka.
For example `linearMap` and `linearSet` are inefficient versions of `map` and `set` interfaces, but useful for building programs while we don't have official `map`s and `set`s.
