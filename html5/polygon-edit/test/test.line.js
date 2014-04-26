'use strict';

var assert = require('chai').assert
  , DotList = require('../src/models/dot').DotList
  , line = require('../src/models/line')
  , Line = line.Line
  , LineList = line.LineList;

describe('LineList', function() {
  it('should cache', function() {
    var dots = new DotList();
    var d1 = dots.create(2, 3);
    var d2 = dots.create(4, 5);

    var lines = new LineList();
    var l = lines.create(d1, d2);
    assert.equal(1, lines.list.length);

    assert.strictEqual(l, lines.create(d1, d2));
    assert.equal(1, lines.list.length);

    assert.strictEqual(l, lines.create(d2, d1));
    assert.equal(1, lines.list.length);
  });

  it('should del line', function() {
    var dots = new DotList();
    var d1 = dots.create(2, 3);
    var d2 = dots.create(4, 5);

    var lines = new LineList();
    var l = lines.create(d1, d2);
    assert.equal(1, lines.list.length);

    lines.del(l);
    assert.equal(0, lines.list.length);
  });

  it('should del dot', function() {
    var dots = new DotList();
    var d1 = dots.create(2, 3);
    var d2 = dots.create(4, 5);
    var d3 = dots.create(6, 7);

    var lines = new LineList();
    lines.create(d1, d2);
    var l = lines.create(d2, d3);
    lines.create(d3, d1);
    assert.equal(3, lines.list.length);

    lines.delDot(d1);
    assert.equal(1, lines.list.length);
    assert.equal(l, lines.list[0]);
  });
});

describe('Line', function() {
  it('contains', function() {
    var dots = new DotList();
    var d1 = dots.create(2, 3);
    var d2 = dots.create(4, 5);
    var d3 = dots.create(6, 7);

    var lines = new LineList();
    var l = lines.create(d1, d2);

    assert.isTrue(l.contains(d1));
    assert.isTrue(l.contains(d2));
    assert.isFalse(l.contains(d3));
  });
});
