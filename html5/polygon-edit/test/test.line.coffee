'use strict'

{assert} = require 'chai'
{Dot} = require '../src/models/dot'
{Line} = require '../src/models/line'
{LineFactory} = require '../src/models/line'

describe 'LineFactory', ->
  it 'should cache', ->
    d1 = new Dot(2, 3)
    d2 = new Dot(4, 5)

    l = LineFactory.get(d1, d2)
    assert.strictEqual(l, LineFactory.get(d1, d2))
    assert.strictEqual(l, LineFactory.get(d2, d1))

describe 'Line', ->
  it 'contains', ->
    d1 = new Dot(2, 3)
    d2 = new Dot(4, 5)
    d3 = new Dot(6, 7)

    l = LineFactory.get(d1, d2)

    assert.isTrue l.contains(d1)
    assert.isTrue l.contains(d2)
    assert.isFalse l.contains(d3)

  describe 'getAnotherDot', ->
    it 'should return valid dot', ->
      d1 = new Dot(2, 3)
      d2 = new Dot(4, 5)
      l = LineFactory.get(d1, d2)

      assert.strictEqual d1, l.getAnotherDot(d2)
      assert.strictEqual d2, l.getAnotherDot(d1)

    it 'should throw an error if invalid dot is given', ->
      d1 = new Dot(2, 3)
      d2 = new Dot(4, 5)
      l = LineFactory.get(d1, d2)

      d3 = new Dot(2, 3)
      assert.throws (-> l.getAnotherDot d3),
        'invalid dot is given'
