/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/

pub import async

extern import
  js file "inline/jsextern.mjs"

pub struct jsobject<t>
  internal: any;

pub struct jsarray<t>
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
inline extern ext/is-bool(a: any): bool
  js inline "typeof #1 === 'boolean'"
inline extern ext/is-int(a: any): bool
  js inline "Number.isInteger(#1)"
inline extern ext/is-num(a: any): bool
  js inline "typeof #1 === 'number'"
inline extern ext/is-string(a: any): bool
  js inline "typeof #1 === 'string'"
inline extern any/is-array(a: any): bool
  js inline "Array.isArray(#1)"
pub inline fun arr/is-array(a: jsobject<t>): bool
  is-array(a.internal)

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
pub inline fun obj/is-bool(a: jsobject<t>): bool
  is-bool(a.internal)
pub inline fun obj/is-int(a: jsobject<t>): bool
  is-int(a.internal)
pub inline fun obj/is-num(a: jsobject<t>): bool
  is-num(a.internal)
pub inline fun obj/is-string(a: jsobject<t>): bool
  is-string(a.internal)

// A marker function that t is a subtype of s
pub alias is-subtype<t,s> = (jsobject<t>, jsobject<s>) -> bool;
// Cast to a supertype, given the evidence that t is a subtype of s
pub inline fun obj/supertype-cast(a: jsobject<t>, ?is-subtype: is-subtype<t,s>): jsobject<s>
  Jsobject(a.internal)
pub inline fun unit/supertype-cast(a: jsobject<t>): jsobject<t>
  a
// Cast to a subtype, given the evidence that t is a supertype of s
pub inline fun obj/subtype-cast(a: jsobject<t>, ?is-subtype: is-subtype<s,t>): jsobject<s>
  Jsobject(a.internal)
pub inline fun unit/subtype-cast(a: jsobject<t>): jsobject<t>
  a
// Transitive closure for evidence
pub inline fun trans/is-subtype<m>(a: jsobject<t>, b: jsobject<s>, ?a/is-subtype: is-subtype<t,m>, ?b/is-subtype: is-subtype<m,s>): bool
  True
// An object of the same type is trivially a subtype of itself
pub inline fun unit/is-subtype(a: jsobject<t>, b: jsobject<t>): bool
  True
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
inline extern ext/field/is-bool(a: any, key: string): bool
  js inline "typeof #1[#2] === 'boolean'"

pub inline fun field/is-bool(a: jsobject<t>, key: string): bool
  is-bool(a.internal, key)
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
inline extern ext/field/is-int(a: any, key: string): bool
  js inline "Number.isInteger(#1[#2])"

pub inline fun field/is-int(a: jsobject<t>, key: string): bool
  is-int(a.internal, key)
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
inline extern ext/field/is-float(a: any, key: string): bool
  js inline "typeof #1[#2] === 'number'"

pub inline fun field/is-num(a: jsobject<t>, key: string): bool
  is-float(a.internal, key)
pub inline fun field/is-float(a: jsobject<t>, key: string): bool
  is-float(a.internal, key)
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
inline extern has-key(a: any, key: string): bool
  js inline "#1[#2] !== undefined"
pub inline fun obj/has-key(a: jsobject<t>, key: string): bool
  has-key(a.internal, key)
inline extern ext/unsafe-as-string(a: any): string
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
inline extern ext/entries(a: any): any
  js inline "Object.entries(#1)"
pub inline fun obj/entries(a: jsobject<t>): list<(string, jsobject<any>)>
  val entries:jsarray<jsarray<jsobject<any>>> = JsArray(a.internal.entries()) 
  val len = entries.length
  list(0, len - 1).map fn(i)
    val jsobj: jsarray<jsobject<any>> = entries[i]
    val key = jsobj[0].unsafe-as-string
    val value = jsobj[1]
    (key, value)

inline extern ext/keys(a: any): any
  js inline "Object.keys(#1)"
pub inline fun obj/keys(a: jsobject<t>): jsarray<string>
  JsArray(a.internal.keys)

inline extern ext/values(a: any): any
  js inline "Object.values(#1)"
pub inline fun obj/values(a: jsobject<t>): jsarray<s>
  JsArray(a.internal.values)

// Array operations
inline extern any/@index(a: any, index: int): any
  js inline "#1[#2]"
inline extern many/@index(a: any, index: int): maybe<any>
  js inline "maybeget(#1, #2)"
inline extern string/@index(a: any, index: int): string
  js inline "#1[#2]"
inline extern mstring/@index(a: any, index: int): maybe<string>
  js inline "maybeget(#1, #2)"
inline extern int/@index(a: any, index: int): int
  js inline "#1[#2]"
inline extern mint/@index(a: any, index: int): maybe<int>
  js inline "maybeget(#1, #2)"
inline extern float/@index(a: any, index: int): float64
  js inline "#1[#2]"
inline extern mfloat/@index(a: any, index: int): maybe<float64>
  js inline "maybeget(#1, #2)"
inline extern bool/@index(a: any, index: int): bool
  js inline "#1[#2]" 
inline extern mbool/@index(a: any, index: int): maybe<bool>
  js inline "maybeget(#1, #2)"
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
pub inline fun mobjarray/@index(a: jsarray<maybe<jsobject<t>>>, index: int): maybe<jsobject<t>>
  a.internal.many/@index(index).map(Jsobject)
pub inline fun jsarray/@index(a: jsarray<jsarray<t>>, index: int): jsarray<t>
  Jsarray(a.internal[index])
pub inline fun mjsarray/@index(a: jsarray<int>, index: int): maybe<jsarray<t>>
  a.internal.many/@index(index).map(Jsarray)
pub inline fun strarray/@index(a: jsarray<string>, index: int): string
  a.internal[index]
pub inline fun mstrarray/@index(a: jsarray<maybe<string>>, index: int): maybe<string>
  a.internal[index]
pub inline fun intarray/@index(a: jsarray<int>, index: int): int
  a.internal[index]
pub inline fun mintarray/@index(a: jsarray<maybe<int>>, index: int): maybe<int>
  a.internal[index]
pub inline fun floatarray/@index(a: jsarray<float64>, index: int): float64
  a.internal[index]
pub inline fun mfloatarray/@index(a: jsarray<maybe<float64>>, index: int): maybe<float64>
  a.internal[index]
pub inline fun boolarray/@index(a: jsarray<bool>, index: int): bool
  a.internal[index]
pub inline fun mboolarray/@index(a: jsarray<maybe<bool>>, index: int): maybe<bool>
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

pub inline fun objarr/list(a: jsarray<jsobject<t>>): list<jsobject<t>>
  list(0, a.length() - 1).map fn(i) a[i]
pub inline fun mobjarr/list(a: jsarray<maybe<jsobject<t>>>): list<maybe<jsobject<t>>>
  list(0, a.length() - 1).map fn(i) a[i]
pub inline fun arrarr/list(a: jsarray<jsarray<t>>): list<jsarray<t>>
  list(0, a.length() - 1).map fn(i) a[i]
pub inline fun strarray/list(a: jsarray<string>): list<string>
  list(0, a.length() - 1).map fn(i) a[i]
pub inline fun intarray/list(a: jsarray<int>): list<int>
  list(0, a.length() - 1).map fn(i) a[i]
pub inline fun floatarray/list(a: jsarray<float64>): list<float64>
  list(0, a.length() - 1).map fn(i) a[i]
pub inline fun boolarray/list(a: jsarray<bool>): list<bool>
  list(0, a.length() - 1).map fn(i) a[i]

pub struct jspromise<t>
  internal: any;

abstract extend type exception-info
  con JSError(error: jsobject<any>)

pub fun js-promise/wrap(promise: jspromise<t>): asyncx jsobject<t>
  setup/await fn(cb)
    promise.on-resolve(fn(output) cb(Ok(output)), fn(error) cb(Error(Exception("Exception in promise.", JSError(error)))))
    Nothing

pub inline fun js-promise/resolve(value: jsobject<t>): jspromise<t>
  Jspromise(any/resolve(value.internal))

inline extern any/resolve(value: any): any
  js inline "Promise.resolve(#1)"

pub inline fun js-promise/on-resolve(value: jspromise<t>, success: (jsobject<t>) -> io-noexn (), error: (jsobject<e>) -> io-noexn ()): io-noexn ()
  value.internal.any/on-resolve(fn(output) success(Jsobject(output)), fn(err) error(Jsobject(err)))

inline extern any/on-resolve(promise: any, success: (any) -> io-noexn (), error: (any) -> io-noexn ()): io-noexn ()
  js inline "#1.then(#2).catch(#3)"