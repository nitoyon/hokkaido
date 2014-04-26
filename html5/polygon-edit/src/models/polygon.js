(function(exports) {
'use strict';

var LineFactory = require('./line').LineFactory
  , EventEmitter2 = require('eventemitter2').EventEmitter2;

function PolygonList() {
	this.list = [];
	this.addingPolygon = null;
}

PolygonList.prototype.createAddingPolygon = function() {
	if (this.addingPolygon === null) {
		this.addingPolygon = new Polygon(this);
		this.add(this.addingPolygon);
		return true;
	}
	return false;
};

PolygonList.prototype.add = function(polygon) {
	this.list.push(polygon);

	var self = this;
	polygon.once('exit', function(p) {
		self.del(p);
	});
};

PolygonList.prototype.del = function(polygon) {
	var index = this.list.indexOf(polygon);
	if (index >= 0) {
		this.list.splice(index, 1);
	}
};

PolygonList.prototype.getOuterLines = function() {
	var lines = {};
	this.list.forEach(function(p) {
		p.lines.forEach(function(l) {
			lines[l.id] = l;
		});
	});

	var ret = [];
	for (var id in lines) {
		ret.push(lines[id]);
	}
	return ret;
};

PolygonList.prototype.getDots = function() {
	var dots = {};
	this.list.forEach(function(p) {
		p.dots.forEach(function(d) {
			dots[d.id] = d;
		});
	});

	var ret = [];
	for (var id in dots) {
		ret.push(dots[id]);
	}
	return ret;
};

PolygonList.prototype.serialize = function() {
	return this.list.map(function(polygon) { return polygon.serialize(); });
};

PolygonList.prototype.deserialize = function(data) {
	var dotmap = {};
	var self = this;

	this.list = data.map(function(entry) {
		var polygon = new Polygon(self);
		entry.forEach(function(pos) {
			var key = pos.join(",");
			var dot;
			if (!(key in dotmap)) {
				dotmap[key] = new Dot(pos[0], pos[1]);
			}
			dot = dotmap[key];

			polygon.add(dot);
		});
		polygon.close();
		return polygon;
	});
};

PolygonList.prototype.splitLine = function(line, dot) {
	for (var i = 0; i < this.list.length; i++) {
		this.list[i].splitLine(line, dot);
	}
};

PolygonList.prototype.closeAddingPolygon = function() {
	if (this.addingPolygon && this.addingPolygon.lines.length > 0) {
		this.addingPolygon.close();
	}
	this.addingPolygon = null;
};


function Polygon() {
	this.dots = [];
	this.lines = [];
	this.innerLines = [];
	this.lastDot = null;
	this.id = Polygon.id++;
	this.isClose = false;

	EventEmitter2.call(this);
}

Polygon.id = 1;
Polygon.prototype = Object.create(EventEmitter2.prototype);
Polygon.prototype.constructor = Polygon;

Polygon.isNeighborDot = function(dots, d1, d2) {
	var i1 = dots.indexOf(d1);
	var i2 = dots.indexOf(d2);

	// not in dots -> exception
	if (i1 == -1 || i2 == -1) {
		throw new Error('invalid dot');
	}

	// neighbor -> true
	return (Math.abs(i2 - i1) == 1 || Math.abs(i2 - i1) == dots.length - 1);
};

Polygon.prototype.add = function(d) {
	var index = this.dots.indexOf(d);
	if (index >= 0) {
		return index;
	}

	this.dots.push(d);
	this.updateLines();

	var self = this;
	d.once("exit", function() { self.del(d); });
	return this.dots.length - 1;
};

Polygon.prototype.del = function(d) {
	var index = this.dots.indexOf(d);
	if (index >= 0) {
		this.dots.splice(index, 1);

		if (this.dots.length <= 2) {
			this.emit('exit', this);
			return;
		} else {
			this.updateLines();
		}
	}
};

Polygon.prototype.contains = function(d) {
	return this.dots.indexOf(d) >= 0;
};

Polygon.prototype.toPoints = function() {
	return this.dots.map(function(p) { return p.x + "," + p.y; }).join(" ");
};

Polygon.prototype.serialize = function() {
	return this.dots.map(function(dot) {
		return [dot.x, dot.y];
	});
};

Polygon.prototype.close = function() {
	this.isClose = true;
	this.updateLines();
};

Polygon.prototype.splitLine = function(line, dot) {
	var index = this.lines.indexOf(line);
	if (index < 0) {
		return;
	}

	var i1 = this.dots.indexOf(line.d1);
	var i2 = this.dots.indexOf(line.d2);
	if (i1 > i2) {
		var tmp = i2;
		i2 = i1;
		i1 = tmp;
	}
	if (i1 + 1 == i2) {
		this.dots.splice(i2, 0, dot);
	} else if (i1 === 0 && i2 === this.dots.length - 1) {
		this.dots.push(dot);
	} else {
		throw new Error('invalid polygon');
	}

	var self = this;
	dot.once("exit", function() { self.del(dot); });

	this.updateLines();
};

Polygon.prototype.addInnerLine = function(d1, d2) {
	if (Polygon.isNeighborDot(this.dots, d1, d2)) {
		alert('cannot connect neighborhood dots!!');
		return;
	}

	this.innerLines.push(LineFactory.get(d1, d2));
};

Polygon.prototype.updateLines = function() {
	this.lines = [];
	var d1, d2;
	for (var i = 0; i < this.dots.length - 1; i++) {
		d1 = this.dots[i];
		d2 = this.dots[i + 1];
		this.lines.push(LineFactory.get(d1, d2));
	}

	if (this.isClose && this.dots.length > 2) {
		d1 = this.dots[0];
		d2 = this.dots[this.dots.length - 1];
		this.lines.push(LineFactory.get(d1, d2));
	}
};

exports.PolygonList = PolygonList;
exports.Polygon = Polygon;

})(typeof exports === 'undefined' ? this : exports);
