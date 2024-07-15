module std/data/json

import std/num/ddouble
import std/num/float64
import std/core/undiv
import std/pretty/pprint

pub type json
  JSNull
  JSBool(b: bool)
  JSString(string: string)
  JSNum(double: float64)
  JSInt(int: int)
  JSList(list: list<json>)
  JSObj(dict: list<(string,json)>)

fun char/quote(c: char): string
  match c
    '"' -> "\\\""
    '\\' -> "\\\\"
    '\n' -> "\\n"
    '\r' -> "\\r"
    '\t' -> "\\t"
    _ -> c.string

// quote essential and whitespace characters in a JSON string
fun string/quote(s: string): string
  s.list.map(quote).join

pub fun json/show(j: json): string
  match j
    JSNull -> "null"
    JSBool(b) -> if b then "true" else "false"
    JSString(s) -> "\"" ++ s.quote ++ "\""
    JSNum(s) -> s.show
    JSInt(i) -> i.show
    JSList(l) -> l.show(?show=fn(s) s.pretend-decreasing.show)
    JSObj(dict) -> "{" ++ dict.map(fn((k, v)) "\"" ++ k ++ "\":" ++ v.pretend-decreasing.show).join(",") ++ "}"

pub fun json/pretty(j: json): doc
  match j
    JSNull -> "null".text
    JSBool(b) -> if b then "true".text else "false".text
    JSString(s) -> ("\"" ++ s.quote ++ "\"").text
    JSNum(s) -> s.pretty
    JSInt(i) -> i.pretty
    JSList(l) -> "[".text |--| vcat(l.map(fn(i) i.pretend-decreasing.pretty).punctuate(",".text)).indent(2) |--| "]".text
    JSObj(dict) -> "{".text |--| vcat(dict.map(fn((k, v)) ("\"" ++ k ++ "\"").text |+| colon |+| v.pretend-decreasing.pretty).punctuate(",".text)).indent(2) |--| "}".text 

pub fun list/to-json(l: list<v>, ?to-json: v -> e json): e json
  JSList(l.map(to-json))

pub fun maybe/to-json(m: maybe<v>, ?to-json: v -> e json): e json
  match m
    Nothing -> JSNull
    Just(v) -> v.to-json 

pub fun string/to-json(s: string): json
  JSString(s)

pub fun num/to-json(d: ddouble): json
  JSNum(d.float64)

pub fun int/to-json(i: int): json
  JSInt(i)

pub fun bool/to-json(b: bool): json
  JSBool(b)

pub fun float64/to-json(f: float64): json
  JSNum(f)

pub fun id/to-json(j: json): json
  j

pub fun either/to-json(e: either<a,b>, key1: string, key2: string, ?a/to-json: a -> e json, ?b/to-json: b -> e json): e (string,json)
  match e
    Left(a) -> (key1, a.to-json)
    Right(b) -> (key2, b.to-json)

pub fun dict/to-json(d: list<(string, v)>, ?to-json: v -> e json): e json
  JSObj(d.map(fn((k, v)) (k, v.to-json)))

pub extend type exception-info
  JsonDeserializationException(d: json, path: string)

pub fun string/from-json(j: json, path: string): pure string
  match j
    JSString(s) -> s
    _ -> throw("Expecting string, got " ++ j.show, info=JsonDeserializationException(j, path))

pub fun bool/from-json(j: json, path: string): pure bool
  match j
    JSBool(b) -> b
    _ -> throw("Expecting bool, got " ++ j.show, info=JsonDeserializationException(j, path))

pub fun int/from-json(j: json, path: string): pure int
  match j
    JSNum(n) -> n.int
    JSInt(i) -> i
    _ -> throw("Expecting num (int or ddouble coerced to int), got " ++ j.show, info=JsonDeserializationException(j, path))

pub fun double/from-json(j: json, path: string): pure ddouble
  match j
    JSNum(d) -> d.ddouble
    JSInt(i) -> i.ddouble
    _ -> throw("Expecting ddouble, got " ++ j.show, info=JsonDeserializationException(j, path))

pub fun float64/from-json(j: json, path: string): pure float64
  match j
    JSNum(d) -> d
    JSInt(i) -> i.float64
    _ -> throw("Expecting float64, got " ++ j.show, info=JsonDeserializationException(j, path))

pub fun dict/from-json(l: list<(string, json)>, key: string, path: string, ?from-json: (j: json, path: string) -> pure a): pure a
  match l.lookup(fn(k) k == key)
    Nothing -> throw("Expecting " ++ key ++ " in " ++ JSObj(l).show, info=JsonDeserializationException(JSObj(l), path))
    Just(s) -> from-json(s, path=path ++ "->" ++ key)

pub fun either/from-json(l: list<(string, json)>, key1: string, key2: string, path: string, ?a/from-json: (j: json, path: string) -> pure a, ?b/from-json: (j: json, path: string) -> pure b): pure either<a,b> 
  match l.lookup(fn(k) k == key1)
    Just(s) -> Left(a/from-json(s, path=path ++ "->" ++ key1))
    Nothing -> match l.lookup(fn(k) k == key2)
      Just(s) -> Right(b/from-json(s, path=path ++ "->" ++ key2))
      Nothing -> throw("Expecting " ++ key1 ++ " or " ++ key2 ++ " in " ++ JSObj(l).show, info=JsonDeserializationException(JSObj(l), path))

pub fun to-dict/as-object(j: json, path: string): pure list<(string, json)>
  match j
    JSObj(d) -> d
    _ -> throw("Expecting object, got " ++ j.show, info=JsonDeserializationException(j, path))

pub fun list/from-json(j: json, path: string, ?from-json: (j: json, path: string) -> pure a): pure list<a>
  match j
    JSList(l) -> 
      l.map-indexed fn(i, j1)
        from-json(j1, path=path ++ "[" ++ i.show ++ "]")
    _ -> throw("Expecting list, got " ++ j.show, info=JsonDeserializationException(j, path))

pub fun maybe/from-json(j: json, path: string, ?from-json: (j: json, path: string) -> pure a): pure maybe<a>
  match j
    JSNull -> Nothing
    _ -> Just(from-json(j, path))

pub fun id/from-json(j: json, path: string): pure json
  j

pub fun parse(j: json, from-json: (j: json, path: string) -> <exn,exn|e> a): <exn|e> a
  match try({from-json(j, "root")})
    Ok(a) -> a
    Error(e) -> throw("Error parsing json\n\t" ++ e.message ++ " in path \"" ++ e.info.path ++ "\"")

pub fun path(e: exception-info): string
  match e
    JsonDeserializationException(_, path) -> path
    _ -> ""
