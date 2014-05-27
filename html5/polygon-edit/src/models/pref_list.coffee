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

  parseJson: (json, path) ->
    @list = json.features
    .map (data) ->
      Pref.createFromJson data, path
    .sort (a, b) -> return a.index - b.index


root.PrefList = PrefList
