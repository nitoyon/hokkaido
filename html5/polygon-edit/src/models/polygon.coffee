'use strict'
root = exports ? this

LineFactory = require('./line').LineFactory
LineFactory ?= @LineFactory
{Dot} = require('./dot')
Dot ?= @Dot
EventEmitter2 = require('eventemitter2').EventEmitter2
EventEmitter2 ?= @EventEmitter2

class PolygonList
  constructor: ->
    @list = []
    @addingPolygon = null

  createAddingPolygon: ->
    unless @addingPolygon is null
      false
    else
      @addingPolygon = new Polygon()
      @addingPolygon.isClose = false
      @add(@addingPolygon)
      return true

  add: (polygon) ->
    @list.push polygon
    polygon.once 'exit', (p) => @del(p)

  del: (polygon) ->
    index = @list.indexOf polygon
    if index >= 0
      @list.splice index, 1

    if @addingPolygon == polygon
      @addingPolygon = null

  getOuterLines: ->
    lines = {}
    @list.forEach (p) ->
      p.lines.forEach (l) ->
        lines[l.id] = l

    (value for key, value of lines)

  getDots: ->
    dots = {}
    @list.forEach (p) ->
      p.dots.forEach (d) ->
        dots[d.id] = d

    (value for key, value of dots)

  serialize: ->
    @list.map (polygon) -> polygon.serialize()

  deserialize: (data) ->
    dotmap = {}

    data.forEach (entry) =>
      polygon = new Polygon()
      return if entry.length == 0

      polygon.deserialize entry, dotmap
      @add polygon

  splitLine: (line, dot) ->
    for p in @list
      p.splitLine line, dot

  closeAddingPolygon: ->
    if @addingPolygon && @addingPolygon.lines.length > 0
      @addingPolygon.close()
    @addingPolygon = null


class Polygon extends EventEmitter2
  @id = 1

  constructor: (dots...)->
    @dots = []
    @lines = []
    @innerLines = []
    @lastDot = null
    @id = @constructor.id++
    @isClose = true

    @add dot for dot in dots
    @updateLines()

  @isNeighborDot: (dots, d1, d2) ->
    i1 = dots.indexOf d1
    i2 = dots.indexOf d2

    # not in dots -> exception
    if i1 == -1 || i2 == -1
      throw new Error('invalid dot')

    # neighbor -> true
    (Math.abs(i2 - i1) == 1 || Math.abs(i2 - i1) == dots.length - 1)

  add: (d) ->
    index = @dots.indexOf(d)
    if index >= 0
      return index

    @dots.push d
    @updateLines()

    d.once "exit", => @del d
    @dots.length - 1

  del: (d) ->
    index = @dots.indexOf d
    if index >= 0
      @dots.splice index, 1

      if @dots.length <= 2
        @emit 'exit', this
      else
        @updateLines()

  contains: (d) ->
    @dots.indexOf d >= 0

  toPoints: ->
    (@dots.map (p) -> "#{p.x},#{p.y}").join(" ")

  # [ [dot1.x, dot1.y], [dot2.x, dot2.y], ...]
  serialize: ->
    @dots.map (dot) ->
      [dot.x, dot.y]

  deserialize: (dots, dotmap) ->
    dots.forEach (pos) =>
      key = pos.join ","
      unless key of dotmap
        dotmap[key] = new Dot(pos[0], pos[1])
      dot = dotmap[key]
      @add dot

  close: ->
    @isClose = true
    @updateLines()

  splitLine: (line, dot) ->
    index = @lines.indexOf line
    if index < 0
      return

    i1 = @dots.indexOf line.d1
    i2 = @dots.indexOf line.d2
    if i1 > i2
      [i2, i1] = [i1, i2]

    if i1 + 1 == i2
      @dots.splice i2, 0, dot
    else if i1 == 0 && i2 == @dots.length - 1
      @dots.push dot
    else
      throw new Error('invalid polygon')

    dot.once "exit", => @del(dot)

    @updateLines()

  addInnerLine: (d1, d2) ->
    if @constructor.isNeighborDot @.dots, d1, d2
      alert 'cannot connect neighborhood dots!!'
      return

    @innerLines.push LineFactory.get(d1, d2)

  updateLines: ->
    @lines = []
    for d1, i in @dots
      d2 = @dots[i + 1 % @dots.length]
      if i == @dots.length - 1
        break

      @lines.push LineFactory.get(d1, d2)

    if @isClose && @dots.length > 2
      d1 = @dots[0]
      d2 = @dots[@dots.length - 1]
      @lines.push LineFactory.get(d1, d2)

root.PolygonList = PolygonList
root.Polygon = Polygon
