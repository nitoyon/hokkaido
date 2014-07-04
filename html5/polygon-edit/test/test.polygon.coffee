'use strict'
require('source-map-support').install()

{assert} = require 'chai'
{Polygon} = require '../src/models/polygon'
{Dot} = require '../src/models/dot'
{LineFactory} = require '../src/models/line'

describe 'Polygon', ->
  beforeEach ->
    Dot.id = 1
    LineFactory.id2line = {}

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

  describe 'getConvexHull', ->
    it 'should throw an error when array is not given', ->
      assert.throws -> Polygon.getConvexHull new Dot(0, 0)

    it 'should return itself if three dots are given', ->
      [d1, d2, d3] = [new Dot(0, 0), new Dot(10, 0), new Dot(10, 10)]
      assert.deepEqual [d3, d2, d1], Polygon.getConvexHull([d1, d2, d3])

    it 'should return subset', ->
      [d1, d2, d3, d4] = [new Dot(0, 0), new Dot(10, 0), new Dot(10, 10),
        new Dot(4, 2), new Dot(8, 3)]
      assert.deepEqual [d3, d2, d1], Polygon.getConvexHull([d1, d2, d3])

  it 'should update lines', ->
    [d1, d2, d3, d4, d5] =
      [new Dot(), new Dot(), new Dot(), new Dot(), new Dot()]
    polygon = new Polygon()
    polygon.isClose = false

    polygon.addDot(d1)
    polygon.addDot(d2)
    assert.lengthOf polygon.lines, 1
    assert.strictEqual LineFactory.get(d1, d2), polygon.lines[0], 'd1-d2'

    polygon.addDot(d3)
    assert.lengthOf polygon.lines, 2
    assert.strictEqual LineFactory.get(d2, d3), polygon.lines[1], 'd2-d3'

    polygon.addDot(d4)
    assert.lengthOf polygon.lines, 3
    assert.strictEqual LineFactory.get(d3, d4), polygon.lines[2], 'd3-d4'

    polygon.close()
    assert.lengthOf polygon.lines, 4
    assert.strictEqual LineFactory.get(d4, d1), polygon.lines[3], 'd4-d1'

    polygon.addDot(d5)
    assert.lengthOf polygon.lines, 5
    assert.strictEqual LineFactory.get(d4, d5), polygon.lines[3], 'd4-d5'
    assert.strictEqual LineFactory.get(d5, d1), polygon.lines[4], 'd5-d1'

  describe 'del dot', ->
    it 'should del dot', ->
      d = new Dot()
      polygon = new Polygon(d, new Dot(), new Dot(), new Dot())

      assert.lengthOf polygon.dots, 4
      assert.lengthOf polygon.lines, 4

      called = false
      polygon.once 'exit', () -> called = true

      d.del()
      assert.lengthOf polygon.dots, 3
      assert.lengthOf polygon.lines, 3
      assert.isFalse called

    it 'should del triangle', ->
      d = new Dot()
      polygon = new Polygon(d, new Dot(), new Dot())

      assert.lengthOf polygon.dots, 3
      assert.lengthOf polygon.lines, 3

      called = false
      polygon.once 'exit', () -> called = true

      d.del()
      assert.isTrue called

    it 'should delete inner line when it becomes outer line', ->
      # d1 o---o d2
      #    | _/|
      #    |/  |
      # d5 o-o-o d3
      #      d4
      [d1, d2, d3, d4, d5] = [new Dot(), new Dot(), new Dot(), new Dot(),
        new Dot()]
      polygon = new Polygon(d1, d2, d3, d4, d5)
      polygon.addInnerLine d2, d5
      assert.lengthOf polygon.innerLines, 1

      d3.del()
      assert.lengthOf polygon.innerLines, 1

      d4.del()
      assert.lengthOf polygon.innerLines, 0

    it 'should delete inner line when one of its node is deleted', ->
      [d1, d2, d3, d4, d5, d6] = [new Dot(), new Dot(), new Dot(),
        new Dot(), new Dot(), new Dot()]
      polygon = new Polygon(d1, d2, d3, d4, d5, d6)
      polygon.addInnerLine d1, d4
      polygon.addInnerLine d4, d6
      assert.lengthOf polygon.innerLines, 2

      d1.del()
      assert.lengthOf polygon.innerLines, 1
      assert.equal polygon.innerLines[0], LineFactory.get d4, d6

  describe 'splitLine', ->
    it 'should add dot', ->
      [d1, d2, d3, d4] = [new Dot(), new Dot(), new Dot(), new Dot()]
      polygon = new Polygon(d1, d2, d3)
      assert.lengthOf polygon.dots, 3
      assert.lengthOf polygon.lines, 3

      polygon.splitLine(polygon.lines[0], d4)
      assert.lengthOf polygon.lines, 4
      assert.lengthOf polygon.dots, 4
      assert.deepEqual [d1, d4, d2, d3], polygon.dots

    it 'should add dot and new dot should be able to delete', ->
      [d1, d2, d3, d4] = [new Dot(), new Dot(), new Dot(), new Dot()]
      polygon = new Polygon(d1, d2, d3)
      polygon.splitLine(polygon.lines[0], d4)
      d4.del()

      assert.lengthOf polygon.dots, 3
      assert.lengthOf polygon.lines, 3

  describe 'addInnerLine', ->
    it 'should split into 2 groups', ->
      [d1, d2, d3, d4] = [new Dot(), new Dot(), new Dot(), new Dot()]
      polygon = new Polygon(d1, d2, d3, d4)
      assert.lengthOf polygon.groups, 1

      polygon.addInnerLine d1, d3
      assert.lengthOf polygon.groups, 2

    it 'should fail when neighbor 2 dots are given', ->
      [d1, d2, d3, d4] = [new Dot(), new Dot(), new Dot(), new Dot()]
      polygon = new Polygon(d1, d2, d3, d4)
      assert.throws -> polygon.addInnerLine d1, d2

    it 'should fail when inner line interacts', ->
      [d1, d2, d3, d4] = [new Dot(), new Dot(), new Dot(), new Dot()]
      polygon = new Polygon(d1, d2, d3, d4)
      polygon.addInnerLine d1, d3
      assert.throws -> polygon.addInnerLine d2, d4

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

    # FIX ME: it's difficult to fix this bug (Knwon issue)
    #it 'should be valid when inner group exists', ->
    #  #       d2
    #  # d1 o--o--o d3
    #  #    | / \ |
    #  #    |/   \|
    #  # d6 o-----o d4
    #  #     \   /
    #  #      --o d5
    #  [d1, d2, d3, d4, d5, d6] =
    #    [new Dot(), new Dot(), new Dot(), new Dot(), new Dot(), new Dot()]
    #  polygon = new Polygon(d1, d2, d3, d4, d5, d6)
    #  polygon.addInnerLine(d2, d4)
    #  polygon.addInnerLine(d4, d6)
    #  polygon.addInnerLine(d6, d2)
    #
    #  assert.lengthOf polygon.groups, 4

  describe 'getInnerLineCandidates', ->
    it 'should be valid when no inner lines exist', ->
      # d1  d2  d3
      #  o---o---o
      #  |       |
      #  o---o---o
      # d6  d5  d4
      [d1, d2, d3, d4, d5, d6] =
        [new Dot(), new Dot(), new Dot(), new Dot(), new Dot(), new Dot()]
      polygon = new Polygon(d1, d2, d3, d4, d5, d6)

      assert.deepEqual [d3, d4, d5], polygon.getInnerLineCandidates(d1), 'd1'
      assert.deepEqual [d4, d5, d6], polygon.getInnerLineCandidates(d2), 'd2'
      assert.deepEqual [d1, d5, d6], polygon.getInnerLineCandidates(d3), 'd3'

    it 'should be valid when one inner lines exist', ->
      # d1  d2  d3
      #  o---o---o
      #  | _____/|
      #  |/      |
      #  o---o---o
      # d6  d5  d4
      [d1, d2, d3, d4, d5, d6] =
        [new Dot(), new Dot(), new Dot(), new Dot(), new Dot(), new Dot()]
      polygon = new Polygon(d1, d2, d3, d4, d5, d6)
      polygon.addInnerLine d3, d6

      assert.deepEqual [d3], polygon.getInnerLineCandidates(d1), 'd1'
      assert.deepEqual [d6], polygon.getInnerLineCandidates(d2), 'd2'
      assert.deepEqual [d1, d5], polygon.getInnerLineCandidates(d3), 'd3'
      assert.deepEqual [d6], polygon.getInnerLineCandidates(d4), 'd4'
      assert.deepEqual [d3], polygon.getInnerLineCandidates(d5), 'd5'
      assert.deepEqual [d2, d4], polygon.getInnerLineCandidates(d6), 'd6'

  describe 'deleteInnerLine', ->
    it 'should delete inner line', ->
      # d1 o-----o d2
      #    | ___/|
      #    |/    |
      # d4 o-----o d3
      [d1, d2, d3, d4] =
        [new Dot(), new Dot(), new Dot(), new Dot()]
      polygon = new Polygon(d1, d2, d3, d4)
      polygon.addInnerLine(d2, d4)
      assert.lengthOf polygon.groups, 2, 'group'
      assert.lengthOf polygon.innerLines, 1, 'inner lines'

      polygon.deleteInnerLine polygon.innerLines[0]
      assert.lengthOf polygon.groups, 1, 'group'
      assert.lengthOf polygon.innerLines, 0, 'inner lines'

  describe 'inner dots', ->
    it 'should contain a dot which is in convex hull', ->
      # d1 o-----o d2
      #  d5 ~o-_ |
      #     d4  o|
      #          o d3
      [d1, d2, d3, d4, d5] = [new Dot(0, 0), new Dot(10, 0), new Dot(10, 10),
        new Dot(8, 2), new Dot(1, 1)]
      polygon = new Polygon(d1, d2, d3, d4, d5)
      assert.deepEqual [d4, d5], polygon.innerDots

    it 'should consider groups', ->
      [d1, d2, d3, d4, d5] = [new Dot(0, 0), new Dot(10, 0), new Dot(10, 10),
        new Dot(8, 2), new Dot(1, 1)]
      polygon = new Polygon(d1, d2, d3, d4, d5)
      polygon.addInnerLine(d2, d5)
      assert.deepEqual [d4], polygon.innerDots

  describe 'serialize', ->
    it 'should contain dot information', ->
      p = new Polygon new Dot(2, 3), new Dot(3, 4), new Dot(4, 5)
      assert.deepEqual(
        dots: [[2, 3], [3, 4], [4, 5]], inner: []
        p.serialize())

    it 'should contain inner line information', ->
      [d1, d2, d3, d4] =
        [new Dot(0, 0), new Dot(2, 0), new Dot(2, 2), new Dot(0, 2)]

      p = new Polygon d1, d2, d3, d4
      p.addInnerLine d1, d3
      assert.deepEqual(
        {dots: [[0, 0], [2, 0], [2, 2], [0, 2]], inner: [ [0, 2] ]},
        p.serialize())

  describe 'deserialize', ->
    it 'should create a polygon with inner line', ->
      p = new Polygon()
      p.deserialize(
        {dots: [[0, 0], [2, 0], [2, 2], [0, 2]], inner: [ [0, 2] ]},
        {})

      assert.lengthOf p.dots, 4
      assert.lengthOf p.innerLines, 1
