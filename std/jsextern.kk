/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/

extern import
  js file "inline/jsextern.mjs"

struct jsobject<t>
  internal: any;

struct jsarray<t>
  internal: any;

// Basics for objects / arrays
inline extern ext/new-obj(): any
  js inline "({})"
inline extern ext/new-array(): any
  js inline "([])"
pub inline extern ext/set-null(a: any, key: string): ()
  js inline "#1[#2] = null"
pub inline extern ext/update-null(a: any, key: string): ()
  js inline "{...#1}[#2] = null"
inline extern ext/obj/copy(a: any): any
  js inline "{...#1}"
inline extern ext/arr/copy(a: any): any
  js inline "[...#1]"
inline extern ext/show(a: any): string
  js inline "JSON.stringify(#1)"

pub inline fun obj/new(): jsobject<t>
  Jsobject(new-obj())
pub inline fun arr/new(): jsarray<t>
  Jsarray(new-array())
pub inline fun obj/copy(a: jsobject<t>): jsobject<t>
  Jsobject(ext/obj/copy(a.internal))
pub inline fun arr/copy(a: jsarray<t>): jsarray<t>
  Jsarray(ext/arr/copy(a.internal))
pub inline fun obj/unsafe-as-array<s>(a: jsobject<t>): jsarray<s>
  Jsarray(a.internal)
pub inline fun maybeobj/unsafe-cast(a: maybe<jsobject<t>>): maybe<jsobject<s>>
  match a
    Just(x) -> Just(Jsobject(x.internal))
    Nothing -> Nothing
pub inline fun obj/unsafe-cast(a: jsobject<t>): jsobject<s>
  Jsobject(a.internal)
pub inline fun obj/show(a: jsobject<t>): string
  show(a.internal)
pub inline fun array/show(a: jsarray<t>): string
  show(a.internal)


// Object field operations for basic and compound types

// String fields
extern ext/get-mstring(a: any, key: string): maybe<string>
  js inline "maybeget(#1, #2)"
inline extern ext/get-string(a: any, key: string): string
  js inline "#1[#2]"
inline extern ext/set-string(a: any, key: string, value: string): ()
  js inline "#1[#2] = #3"
inline extern ext/update-string(a: any, key: string, value: string): any
  js inline "{...#1}[#2] = #3"

pub inline fun obj/get-mstring(a: jsobject<t>, key: string): maybe<string>
  get-mstring(a.internal, key)
pub inline fun obj/get-string(a: jsobject<t>, key: string): string
  get-string(a.internal, key)
pub inline fun obj/set-string(a: jsobject<t>, key: string, value: string): ()
  set-string(a.internal, key, value)
pub inline fun obj/update-string(a: jsobject<t>, key: string, value: string): jsobject<t>
  Jsobject(update-string(a.internal, key, value))

// Bool fields
extern ext/get-mbool(a: any, key: string): maybe<bool>
  js inline "maybeget(#1, #2)"
inline extern ext/get-bool(a: any, key: string): bool
  js inline "#1[#2]"
inline extern ext/set-bool(a: any, key: string, value: bool): ()
  js inline "#1[#2] = #3"
inline extern ext/update-bool(a: any, key: string, value: bool): any
  js inline "{...#1}[#2] = #3"

pub inline fun obj/get-mbool(a: jsobject<t>, key: string): maybe<bool>
  get-mbool(a.internal, key)
pub inline fun obj/get-bool(a: jsobject<t>, key: string): bool
  get-bool(a.internal, key)
pub fun obj/set-bool(a: jsobject<t>, key: string, value: bool): ()
  set-bool(a.internal, key, value)
pub inline fun obj/update-bool(a: jsobject<t>, key: string, value: bool): jsobject<t>
  Jsobject(update-bool(a.internal, key, value))

// Int fields
extern ext/get-mint(a: any, key: string): maybe<int>
  js inline "maybeget(#1, #2)"
inline extern ext/get-int(a: any, key: string): int
  js inline "#1[#2]"
inline extern ext/set-int(a: any, key: string, value: int): ()
  js inline "#1[#2] = #3"
inline extern ext/update-int(a: any, key: string, value: int): any
  js inline "{...#1}[#2] = #3"

pub inline fun obj/get-mint(a: jsobject<t>, key: string): maybe<int>
  get-mint(a.internal, key)
pub inline fun obj/get-int(a: jsobject<t>, key: string): int
  get-int(a.internal, key)
pub inline fun obj/set-int(a: jsobject<t>, key: string, value: int): ()
  set-int(a.internal, key, value)
pub inline fun obj/update-int(a: jsobject<t>, key: string, value: int): jsobject<t>
  Jsobject(update-int(a.internal, key, value))

// Float fields
extern ext/get-mfloat(a: any, key: string): maybe<float64>
  js inline "maybeget(#1, #2)"
inline extern ext/get-float(a: any, key: string): float64
  js inline "#1[#2]"
inline extern ext/set-float(a: any, key: string, value: float64): ()
  js inline "#1[#2] = #3"
inline extern ext/update-float(a: any, key: string, value: float64): any
  js inline "{...#1}[#2] = #3"

pub inline fun obj/get-mfloat(a: jsobject<t>, key: string): maybe<float64>
  get-mfloat(a.internal, key)
pub inline fun obj/get-float(a: jsobject<t>, key: string): float64
  get-float(a.internal, key)
pub inline fun obj/set-float(a: jsobject<t>, key: string, value: float64): ()
  set-float(a.internal, key, value)
pub inline fun obj/update-float(a: jsobject<t>, key: string, value: float64): jsobject<t>
  Jsobject(update-float(a.internal, key, value))

// Object fields
extern ext/get-mobj(a: any, key: string): maybe<any>
  js inline "maybeget(#1, #2)"
inline extern ext/get-obj(a: any, key: string): any
  js inline "#1[#2]"
inline extern ext/set-obj(a: any, key: string, value: any): ()
  js inline "#1[#2] = #3"
inline extern ext/update-obj(a: any, key: string, value: any): any
  js inline "{...#1}[#2] = #3"

pub inline fun obj/get-mobj(a: jsobject<t>, key: string): maybe<jsobject<s>>
  get-mobj(a.internal, key).map(Jsobject)
pub inline fun obj/get-obj(a: jsobject<t>, key: string): jsobject<s>
  Jsobject(a.internal.get-obj(key))
pub inline fun obj/set-obj(a: jsobject<t>, key: string, value: jsobject<s>): ()
  set-obj(a.internal, key, value.internal)
pub inline fun obj/update-obj(a: jsobject<t>, key: string, value: jsobject<s>): jsobject<t>
  Jsobject(update-obj(a.internal, key, value.internal))

// Array fields
pub inline fun obj/get-marray(a: jsobject<t>, key: string): maybe<jsarray<s>>
  match a.internal.get-mobj(key)
    Just(internal) -> Just(Jsarray(internal))
    Nothing -> Nothing
pub inline fun arr/get-array(a: jsobject<t>, key: string): jsarray<s>
  Jsarray(a.internal.get-obj(key))
pub inline fun obj/set-array(a: jsobject<t>, key: string, value: jsarray<s>): ()
  set-obj(a.internal, key, value.internal)
pub inline fun obj/update-array(a: jsobject<t>, key: string, value: jsarray<s>): jsobject<t>
  Jsobject(update-obj(a.internal, key, value.internal))

// Misc object operations
extern ext/unsafe-as-string(a: any): string
  js inline "#1"
pub inline fun obj/unsafe-as-string(a: jsobject<t>): string
  a.internal.unsafe-as-string()
extern ext/unsafe-as-int(a: any): int
  js inline "#1"
pub inline fun obj/unsafe-as-int(a: jsobject<t>): int
  a.internal.unsafe-as-int()
extern ext/unsafe-as-float(a: any): float64
  js inline "#1"
pub inline fun obj/unsafe-as-float(a: jsobject<t>): float64
  a.internal.unsafe-as-float()
extern ext/unsafe-as-bool(a: any): bool
  js inline "#1"
pub inline fun obj/unsafe-as-bool(a: jsobject<t>): bool
  a.internal.unsafe-as-bool()

// Indexing operations
pub inline fun obj/int/@index(a: jsobject<t>, index: string): int
  a.get-int(index)
pub inline fun obj/mint/@index(a: jsobject<t>, index: string): maybe<int>
  a.get-mint(index)
pub inline fun obj/float/@index(a: jsobject<t>, index: string): float64
  a.get-float(index)
pub inline fun obj/mfloat/@index(a: jsobject<t>, index: string): maybe<float64>
  a.get-mfloat(index)
pub inline fun obj/bool/@index(a: jsobject<t>, index: string): bool
  a.get-bool(index)
pub inline fun obj/mbool/@index(a: jsobject<t>, index: string): maybe<bool>
  a.get-mbool(index)
pub inline fun obj/string/@index(a: jsobject<t>, index: string): string
  a.get-string(index)
pub inline fun obj/mstring/@index(a: jsobject<t>, index: string): maybe<string>
  a.get-mstring(index)
pub inline fun obj/obj/@index(a: jsobject<t>, index: string): jsobject<s>
  a.get-obj(index)
pub inline fun obj/mobj/@index(a: jsobject<t>, index: string): maybe<jsobject<s>>
  a.get-mobj(index)
pub inline fun obj/array/@index(a: jsobject<t>, index: string): jsarray<s>
  a.get-array(index)
pub inline fun obj/int/@assign(a: jsobject<t>, index: string, value: int): ()
  a.set-int(index, value)
pub inline fun obj/float/@assign(a: jsobject<t>, index: string, value: float64): ()
  a.set-float(index, value)
pub inline fun obj/bool/@assign(a: jsobject<t>, index: string, value: bool): ()
  a.set-bool(index, value)
pub inline fun obj/string/@assign(a: jsobject<t>, index: string, value: string): ()
  a.set-string(index, value)
pub inline fun obj/obj/@assign(a: jsobject<t>, index: string, value: jsobject<s>): ()
  a.set-obj(index, value)
pub inline fun obj/array/@assign(a: jsobject<t>, index: string, value: jsarray<s>): ()
  a.set-array(index, value)

// Object operations
// entries returns an array of [key, value] pairs
inline extern ext/entries(a: any): jsarray<jsarray<jsobject<any>>>
  js inline "Object.entries(#1)"
pub inline fun obj/entries(a: jsobject<t>): list<(string, jsobject<any>)>
  val entries:jsarray<jsarray<jsobject<any>>> = a.internal.entries() 
  val len = entries.length
  list(0, len - 1).map fn(i)
    val jsobj: jsarray<jsobject<any>> = entries[i]
    val key = jsobj[0].unsafe-as-string
    val value = jsobj[1]
    (key, value)


// Array operations
inline extern any/@index(a: any, index: int): any
  js inline "#1[#2]"
inline extern string/@index(a: any, index: int): string
  js inline "#1[#2]"
inline extern int/@index(a: any, index: int): int
  js inline "#1[#2]"
inline extern float/@index(a: any, index: int): float64
  js inline "#1[#2]"
inline extern bool/@index(a: any, index: int): bool
  js inline "#1[#2]"
inline extern any/@assign(a: any, index: int, value: any): ()
  js inline "#1[#2] = #3"
inline extern string/@assign(a: any, index: int, value: string): ()
  js inline "#1[#2] = #3"
inline extern int/@assign(a: any, index: int, value: int): ()
  js inline "#1[#2] = #3"
inline extern float/@assign(a: any, index: int, value: float64): ()
  js inline "#1[#2] = #3"
inline extern bool/@assign(a: any, index: int, value: bool): ()
  js inline "#1[#2] = #3"

pub inline fun objarray/@index(a: jsarray<jsobject<t>>, index: int): jsobject<t>
  Jsobject(a.internal[index])
pub inline fun jsarray/@index(a: jsarray<jsarray<t>>, index: int): jsarray<t>
  Jsarray(a.internal[index])
pub inline fun strarray/@index(a: jsarray<string>, index: int): string
  a.internal[index]
pub inline fun intarray/@index(a: jsarray<int>, index: int): int
  a.internal[index]
pub inline fun floatarray/@index(a: jsarray<float64>, index: int): float64
  a.internal[index]
pub inline fun boolarray/@index(a: jsarray<bool>, index: int): bool
  a.internal[index]
pub inline fun objarray/@assign(a: jsarray<jsobject<t>>, index: int, value: jsobject<t>): ()
  a.internal.@assign(index, value.internal)
pub inline fun jsarray/@assign(a: jsarray<jsobject<t>>, index: int, value: jsarray<t>): ()
  a.internal.@assign(index, value.internal)
pub inline fun strarray/@assign(a: jsarray<string>, index: int, value: string): ()
  a.internal.@assign(index, value)
pub inline fun intarray/@assign(a: jsarray<int>, index: int, value: int): ()
  a.internal.@assign(index, value)
pub inline fun floatarray/@assign(a: jsarray<float64>, index: int, value: float64): ()
  a.internal.@assign(index, value)
pub inline fun boolarray/@assign(a: jsarray<bool>, index: int, value: bool): ()
  a.internal.@assign(index, value)

// More array methods
inline extern ext/length(a: any): int
  js inline "#1.length"
pub inline fun arr/length(a: jsarray<t>): int
  a.internal.length()
