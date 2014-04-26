'use strict';

var assert = require('chai').assert
  , dot = require('../src/models/dot')
  , Dot = dot.Dot;

describe('Dot', function() {
  it('should be created', function() {
    var dot = new Dot(2, 3);
    assert.equal(2, dot.x);
    assert.equal(3, dot.y);
  });

  it('should have id', function() {
    var d1 = new Dot(2, 3);
    var d2 = new Dot(5, 6);

    assert.equal(d2.id, d1.id + 1);
  });
});
