/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// This module provides a simple resizable vector implementation
module std/data/heap
import std/core-extras
import std/test
import std/core/unsafe

pub value struct heap<a>
  data : vector<a>
  size : int



fun push-down( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : heap<a>
  if h.on-min-level( i ) then
    h.min/push-down( i )
  else
    h.max/push-down( i )

inline fip fun min/push-down( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : heap<a>
  match h
    Heap( data, size) ->
      if data.has-children( i ) then
        val (m, grandchild?) = data.get-next-min( i )
        if grandchild? then
          if data.unsafe-idx( m.ssize_t ) < data.unsafe-idx( i.ssize_t ) then
            val m-item = data.unsafe-idx( m.ssize_t )
            val data' = data.unsafe-set( m, data.unsafe-idx( i.ssize_t ))
            data.unsafe-assign( i.ssize_t, m-item )
            if data'.unsafe-idx( m.ssize_t ) > data'.unsafe-idx( m.parent.ssize_t ) then
              val m-parent-item = data'.unsafe-idx( m.parent.ssize_t )
              data'.unsafe-assign( m.parent.ssize_t, m-item )
              data'.unsafe-assign( m.ssize_t, m-parent-item )
            Heap( data', size ).push-down( m )
        elif data.unsafe-idx( m.ssize_t ) < data.unsafe-idx( i.ssize_t ) then
          val m-item = data.unsafe-idx( m.ssize_t )
          val data' = data.unsafe-set( m, data.unsafe-idx( i.ssize_t ))
          data.unsafe-assign( i.ssize_t, m-item )
          Heap( data', size )
      else
        Heap( data, size )

inline fip fun max/push-down( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : heap<a>
  match h
    Heap( data, size) ->
      if data.has-children( i ) then
        val (m, grandchild?) = data.get-next-max( i )
        if grandchild? then
          if data.unsafe-idx( m.ssize_t ) > data.unsafe-idx( i.ssize_t ) then
            val m-item = data.unsafe-idx( m.ssize_t )
            val data' = data.unsafe-set( m, data.unsafe-idx( i.ssize_t ))
            data.unsafe-assign( i.ssize_t, m-item )
            if data'.unsafe-idx( m.ssize_t ) < data'.unsafe-idx( m.parent.ssize_t ) then
              val m-parent-item = data'.unsafe-idx( m.parent.ssize_t )
              data'.unsafe-assign( m.parent.ssize_t, m-item )
              data'.unsafe-assign( m.ssize_t, m-parent-item )
            Heap( data', size ).push-down( m )
        elif data.unsafe-idx( m.ssize_t ) > data.unsafe-idx( i.ssize_t ) then
          val m-item = data.unsafe-idx( m.ssize_t )
          val data' = data.unsafe-set( m, data.unsafe-idx( i.ssize_t ))
          data.unsafe-assign( i.ssize_t, m-item )
          Heap( data', size )
      else
        Heap( data, size )

fun push-up( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : heap<a>
  match h
    Heap(data, size) -> 
      if i.is-root.not then
        if h.on-min-level( i ) then
          if data.unsafe-idx( i.ssize_t ) < data.unsafe-idx( i.parent.ssize_t ) then
            val parent-item = data.unsafe-idx( i.parent.ssize_t )
            val data' = data.unsafe-set( i.parent, data.unsafe-idx( i.ssize_t ))
            data.unsafe-assign( i.ssize_t, parent-item )
            Heap( data', size ).max/push-up( i.parent )
          else
            Heap( data, size ).min/push-up( i )
        else
          if data.unsafe-idx( i.ssize_t ) > data.unsafe-idx( i.parent.ssize_t ) then
            val parent-item = data.unsafe-idx( i.parent.ssize_t )
            val data' = data.unsafe-set( i.parent, data.unsafe-idx( i.ssize_t ))
            data.unsafe-assign( i.ssize_t, parent-item )
            Heap( data', size ).min/push-up( i.parent )
          else
            Heap( data, size ).max/push-up( i )
      else
        Heap( data, size )

fun min/push-up( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : heap<a>
  val grandparent = h.data.get-grandparent( i )
  match grandparent
    Nothing -> h
    Just( g ) ->
      match h 
        Heap( data, size ) ->
          if data.unsafe-idx( i.ssize_t ) < data.unsafe-idx( g.ssize_t ) then
            val i-item = data.unsafe-idx( i.ssize_t )
            val data' = data.unsafe-set( i, data.unsafe-idx( g.ssize_t ))
            data.unsafe-assign( i.ssize_t, i-item )
            Heap( data', size ).min/push-up( g )
          else
            Heap( data, size )

fun max/push-up( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : heap<a>
  val grandparent = h.data.get-grandparent( i )
  match grandparent
    Nothing -> h
    Just( g ) ->
      match h 
        Heap( data, size ) ->
          if data.unsafe-idx( i.ssize_t ) > data.unsafe-idx( g.ssize_t ) then
            val i-item = data.unsafe-idx( i.ssize_t )
            val data' = data.unsafe-set( i, data.unsafe-idx( g.ssize_t ))
            data.unsafe-assign( i.ssize_t, i-item )
            Heap( data', size ).max/push-up( g )
          else
            Heap( data, size )


fun resizer( size : int ) : int
  if size == 0 then
    1
  else
    size * 2

pub fun insert( h : heap<a>, x : a, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool, ?resizer : (int) -> int ) : heap<a>
  match h
    Heap( data, size ) ->
      val vec = if size == data.length - 2 then
        data.realloc( resizer( size.ssize_t ) )
      else
        data
      val vec' = vec.unsafe-set( size, x)
      Heap( vec', size + 1 ).push-up( size )

pub fun delete-min( h : heap<a>, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : maybe<(a, heap<a>)>
  val min = h.data.unsafe-idx( 1.ssize_t )
  match h
    Heap( data, size ) ->
      val last = data.unsafe-idx( size.ssize_t )
      val data' = data.unsafe-set( 1, last )
      