'use strict'
require('source-map-support').install()

{assert} = require 'chai'
{PrefList} = require '../src/models/pref_list'
{Pref} = require '../src/models/pref'
{Polygon} = require '../src/models/polygon'

describe 'PrefList', ->
  describe 'getAllPolygons', ->
    it 'should return [] when vacant', ->
      prefs = new PrefList()
      assert.lengthOf prefs.getAllPolygons(), 0

    it 'should return valid number', ->
      prefs = new PrefList()

      p1 = new Pref()
      p1.regions.push new Polygon()
      p1.regions.push new Polygon()

      p2 = new Pref()
      p2.regions.push new Polygon()

      prefs.list.push p1
      prefs.list.push p2
      assert.lengthOf prefs.getAllPolygons(), 3
