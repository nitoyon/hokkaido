class MapEditor
  constructor: (@elm, json) ->
    @selectedItem = null
    @modes = []
    @initJson json

    @initModel()
    @initElement()
    @initViewModel()
    @initEvent()
    @updateView()

  initModel: ->
    @polygons = new PolygonList()

    if localStorage.polygon
      data = JSON.parse localStorage.polygon
      @polygons.deserialize data

  initElement: () ->
    @svg = d3.select(@elm)
    @canvas = @svg.select "#canvas"
    @mapContainer = @canvas.select "#map_pathes"
    @polygonView = new PolygonView(@, @polygons)
    @lineView = new LineView(@, @polygons)
    @dotView = new DotView(@)

    @modeView = new ModeView(@, [new PointMode(@), new PolygonMode(@)])

  initJson: (json) ->
    projection = d3.geo
    .mercator()
    .scale 1200    # scale
    .rotate [-150,0,0]
    .translate [580, 1100]

    path = d3.geo.path().projection projection

    @prefs = new PrefList()
    @prefs.parseJson json, path
    null

  initViewModel: () ->
    _selectedIds = []

    new Vue
      el: "#main"
      data:
        prefs: @prefs.list
        selectedRegion: null
      computed:
        selectedIds:
          $get: () -> _selectedIds
          $set: (val) ->
            _selectedIds = val

            # unselect previsious selected pref
            @selectedRegion?.isSelected = false

            # update new selected pref
            if _selectedIds.length > 0
              id = _selectedIds[0]
              [prefName, index] = id.split "-"
              pref = _.find @prefs, (pref) -> pref.name == prefName
              @selectedRegion = _.find pref.regions, (region) ->
                region.id == id
            else
              @selectedRegion = null

            # select it
            @selectedRegion?.isSelected = true
      methods:
        onRename: () ->
          newName = prompt "new Name", @selectedRegion.name
          @selectedRegion.name = newName if newName?
          d3.select("#pref_list").node().focus()

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
