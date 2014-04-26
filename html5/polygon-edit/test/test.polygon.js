'use strict';

var assert = require('chai').assert
  , PolygonList = require('../src/models/polygon').PolygonList
  , Polygon = require('../src/models/polygon').Polygon
  , DotList = require('../src/models/dot').DotList
  , LineList = require('../src/models/line').LineList;

describe('PolygonList', function() {
  it('should create adding polygon', function() {
    var list = new PolygonList(new LineList());
    assert.isTrue(list.createAddingPolygon());
    var polygon = list.addingPolygon;
    assert.isFalse(polygon.isClose);
    assert.equal(1, list.list.length);
  });

  it('should close adding polygon', function() {
    var list = new PolygonList(new LineList());
    list.createAddingPolygon();
    var polygon = list.addingPolygon;

    var dots = new DotList();
    polygon.add(dots.create(2, 3));
    polygon.add(dots.create(3, 4));
    polygon.add(dots.create(4, 5));
    list.closeAddingPolygon();

    assert.isTrue(polygon.isClose);
  });
});

describe('PolygonList', function() {
  it('should update lines', function() {
    var lines = new LineList();
    var list = new PolygonList(lines);
    var polygon = new Polygon(list, lines);

    var dots = new DotList();
    polygon.add(dots.create(2, 3));
    polygon.add(dots.create(3, 4));
    assert.equal(1, polygon.lines.length);

    polygon.add(dots.create(4, 5));
    assert.equal(2, polygon.lines.length);

    polygon.add(dots.create(6, 7));
    assert.equal(3, polygon.lines.length);

    polygon.close();
    assert.equal(4, polygon.lines.length);

    polygon.add(dots.create(8, 9));
    assert.equal(5, polygon.lines.length);
  });

  it('should del dot', function() {
    var lines = new LineList();
    var list = new PolygonList(lines);
    var polygon = new Polygon(list, lines);

    var dots = new DotList();
    var d = dots.create(2, 3);
    polygon.add(d);
    polygon.add(dots.create(3, 4));
    polygon.add(dots.create(4, 5));
    polygon.add(dots.create(5, 6));
    polygon.close();
    assert.equal(4, polygon.lines.length);

    polygon.del(d);
    assert.equal(3, polygon.lines.length);
  });

  it('should split line', function() {
    var lines = new LineList();
    var list = new PolygonList(lines);
    var polygon = new Polygon(list, lines);

    var dots = new DotList();
    var d1 = dots.create(2, 3)
      , d2 = dots.create(3, 4)
      , d3 = dots.create(4, 5)
      , d4 = dots.create(5, 6);
    polygon.add(d1);
    polygon.add(d2);
    polygon.add(d3);
    polygon.close();
    assert.equal(3, polygon.lines.length);

    polygon.splitLine(polygon.lines[0], d4);
    assert.equal(4, polygon.lines.length);
    assert.equal(4, polygon.dots.length);
    assert.strictEqual(d1, polygon.dots[0]);
    assert.strictEqual(d4, polygon.dots[1]);
    assert.strictEqual(d2, polygon.dots[2]);
    assert.strictEqual(d3, polygon.dots[3]);
  });
});
