/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/

module std/data/hash/hashset
import std/num/int64
import std/num/random


pub struct hash-set<v>
  data : vector<list<v>>
  amount : int
  seed : int64

