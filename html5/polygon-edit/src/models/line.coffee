'use strict'
root = exports ? this

LineFactory =
  id2line: {}

  get: (d1, d2) ->
    l = new Line(d1, d2)
    unless l.id of @id2line
      @id2line[l.id] = l

    @id2line[l.id]


class Line
  constructor: (d1, d2) ->
    if d1.id == d2.id
      throw new Error('invalid line')

    if d1.id < d2.id
      @d1 = d1
      @d2 = d2
    else
      @d1 = d2
      @d2 = d1
    @id = @d1.id + "," + @d2.id


  contains: (d) ->
    @d1 == d || @d2 == d


root.LineFactory = LineFactory
root.Line = Line
