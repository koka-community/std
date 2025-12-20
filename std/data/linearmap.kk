/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/data/linearmap

pub value struct linearMap<k,v>
  internal: list<(k,v)> 

pub fun show(l: linearMap<k,v>, ?key/show: (k) -> e string, ?value/show: (v) -> e string): e string
  "{" ++ l.internal.map(fn((k,v)) k.show ++ ": " ++ v.show).join(",") ++ "}"

pub fun (==)(l1: linearMap<k,v>, l2: linearMap<k,v>, ?key/(==): (k, k) -> e bool, ?value/(==): (v, v) -> e bool): e bool
  l1.internal.length == l2.internal.length && l1.internal.all fn(x) 
    match l2.lookup(x.fst)
      Just(v') -> v' == x.snd
      Nothing -> False

pub fun map/lookup-index(m : linearMap<k,v>, k: k, ?(==): (k, k) -> e bool): e maybe<int>
  match m.internal.index-of(fn((kk, _)) kk == k)
    -1 -> Nothing
    i  -> Just(i)

pub fun map/elem-at(m : linearMap<k,v>, i: int): e maybe<(k, v)>
  m.internal[i]

pub fun map/contains-key(m: linearMap<k,v>, k: k, ?(==): (k, k) -> e bool): e bool
  m.internal.any(fn((kk, _)) kk == k)

pub fun key/contains(l: list<(k,v)>, k: k, ?(==): (k, k) -> e bool): e bool
  l.any(fn((kk, _)) kk == k)

pub fun map/update(l: linearMap<k,v>, k: k, b: v, f: (v, v) -> e v, ?(==): (k, k) -> e bool): e linearMap<k,v>
  val LinearMap(l') = l
  LinearMap(l'.update(k, b, f))

pub fun assoclist/update(l: list<(k,v)>, k: k, b: v, f: (v, v) -> e v, ?(==): (k, k) -> e bool): e list<(k,v)>
  match l
    Cons((kk, vv), rst) -> if k == kk then Cons((kk, f(vv, b)), rst) else Cons((kk, vv), rst.update(k, b, f))
    Nil -> Cons((k, b), Nil) 

pub fun list/lookup(m: list<(k,v)>, k: k, ?(==): (k, k) -> e bool): e maybe<v>
  match m
    Cons((kk, vv), rst) -> if kk == k then Just(vv) else rst.lookup(k)
    Nil -> Nothing

pub fun map/lookup(m: linearMap<k,v>, k: k, ?(==): (k, k) -> e bool): e maybe<v>
  m.internal.lookup(k)

pub fun map/get(m: linearMap<k,v>, k: k, ?(==): (k, k) -> e bool, ?kk-file-line: string): <exn|e> v  
  val mask/(==) = fn(k1,k2) mask<exn>{?(==)(k1,k2)}
  m.internal.lookup(k).unjust

pub fun list/get-default(l: list<(k,v)>, k: k, v: v, ?(==): (k, k) -> e bool): e v
  match l
    Cons((kk, vv), rst) -> if kk == k then vv else rst.get-default(k, v)
    Nil -> v

pub fun map/get-default(m: linearMap<k,v>, k: k, v: v, ?(==): (k, k) -> e bool): e v
  m.internal.get-default(k, v)

/// Overwrite any existing key with value
pub fun set(m: linearMap<k,v>, k: k, v: v, ?(==): (k, k) -> e bool): e linearMap<k,v>
  m.update(k, v, fn(_, v1) v1)

/// Add only if key is not present in the map
pub fun add(m: linearMap<k,v>, k: k, b: v, ?(==): (k, k) -> e bool): e linearMap<k,v>
  m.update(k, b, fn(x, _) x)

pub fun add-all(m: linearMap<k,v>, l: list<(k,v)>, ?(==): (k, k) -> e bool): e linearMap<k,v>
  match l
    Nil -> m
    Cons((k, v), rst) -> add-all(m.add(k, v), rst)

pub fun foldr(m: linearMap<k,v>, acc: a, f: (k, v, a) -> e a): e a
  m.internal.foldr(acc, fn((k, v), x) f(k, v, x))

// Cannot also map the keys unless we require a bijective function between keys
pub fun map/map(m: linearMap<k,v>, f: (k, v) -> e v1): e linearMap<k,v1> 
  val LinearMap(l) = m
  LinearMap(l.map(fn((k,v)) (k, f(k,v))))

pub fun unions(l: list<linearMap<k,v>>, ?(==): (k, k) -> e bool): e linearMap<k,v>
  val fst = l.head.default(LinearMap([]))
  l.foldl(fst, fn(x, y) x.add-all(y.internal))

pub fun list-add/(+)(l1: linearMap<k,v>, l2: list<(k,v)>, ?(==): (k, k) -> e bool): e linearMap<k,v>
  l1.add-all(l2)

pub fun union(l1: linearMap<k,v>, l2: linearMap<k,v>, ?(==): (k, k) -> e bool): e linearMap<k,v>
  l1.add-all(l2.internal)

pub fun filter(m: linearMap<k,v>, f: (k, v) -> e bool): e linearMap<k,v>
  val LinearMap(l) = m
  LinearMap(l.filter(fn((k,v)) f(k,v)))

pub fun remove(m: linearMap<k,v>, k: k, ?(==): (k, k) -> e bool): e linearMap<k,v>
  m.filter(fn(k1,_) !(k == k1))

pub fun keys(m: linearMap<k,v>): e list<k>
  m.internal.map(fn((k,_)) k)

pub fun values(m: linearMap<k,v>): e list<v>
  m.internal.map(fn((_,v)) v)

pub fun entries(m: linearMap<k,v>): e list<(k,v)>
  m.internal

pub fun list(m: linearMap<k,v>): e list<(k,v)>
  m.internal

pub fun remove-all(m: linearMap<k,v>, l: list<k>, ?(==): (k, k) -> e bool): e linearMap<k,v>
  m.filter(fn(k1,_) !l.any(fn(k2) k1 == k2))

pub fun union-with(m1: linearMap<k,v>, m2: linearMap<k,v>, f: (v, v) -> e v, ?(==): (k, k) -> e bool): e linearMap<k,v>
  m2.internal.foldl(m1, fn(x, (k, y)) x.update(k, y, f))

pub fun foreach(m: linearMap<k,v>, f: (k, v) -> e ()): e ()
  m.internal.foreach(fn((k,v)) f(k,v))
  