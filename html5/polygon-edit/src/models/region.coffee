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
    @polygon.once 'exit', => @_delPolygon()

  _delPolygon: ->
    if @polygon != null
      @polygon.removeAllListeners()
      @polygon = null

  deserialize: (json, dotmap) ->
    @createPolygon()
    @polygon.isClose = true
    @polygon.deserialize json, dotmap

    @_delPolygon() if @polygon.dots < 3

root.Region = Region
