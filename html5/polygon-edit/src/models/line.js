(function(exports) {
'use strict';

var LineFactory = {
	id2line: {}
};

LineFactory.get = function(d1, d2) {
	var l = new Line(d1, d2);
	if (l.id in LineFactory.id2line) {
		return LineFactory.id2line[l.id];
	} else {
		LineFactory.id2line[l.id] = l;
		return l;
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
	this.id = this.d1.id + "," + this.d2.id;
}

Line.prototype.contains = function(d) {
	return (this.d1 == d || this.d2 == d);
};


exports.LineFactory = LineFactory;
exports.Line = Line;

})(typeof exports === 'undefined' ? this : exports);
