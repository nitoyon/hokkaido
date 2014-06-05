'use strict'
root = exports ? this

LineFactory = require('./line').LineFactory
LineFactory ?= @LineFactory
{Dot} = require('./dot')
Dot ?= @Dot
EventEmitter2 = require('eventemitter2').EventEmitter2
EventEmitter2 ?= @EventEmitter2
_ = require('underscore')
_ ?= @_

class Polygon extends EventEmitter2
  @id = 1

  constructor: (dots...)->
    @dots = []
    @lines = []
    @groups = []
    @innerLines = []
    @innerDots = []
    @selectedInnerLine = null
    @lastDot = null
    @id = @constructor.id++
    @isClose = true

    @addDot dot, true for dot in dots
    @update()

  @isNeighborDot: (dots, d1, d2) ->
    i1 = dots.indexOf d1
    i2 = dots.indexOf d2

    # not in dots -> exception
    if i1 == -1 || i2 == -1
      throw new Error('invalid dot')

    # neighbor -> true
    (Math.abs(i2 - i1) == 1 || Math.abs(i2 - i1) == dots.length - 1)

  @getConvexHull: (dots) ->
    throw new Error 'dots is not an Array' unless dots instanceof Array
    throw new Error 'dot count is too small' if dots.length < 3

    start = _.max dots, (d) -> d.y

    cur = null
    ret = []
    vec = x: 1, y: 0
    while start != cur
      cur = start unless cur?
      ret.push cur

      if ret.length > dots.length
        console.warn 'invalid convex hull', dots
        break

      nextDot = _.max dots, (dot) ->
        if dot == cur
          -1
        else
          # calc cos(theta) by calculating inner product
          ((dot.x - cur.x) * vec.x + (dot.y - cur.y) * vec.y) /
            Math.sqrt (dot.x - cur.x) ** 2 + (dot.y - cur.y) ** 2

      # update vec and cur
      vec = x: nextDot.x - cur.x, y: nextDot.y - cur.y
      d = Math.sqrt vec.x ** 2 + vec.y ** 2
      vec.x /= d
      vec.y /= d
      cur = nextDot

    ret

  addDot: (d, preventUpdate) ->
    index = @dots.indexOf(d)
    if index >= 0
      return index

    @dots.push d
    @update() unless preventUpdate

    d.once "exit", => @_delDot d
    @dots.length - 1

  # private method
  # Use dot.del() instead
  _delDot: (d) ->
    index = @dots.indexOf d
    if index >= 0
      @dots.splice index, 1

      @clearInnerLines()

      if @dots.length <= 2
        @emit 'exit', this
      else
        @update()

  del: ->
    @deleteInnerLine @selectedInnerLine if @selectedInnerLine?

  contains: (d) ->
    @dots.indexOf d >= 0

  containsInnerLine: (l) ->
    @innerLines.indexOf l >= 0

  toPoints: ->
    (@dots.map (p) -> "#{p.x},#{p.y}").join(" ")

  # {
  #   dots:
  #   [
  #     [dot1.x, dot1.y], [dot2.x, dot2.y], ...
  #   ],
  #   inner:
  #   [
  #     [line1_start, line1_end], [line2_start, line2_end], ...
  #   ],
  # }
  serialize: ->
    dots = @dots.map (dot) ->
      [dot.x, dot.y]
    inner = @innerLines.map (line) =>
      [@dots.indexOf(line.d1), @dots.indexOf line.d2]
    { dots: dots, inner: inner }

  deserialize: (data, dotmap) ->
    @dots = []
    @innerLines = []

    data.dots ?= []
    return if data.dots.length < 3
    data.dots.forEach (pos) =>
      key = pos.join ","
      unless key of dotmap
        dotmap[key] = new Dot(pos[0], pos[1])
      dot = dotmap[key]
      @addDot dot, true

    # we should create a default group
    @update()

    data.inner ?= []
    data.inner.forEach (indices) =>
      d1 = @dots[indices[0]]
      d2 = @dots[indices[1]]
      @addInnerLine d1, d2

    @update()

  close: ->
    @isClose = true
    @update()

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

    dot.once "exit", => @_delDot(dot)

    @update()

  getInnerLineCandidates: (d) ->
    ret = []

    groups = @groups.filter (g) -> g.indexOf(d) != -1
    groups.forEach (group) ->
      dots = group.filter (dot) ->
        d != dot && !Polygon.isNeighborDot group, d, dot
      ret = ret.concat dots
    return ret

  addInnerLine: (d1, d2) ->
    if @getInnerLineCandidates(d1).indexOf(d2) == -1
      throw new Error('cannot connect neighborhood dots!!')

    @innerLines.push LineFactory.get(d1, d2)
    @update()

  deleteInnerLine: (l) ->
    throw new Error 'not an inner line' unless @containsInnerLine l
    index = @innerLines.indexOf l
    @innerLines.splice index, 1
    @update()

  clearInnerLines: ->
    @unselectInnerLine()
    @innerLines = []

  selectInnerLine: (l) ->
    throw new Error 'not an inner line' unless @containsInnerLine l
    @unselectInnerLine()
    l.isSelected = true
    @selectedInnerLine = l

  unselectInnerLine: ->
    @selectedInnerLine?.isSelected = false
    @selectedInnerLine = null

  update: ->
    @updateLines()
    @updateGroups()

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

  @getDotsOfLineAscending: (dots, line) ->
    i1 = dots.indexOf line.d1
    i2 = dots.indexOf line.d2
    throw new Error("line is not contains dots") if i1 == -1 or i2 == -1
    [i1, i2] = [i2, i1] if i1 > i2
    [i1, i2] = [i2, i1] if i1 == 0 && i2 == dots.length - 1
    return [dots[i1], dots[i2], i1, i2]

  getConnectedDots: (dot) ->
    ret = []
    for line in @lines.concat @innerLines
      if line.contains dot
        d = line.getAnotherDot dot
        ret.push dot: d, index: @dots.indexOf d
    ret

  findGroup: (line) ->
    [startDot, curDot, startIndex, curIndex] =
      @constructor.getDotsOfLineAscending(@dots, line)
    ret = [startDot]
    prevDot = startDot

    #console.log "findGroup; ", startDot.id, curDot.id
    while startDot != curDot
      ret.push curDot

      # find the next dot
      connectedDots = @getConnectedDots(curDot).filter (d) -> d.dot != prevDot
      connectedDots.forEach (d) =>
        if d.index > startIndex
          d.distance = startIndex + @dots.length - d.index
        else
          d.distance = startIndex - d.index
      connectedDots.sort (x, y) -> x.distance - y.distance
      #console.log connectedDots
      break if connectedDots.length == 0

      prevDot = curDot
      curDot = connectedDots[0].dot

    ret

  updateGroups: ->
    @groups = []
    lines = @lines[..]

    unless @isClose
      @groups = [@dots[..]]
      return

    while lines.length > 0
      # find the group which contains the first line
      line = lines.shift()
      group = @findGroup line
      @groups.push group

      # update remaining lines
      for dot, i in group
        line = LineFactory.get(dot, group[(i + 1) % group.length])
        index = lines.indexOf line
        lines.splice index, 1 if index >= 0

    @innerDots = []
    for group in @groups
      dots = _.difference group, @constructor.getConvexHull group
      @innerDots = _.union @innerDots, dots
    null

root.Polygon = Polygon
