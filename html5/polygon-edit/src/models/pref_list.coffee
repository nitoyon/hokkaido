'use strict'
root = exports ? this

_ = require('underscore')
_ ?= @_

class PrefList
  constructor: () ->
    @list = []

  getAllRegions: () ->
    _.chain @list
    .map (pref) -> pref.regions
    .flatten()
    .value()

  getAllPolygons: () ->
    _.chain @getAllRegions()
    .map (region) -> region.polygon
    .flatten()
    .compact()
    .value()

  getAllDots: () ->
    _.chain @getAllRegions()
    .map (region) -> region.polygon?.dots
    .flatten()
    .compact()
    .uniq()
    .value()

  serialize: ->
    ret = {}
    @list.forEach (pref) -> ret[pref.name] = pref.serialize()
    ret

  deserialize: (data) ->
    dotmap = {}
    for pref in @list
      if pref.name of data
        pref.deserialize data[pref.name], dotmap

  parseJson: (json, path) ->
    @list = json.features
    .map (data) ->
      Pref.createFromJson data, path
    .sort (a, b) -> return a.index - b.index


root.PrefList = PrefList
