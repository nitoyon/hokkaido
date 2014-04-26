'use strict';

var assert = require('chai').assert
  , Dot = require('../src/models/dot').Dot
  , line = require('../src/models/line')
  , Line = line.Line
  , LineFactory = line.LineFactory;

describe('LineFactory', function() {
  it('should cache', function() {
    var d1 = new Dot(2, 3);
    var d2 = new Dot(4, 5);

    var l = LineFactory.get(d1, d2);
    assert.strictEqual(l, LineFactory.get(d1, d2));
    assert.strictEqual(l, LineFactory.get(d2, d1));
  });
});

describe('Line', function() {
  it('contains', function() {
    var d1 = new Dot(2, 3);
    var d2 = new Dot(4, 5);
    var d3 = new Dot(6, 7);

    var l = LineFactory.get(d1, d2);

    assert.isTrue(l.contains(d1));
    assert.isTrue(l.contains(d2));
    assert.isFalse(l.contains(d3));
  });
});
