/*----------------------------------------------------------------------------
   Copyright 2025, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// This module provides a simple list based buffer
module std/data/buffer

abstract value struct buffer<t>
  internal: list<t> = []

pub fun buffer<t>(): buffer<t>
  Buffer()

pub fun append<t>(b: buffer<t>, item: t): buffer<t>
  Buffer(Cons(item, b.internal))

pub fun list(b: buffer<t>): list<t>
  b.internal.reverse
