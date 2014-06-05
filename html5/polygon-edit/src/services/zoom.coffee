app = angular.module('PolygonEdit')

app.service 'Zoom', () ->
  @x = 0
  @y = 0
  @scale = 1

  @move = (dx, dy) =>
    @x += dx
    @y += dy
    @save()

  @zoomUp = () =>
    @setScale @scale * 2

  @zoomDown = () =>
    @setScale @scale / 2

  @setScale = (val) =>
    if isNaN(val) || val < 1 || val == @scale
      return

    old = @scale
    @x = (@x - 300) / @scale * val + 300
    @y = (@y - 300) / @scale * val + 300
    @scale = val

    @save()

  @clientToWorld = (x, y) =>
    x: (x - @x) / @scale,
    y: (y - @y) / @scale

  @save = () =>
    localStorage.zoom = JSON.stringify(
      x: @x
      y: @y
      scale: @scale)

  @load = () =>
    data = JSON.parse localStorage.zoom if localStorage.zoom?
    return unless data?

    @x = data.x if data.x?
    @y = data.y if data.y?
    @scale = data.scale if data.scale?

  @load()

  null