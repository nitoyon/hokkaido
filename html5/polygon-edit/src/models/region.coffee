'use strict'
root = exports ? this

class Region
  constructor: (@prefName, index, @path) ->
    @id = @prefName + "-" + (index + 1)
    @name = @id
    @count = @path.split(/L|M/).length
    @polygon = null

  createPolygon: ->
    throw new Error 'polygon is not null' if @polygon?
    @polygon = new Polygon()
    @polygon.isClose = false

root.Region = Region
