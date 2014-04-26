(function(exports) {
'use strict';

function LineList() {
	this.list = [];
	this.id2line = {};
}

LineList.prototype.create = function(d1, d2) {
	var l = new Line(d1, d2);
	if (l.id in this.id2line) {
		return this.id2line[l.id];
	} else {
		this.list.push(l);
		this.id2line[l.id] = l;
		return l;
	}
};

LineList.prototype.delDot = function(d) {
	for (var i = this.list.length - 1; i >= 0; i--) {
		var line = this.list[i];
		if (line.contains(d)) {
			this.list.splice(i, 1);
			delete this.id2line[line.id];
		}
	}
};

LineList.prototype.del = function(l) {
	var index = this.list.indexOf(l);
	if (index >= 0) {
		this.list.splice(index, 1);
		delete this.id2line[l.id];
	}
};


function Line(d1, d2) {
	if (d1.id == d2.id) {
		throw new Error('invalid line');
	}
	if (d1.id < d2.id) {
		this.d1 = d1;
		this.d2 = d2;
	} else {
		this.d1 = d2;
		this.d2 = d1;
	}
	this.id = d1.id + "," + d2.id;
}

Line.prototype.contains = function(d) {
	return (this.d1 == d || this.d2 == d);
};


exports.LineList = LineList;
exports.Line = Line;

})(typeof exports === 'undefined'? this : exports);
