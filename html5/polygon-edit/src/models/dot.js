(function(exports) {
'use strict';

var EventEmitter2 = require('eventemitter2').EventEmitter2;

function DotList() {
	this.list = [];
	this.id = 1;
}
DotList.prototype = {
	create: function(x, y) {
		return new Dot(x, y, this.id++, this);
	},

	add: function(dot) {
		this.list.push(dot);
		return dot;
	},

	del: function(dot) {
		var index = this.list.indexOf(dot);
		if (index >= 0) {
			this.list.splice(index, 1);
		}
	}
};


function Dot(x, y, id, container) {
	this.x = x;
	this.y = y;
	this.id = id;
	this.container = container;
	this.isSelected = false;

	EventEmitter2.call(this);
}
Dot.prototype = {};
Object.create(EventEmitter2.prototype);
Dot.prototype = Object.create(EventEmitter2.prototype);
Dot.prototype.constructor = Dot;
Dot.prototype.del = function() {
	this.container.del(this);
	this.emit('exit', this);
};


exports.DotList = DotList;
exports.Dot = Dot;

})(typeof exports === 'undefined'? this : exports);
