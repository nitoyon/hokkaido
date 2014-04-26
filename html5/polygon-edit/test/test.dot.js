'use strict';

var assert = require('chai').assert
  , dot = require('../src/models/dot')
  , Dot = dot.Dot
  , DotList = dot.DotList;

describe('DotList', function() {
  it('should create a dot', function() {
    var list = new DotList();
    var d = list.create(2, 3);

    assert.equal(2, d.x);
    assert.equal(3, d.y);
    assert.equal(list, d.container);
    assert.equal(1, d.id);
  });

  it('should create two dots', function() {
    var list = new DotList();
    var d1 = list.create(2, 3);
    var d2 = list.create(5, 6);

    assert.equal(1, d1.id);
    assert.equal(2, d2.id);
  });

  it('should delete a dot', function() {
    var list = new DotList();
    var d = list.create(2, 3);
    list.add(d);
    assert.equal(1, list.list.length);

    var called = false;
    d.on('exit', function() {
      called = true;
    });
    d.del();
    assert.equal(0, list.list.length);
    assert.isTrue(called);
  });
});
