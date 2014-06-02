'use strict'
root = exports ? this

class Pref
  constructor: (@name, @index) ->
    @color = "#999999"

    # prefName: "Hokkaido"
    # name: "Hokkaido-1"
    # count: "5"  # size of RegionOutlinePath
    # path: "..." # RegionOutlinePath
    # id: "Hokkaido-1"
    # isSelected: false
    # polygon: new Polygon(...)
    @regions = []

  @createFromJson: (json, path) ->
    # MultiPolygon -> array of Polygons
    pathes = []
    if json.geometry.type == "MultiPolygon"
      json.geometry.type = "Polygon"
      coordinates = json.geometry.coordinates
      for coordinate in coordinates
        json.geometry.coordinates = coordinate
        pathes.push(path json)
    else if json.geometry.type == "Polygon"
      pathes.push(path json)

    name = json.properties.ObjName_1
    index = json.properties["JIS-CODE"]
    ret = new Pref name, index
    ret.regions = pathes.map (path, i) ->
      prefName: name,
      name: name + "-" + (i + 1)
      count: path.split(/L|M/).length
      path: path
      id: name + "-" + (i + 1)
      isSelected: false
      polygon: null

    return ret

root.Pref = Pref
