'use strict'

{assert} = require 'chai'
{Dot} = require '../src/models/dot'

describe 'Dot', ->
  it 'should be created', ->
    dot = new Dot(2, 3)
    assert.equal 2, dot.x
    assert.equal 3, dot.y

  it 'should have id', ->
    d1 = new Dot(2, 3)
    d2 = new Dot(5, 6)

    assert.equal d2.id, d1.id + 1
