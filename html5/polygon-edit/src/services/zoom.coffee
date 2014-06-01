app = angular.module('PolygonEdit')

app.service 'Zoom', () ->
  @x = 0
  @y = 0
  @scale = 1

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

  @clientToWorld = (x, y) =>
    x: (x - @x) / @scale,
    y: (y - @y) / @scale

  null