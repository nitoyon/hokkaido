root = exports ? this

class Mode
  constructor: (@name, @app) ->

  onClick: (d, i) ->
    prev = @app.unselect()
    if d?
      @app.select d

  onDragStart: (d, i) ->

  onDrag: (d, i) ->
    event = d3.event
    p = @app.zoom.clientToWorld event.x, event.y
    if d == undefined
      @app.zoom.x += event.dx
      @app.zoom.y += event.dy
      @app.zoom.update()
    else if d instanceof Dot
      @app.select d
      d.x += event.dx
      d.y += event.dy

  onDragEnd: (d, i) ->

class PointMode extends Mode
  constructor: (@app) ->
    @name = 'point'

  onClick: (d, i) ->
    event = d3.event

    p = null
    unless d?
      return unless @app.viewModel.adding

      # click none -> add dot
      p = @app.zoom.clientToWorld event.offsetX, event.offsetY
      d = new Dot p.x, p.y
      @app.select d

      @app.viewModel.selectedRegion.polygon.addDot d
    else if d instanceof Dot
      @app.select d

      return unless @app.viewModel.adding

      # click dot -> connect
      create = @app.polygons.createAddingPolygon()
      index = @app.polygons.addingPolygon.addDot d

      # click first dot -> close
      if index == 0 && !create
        @app.viewModel.selectedRegion.polygon.isClose = false
    else if d instanceof Line
      # click line -> add dot
      p = @app.zoom.clientToWorld event.offsetX, event.offsetY
      dot = new Dot p.x, p.y
      @app.polygons.splitLine d, dot

class PolygonMode extends Mode
  constructor: (@app) ->
    @name = 'polygon'

  onClick: (d, i) ->
    # select polygon
    event = d3.event
    if d instanceof Polygon
      @app.select d
      @app.selectedItem.unselectInnerLine()
    else if d instanceof Line
      polygon = @app.selectedItem
      if polygon.containsInnerLine(d)
        polygon.selectInnerLine(d)
    else
      @app.unselect()

  onDragStart: (d, i) ->
    unless d instanceof Dot
      return

    p = @app.selectedItem
    p.getInnerLineCandidates(d).forEach (dot) ->
      dot.canDrop = true
    p.draggingLine =
      d1: d
      d2: {x: 0, y: 0}

  onDrag: (d, i) ->
    unless d instanceof Dot
      Mode.prototype.onDrag.call @, d, i
      return

    hover = d3.select(d3.event.sourceEvent.target).datum()
    src = if hover instanceof Dot then hover else d3.event

    p = @app.selectedItem
    p.draggingLine.d2.x = src.x
    p.draggingLine.d2.y = src.y

  onDragEnd: (d, i) ->
    return unless d instanceof Dot

    p = @app.selectedItem
    p.draggingLine = null
    hover = d3.select(d3.event.sourceEvent.target).datum()
    if hover instanceof Dot && hover.canDrop
      p.addInnerLine(d, hover)

    p.dots.forEach (dot) -> dot.canDrop = false

root.PointMode = PointMode
root.PolygonMode = PolygonMode
