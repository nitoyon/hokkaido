'use strict'

{assert} = require 'chai'
{PolygonList} = require '../src/models/polygon'
{Polygon} = require '../src/models/polygon'
{Dot} = require '../src/models/dot'
{LineList} = require '../src/models/line'

describe 'PolygonList', ->
  it 'should create adding polygon', ->
    list = new PolygonList()
    assert.isTrue list.createAddingPolygon()
    polygon = list.addingPolygon
    assert.isFalse polygon.isClose
    assert.equal 1, list.list.length

  it 'should close adding polygon', ->
    list = new PolygonList()
    list.createAddingPolygon()
    polygon = list.addingPolygon

    polygon.add(new Dot(2, 3))
    polygon.add(new Dot(3, 4))
    polygon.add(new Dot(4, 5))
    list.closeAddingPolygon()

    assert.isTrue polygon.isClose

  describe 'serialize', ->
    it 'should serialize vacant polygons', ->
      list = new PolygonList()
      assert.deepEqual [], list.serialize()

    it 'should serialize multiple polygons', ->
      d1 = new Dot(2, 3)

      list = new PolygonList()
      list.add(new Polygon(d1, new Dot(3, 4), new Dot(4, 5)))
      list.add(new Polygon(d1, new Dot(6, 7), new Dot(7, 8)))
      assert.deepEqual [
        [[2,3], [3,4], [4,5]],
        [[2,3], [6,7], [7,8]],
      ], list.serialize()

  describe 'deserialize', ->
    it 'should deserialize vacant polygons', ->
      list = new PolygonList()
      list.deserialize([])
      assert.equal 0, list.list.length

    it 'should deserialize multiple polygons', ->
      list = new PolygonList()
      list.deserialize [
        [[2,3], [3,4], [4,5], [5,6], [7,8]],
        [[2,3], [6,7], [7,8], [8,9]],
      ]
      assert.equal 2, list.list.length
      assert.strictEqual list.list[0].dots[0], list.list[1].dots[0]
      assert.equal 5, list.list[0].dots.length
      assert.equal 5, list.list[0].lines.length
      assert.equal 2, list.list[0].dots[0].x
      assert.equal 3, list.list[0].dots[0].y
      assert.equal 4, list.list[1].dots.length
      assert.equal 4, list.list[1].lines.length

describe 'Polygon', ->
  describe 'constructor', ->
    it 'should create vacant polygon', ->
      p = new Polygon()
      assert.equal 0, p.dots.length

    it 'should create triangle', ->
      p = new Polygon(new Dot(2, 3), new Dot(3, 4), new Dot(4, 5))
      assert.equal 3, p.dots.length
      assert.equal 3, p.lines.length

  describe 'isNeighborDot', ->
    it 'should return true on neighbor dots', ->
      dots = [
        new Dot(), new Dot(), new Dot(), new Dot()
      ]
      assert.isTrue Polygon.isNeighborDot dots, dots[0], dots[1]
      assert.isTrue Polygon.isNeighborDot dots, dots[1], dots[0]
      assert.isTrue Polygon.isNeighborDot dots, dots[1], dots[2]
      assert.isTrue Polygon.isNeighborDot dots, dots[2], dots[3]
      assert.isTrue Polygon.isNeighborDot dots, dots[3], dots[0]

    it 'should return false on not neighbor dots', ->
      dots = [
        new Dot(), new Dot(), new Dot(), new Dot()
      ]
      assert.isFalse Polygon.isNeighborDot dots, dots[0], dots[2]
      assert.isFalse Polygon.isNeighborDot dots, dots[1], dots[3]

  it 'should update lines', ->
    polygon = new Polygon()
    polygon.isClose = false

    polygon.add(new Dot(2, 3))
    polygon.add(new Dot(3, 4))
    assert.equal 1, polygon.lines.length

    polygon.add(new Dot(4, 5))
    assert.equal 2, polygon.lines.length

    polygon.add(new Dot(6, 7))
    assert.equal 3, polygon.lines.length

    polygon.close()
    assert.equal 4, polygon.lines.length

    polygon.add(new Dot(8, 9))
    assert.equal 5, polygon.lines.length

  it 'should del dot', ->
    polygon = new Polygon()

    d = new Dot(2, 3)
    polygon.add(d)
    polygon.add(new Dot(3, 4))
    polygon.add(new Dot(4, 5))
    polygon.add(new Dot(5, 6))
    polygon.close()
    assert.equal 4, polygon.lines.length

    polygon.del(d)
    assert.equal 3, polygon.lines.length

  it 'should split line', ->
    polygon = new Polygon()

    d1 = new Dot(2, 3)
    d2 = new Dot(3, 4)
    d3 = new Dot(4, 5)
    d4 = new Dot(5, 6)
    polygon.add(d1)
    polygon.add(d2)
    polygon.add(d3)
    polygon.close()
    assert.equal 3, polygon.lines.length

    polygon.splitLine(polygon.lines[0], d4)
    assert.equal 4, polygon.lines.length
    assert.equal 4, polygon.dots.length
    assert.strictEqual d1, polygon.dots[0]
    assert.strictEqual d4, polygon.dots[1]
    assert.strictEqual d2, polygon.dots[2]
    assert.strictEqual d3, polygon.dots[3]

  describe 'group', ->
    it 'should be one when no inner lines exist', ->
      # d1 o-----o d2
      #    |     |
      #    |     |
      # d4 o-----o d3
      [d1, d2, d3, d4] = [new Dot(), new Dot(), new Dot(), new Dot()]
      polygon = new Polygon(d1, d2, d3, d4)

      assert.lengthOf polygon.groups, 1

      g = polygon.groups[0]
      assert.lengthOf g, 4
      assert.deepEqual [d1, d2, d3, d4], g

    it 'should be two when one inner line exists', ->
      # d1 o-----o d2
      #    | ___/|
      #    |/    |
      # d5 o--o--o d3
      #       d4
      [d1, d2, d3, d4, d5] =
        [new Dot(), new Dot(), new Dot(), new Dot(), new Dot()]
      polygon = new Polygon(d1, d2, d3, d4, d5)
      polygon.addInnerLine(d2, d5)

      assert.lengthOf polygon.groups, 2

      g = polygon.groups[0]
      assert.lengthOf g, 3
      assert.deepEqual [d1, d2, d5], g

      g = polygon.groups[1]
      assert.lengthOf g, 4
      assert.deepEqual [d2, d3, d4, d5], g

    it 'should be valid when two inner line exists', ->
      # d1 o---o d2
      #    | _/|
      #    |/  |
      # d5 o---o d3
      #     \ /
      #      o d4
      [d1, d2, d3, d4, d5] =
        [new Dot(), new Dot(), new Dot(), new Dot(), new Dot()]
      polygon = new Polygon(d1, d2, d3, d4, d5)
      polygon.addInnerLine(d2, d5)
      polygon.addInnerLine(d3, d5)

      assert.lengthOf polygon.groups, 3

      g = polygon.groups[0]
      assert.lengthOf g, 3
      assert.deepEqual [d1, d2, d5], g

      g = polygon.groups[1]
      assert.lengthOf g, 3
      assert.deepEqual [d2, d3, d5], g

      g = polygon.groups[2]
      assert.lengthOf g, 3
      assert.deepEqual [d3, d4, d5], g
