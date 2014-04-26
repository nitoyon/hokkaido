(function(exports) {
'use strict';

var EventEmitter2 = require('eventemitter2').EventEmitter2;

function Dot(x, y) {
	this.x = x;
	this.y = y;
	this.id = Dot.id++;
	this.isSelected = false;

	EventEmitter2.call(this);
}

Dot.id = 1;

Dot.prototype = Object.create(EventEmitter2.prototype);
Dot.prototype.constructor = Dot;
Dot.prototype.del = function() {
	this.emit('exit', this);
};


exports.Dot = Dot;

})(typeof exports === 'undefined'? this : exports);
