module rbtree

import std/os/env
import std/num/random
import std/num/int32
import tree-common

pub type color
  Red
  Black

pub type rbtree<k,v>
  Leaf
  Node(color : color, left : rbtree<k,v>, key : k, value : v, right : rbtree<k,v>)

pub type root<k,v>
  Root(color : color, left : rbtree<k,v>, key : k, value : v, right : rbtree<k,v>)


// ---------------------------------------------------------
// show and print trees

pub fun render( t : rbtree<k,v>, ?key/show: (k) -> e string, ?value/show: (v) -> e string  ) : e render
  val minwidth = 3
  match t
    Leaf -> Render(0,[])
    Node(c,l,x,_,r) -> 
      beside(l.render,"-" ++ (x.show ++ "@" ++ c.showc).pad-left(minwidth) ++ "-",r.render)

pub fun show( t : rbtree<k,v> , ?key/show: (k) -> e string, ?value/show: (v) -> e string ) : e string
  t.render.lines.unlines

pub fun showc( c : color ) : string
  match c
    Red -> "r"
    Black -> "b"

pub fun show-trees( ts : list<rbtree<k,v>>, ?key/show: (k) -> e string, ?value/show: (v) -> e string ) : e string
  ts.map-indexed( fn(i,t) "rbtree<k,v> " ++ show(i+1) ++ ":\n\n" ++ t.show ).join("\n\n")

pub fun print( t : rbtree<k,v>, ?key/show: (k) -> <io|e> string, ?value/show: (v) -> <io|e> string ) : <io|e> ()
  t.show.println

pub fun print-trees( ts : list<rbtree<k,v>>, ?key/show: (k) -> <io|e> string, ?value/show: (v) -> <io|e> string ) : <io|e> ()
  ts.show-trees.println