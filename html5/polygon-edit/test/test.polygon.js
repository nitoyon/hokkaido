'use strict';

var assert = require('chai').assert
  , PolygonList = require('../src/models/polygon').PolygonList
  , Polygon = require('../src/models/polygon').Polygon
  , Dot = require('../src/models/dot').Dot
  , LineList = require('../src/models/line').LineList;

describe('PolygonList', function() {
  it('should create adding polygon', function() {
    var list = new PolygonList();
    assert.isTrue(list.createAddingPolygon());
    var polygon = list.addingPolygon;
    assert.isFalse(polygon.isClose);
    assert.equal(1, list.list.length);
  });

  it('should close adding polygon', function() {
    var list = new PolygonList();
    list.createAddingPolygon();
    var polygon = list.addingPolygon;

    polygon.add(new Dot(2, 3));
    polygon.add(new Dot(3, 4));
    polygon.add(new Dot(4, 5));
    list.closeAddingPolygon();

    assert.isTrue(polygon.isClose);
  });
});

describe('PolygonList', function() {
  it('should update lines', function() {
    var list = new PolygonList();
    var polygon = new Polygon(list);

    polygon.add(new Dot(2, 3));
    polygon.add(new Dot(3, 4));
    assert.equal(1, polygon.lines.length);

    polygon.add(new Dot(4, 5));
    assert.equal(2, polygon.lines.length);

    polygon.add(new Dot(6, 7));
    assert.equal(3, polygon.lines.length);

    polygon.close();
    assert.equal(4, polygon.lines.length);

    polygon.add(new Dot(8, 9));
    assert.equal(5, polygon.lines.length);
  });

  it('should del dot', function() {
    var list = new PolygonList();
    var polygon = new Polygon(list);

    var d = new Dot(2, 3);
    polygon.add(d);
    polygon.add(new Dot(3, 4));
    polygon.add(new Dot(4, 5));
    polygon.add(new Dot(5, 6));
    polygon.close();
    assert.equal(4, polygon.lines.length);

    polygon.del(d);
    assert.equal(3, polygon.lines.length);
  });

  it('should split line', function() {
    var list = new PolygonList();
    var polygon = new Polygon(list);

    var d1 = new Dot(2, 3)
      , d2 = new Dot(3, 4)
      , d3 = new Dot(4, 5)
      , d4 = new Dot(5, 6);
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
