class MapEditor
  constructor: (@elm, json) ->
    @data = null
    @selectedItem = null
    @modes = []

    @initModel()
    @initElement()
    @initJson json
    @initEvent()
    @updateView()

  initModel: ->
    @polygons = new PolygonList()

    if localStorage.polygon
      data = JSON.parse localStorage.polygon
      @polygons.deserialize data

  initElement: () ->
    @svg = d3.select(@elm)
    @canvas = @svg.append("svg:g").attr("id", "canvas")
    @mapContainer = @canvas.append("svg:g").attr("id", "map_pathes")
    @polygonView = new PolygonView(@, @polygons)
    @lineView = new LineView(@, @polygons)
    @dotView = new DotView(@)

    @modeView = new ModeView(@, [new PointMode(@), new PolygonMode(@)])

  initJson: (json) ->
    geodata = json.features

    projection = d3.geo
    .mercator()
    .scale 1200    # scale
    .rotate [-150,0,0]
    .translate [580, 1100]

    path = d3.geo.path().projection projection
    color = d3.scale.category20()

    pathes = []
    self = @
    geodata.forEach (data) =>
      # MultiPolygon -> array of Polygons
      pathes = []
      if data.geometry.type == "MultiPolygon"
        data.geometry.type = "Polygon"
        coordinates = data.geometry.coordinates
        for coordinate in coordinates
          data.geometry.coordinates = coordinate
          pathes.push(path data)
      else if data.geometry.type == "Polygon"
        pathes.push(path data)

      @mapContainer.append "g"
      .attr "class", data.properties.ObjName_1
      .selectAll("path")
      .data pathes
      .enter()
      .append "svg:path"
      .attr
        "d": (d) -> d
      .attr "fill", color(data.properties.ObjName)

  initEvent: () ->
    d3.select(document).on "keydown", () =>
      #console.log(d3.event.keyCode)
      switch d3.event.keyCode
        when 46  # del
          @del()
        when 187 # +
          @zoom.zoomUp()
        when 189 # -
          @zoom.zoomDown()

    @zoom = new MapZoom(@svg, @canvas)
    @zoom.on 'scaleChange', () =>
      @onZoomChange()

    if localStorage.zoom
      @zoom.deserialize(JSON.parse(localStorage.zoom))
      @zoom.update()

    dragging = dragMoved = false
    @drag = d3.behavior.drag()
    .on "dragstart", (d) ->
      dragging = dragMoved = false

      # drag the most foreground draggable object
      d3.event.sourceEvent.stopPropagation()
    .on "dragend", (d, i) =>
      if !dragMoved
        @onClick(d, i, this)
      else
        @onDragEnd(d, i, this)
    .on "drag", (d, i) =>
      if !dragging
        # skip first event (triggered on mouse down)
        dragging = true
        return
      else if !dragMoved
        # trigger onDragStart on first move
        dragMoved = true
        @onDragStart d, i, this
      @onDrag d, i, this

    @svg.call @drag

    @modeView.on 'change', () => @updateView()

  updateView: () ->
    @dotView.update()
    @lineView.update()
    @polygonView.update()

    localStorage.polygon = JSON.stringify(@polygons.serialize())
    localStorage.zoom = JSON.stringify(@zoom.serialize())

  del: () ->
    if @selectedItem
      @selectedItem.del()
      @selectedItem = null
      @updateView()

  select: (item) ->
    prev = @unselect()

    if item
      @selectedItem = item
      item.isSelected = true
    else
      @selectedItem = null
    prev

  unselect: () ->
    prev = null
    if @selectedItem?
      prev = @selectedItem
      @selectedItem.isSelected = false
    @selectedItem = null
    prev

  onDragStart: (d, i, elm) ->
    @modeView.currentMode.onDragStart d, i, elm
    @updateView()

  onDrag: (d, i, elm) ->
    @modeView.currentMode.onDrag d, i, elm
    @updateView()

  onDragEnd: (d, i, elm) ->
    @modeView.currentMode.onDragEnd d, i, elm
    @updateView()

  onClick: (d, i, elm, event) ->
    prevEvent = d3.event
    d3.event = d3.event.sourceEvent
    @modeView.currentMode.onClick d, i
    d3.event = prevEvent
    @updateView()

  onZoomChange: () ->
    @updateView()

map = null
d3.json "out.geojson", (json) ->
  map = new MapEditor document.getElementById("map"), json
