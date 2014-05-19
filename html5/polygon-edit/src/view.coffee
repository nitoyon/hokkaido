root = exports ? this

class DotView
  constructor: (@app) ->
    @view = app.canvas.append("svg:g").attr("id", "dots")

  update: () ->
    dots = null
    if @app.modeView.currentMode.name == 'polygon'
      p = @app.selectedItem
      if p instanceof Polygon
        dots = p.dots
      else
        dots = []
    else
      dots = @app.polygons.getDots()

    s = @view.selectAll "circle"
    .data(dots)
    s.enter()
    .append "circle"
    .call @app.drag
    s.exit().remove()
    s
    .classed "selected", (d) -> d.isSelected
    .classed "can_drop", (d) -> d.canDrop
    .classed "is_inner", (d) ->
      if p?
        p.innerDots.indexOf(d) >= 0
    .attr "cx", (d) -> d.x
    .attr "cy", (d) -> d.y
    .attr "r", 5 / @app.zoom.scale

class PolygonView
  constructor: (@app, @polygons) ->
    @view = app.canvas.append("svg:g").attr("id", "polygons")

  update: () ->
    curModeName = @app.modeView.currentMode.name
    if curModeName == "polygon"
      @updatePolygonMode()
    else if curModeName == "point"
      @updatePointMode()

  updatePointMode: () ->
    # delete all polygon
    @view.selectAll("polygon").data([]).exit().remove()

  updatePolygonMode: () ->
    s = @view.selectAll("polygon")
    .data(@polygons.list)
    s.enter().append("polygon").call(@app.drag)
    s.exit().remove()
    s
    .attr "points", (d) -> d.toPoints()
    .classed "selected", (d) -> d.isSelected

    line = null
    if @app.selectedItem instanceof Polygon
      line = @app.selectedItem.draggingLine
    l = @view.selectAll("line")
    .data if line then [line] else []
    l.enter().append "line"
    l.exit().remove()
    l
    .attr
      x1: (d) -> d.d1.x
      y1: (d) -> d.d1.y
      x2: (d) -> d.d2.x
      y2: (d) -> d.d2.y
      "stroke-width": 2 / @app.zoom.scale

class LineView
  constructor: (@app, @polygons) ->
    @view = app.canvas.append("svg:g").attr("id", "lines")

  update: () ->
    curModeName = @app.modeView.currentMode.name
    if curModeName == "polygon"
      @updatePolygonMode()
    else if curModeName == "point"
      @updatePointMode()

  updatePointMode: () ->
    highlightLines =
      if @polygons.addingPolygon then @polygons.addingPolygon.lines else []

    s = @view.selectAll("line.outer")
    .data(@polygons.getOuterLines())
    s.enter()
    .append("line")
    .classed("outer", true)
    .call(@app.drag)
    s.exit().remove()
    s
    .classed "adding", (d) -> highlightLines.indexOf(d) >= 0
    .attr "x1", (d) -> d.d1.x
    .attr "y1", (d) -> d.d1.y
    .attr "x2", (d) -> d.d2.x
    .attr "y2", (d) -> d.d2.y
    .attr "stroke-width", 2 / @app.zoom.scale

    @view.selectAll("line.inner").remove()

  updatePolygonMode: () ->
    unless @app.selectedItem instanceof Polygon
      @view.selectAll("line")
      .data([]).exit().remove()
      return

    polygon = @app.selectedItem
    s = @view.selectAll("line.outer")
    .data(polygon.lines)
    s.enter().append("line")
    .classed("outer", true)
    .call(@app.drag)
    s.exit().remove()
    s
    .attr "x1", (d) -> d.d1.x
    .attr "y1", (d) -> d.d1.y
    .attr "x2", (d) -> d.d2.x
    .attr "y2", (d) -> d.d2.y
    .attr "stroke-width", 2 / @app.zoom.scale

    s = @view.selectAll("line.inner")
    .data(polygon.innerLines)
    s.enter().append("line")
    .classed("inner", true)
    .call(@app.drag)
    s.exit().remove()
    s
    .classed "selected", (d) -> d.isSelected
    .attr "x1", (d) -> d.d1.x
    .attr "y1", (d) -> d.d1.y
    .attr "x2", (d) -> d.d2.x
    .attr "y2", (d) -> d.d2.y
    .attr "stroke-width", 2 / @app.zoom.scale

class MapZoom
  constructor: (@elm, @target) ->
    @dispatch = d3.dispatch "scaleChange"
    d3.rebind this, @dispatch, "on"

    @x = 0
    @y = 0
    @scale = 1

  zoomUp: () ->
    @setScale @scale * 2
  
  zoomDown: () ->
    @setScale @scale / 2

  setScale: (val) ->
    if isNaN(val) || val < 1 || val == @scale
      return

    old = @scale
    @x = (@x - 300) / @scale * val + 300
    @y = (@y - 300) / @scale * val + 300
    @scale = val

    @update()
    @scaleChange {oldScale: old, newScale: @scale}

  clientToWorld: (x, y) ->
    {
      x: (x - @x) / @scale,
      y: (y - @y) / @scale
    }

  update: () ->
    @target.attr "transform",
      "translate(" + @x + "," + @y + ") " +
      "scale(" + @scale + ")"
  
  scaleChange: () ->
    @dispatch.scaleChange()

  serialize: () ->
    {x: @x, y: @y, scale: @scale }

  deserialize: (data) ->
    @x = data.x unless isNaN data.x
    @y = data.y unless isNaN data.y
    @scale = data.scale unless isNaN data.scale

root.DotView = DotView
root.PolygonView = PolygonView
root.LineView = LineView
root.MapZoom = MapZoom
