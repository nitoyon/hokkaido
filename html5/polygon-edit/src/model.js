var EventEmitter2 = require('eventemitter2').EventEmitter;

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
Dot.prototype = Object.create(EventEmitter2.prototype);
Dot.prototype.constructor = Dot;
Dot.prototype.del = function() {
	this.container.del(this);
	this.emit('exit', this);
};


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
}

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
}


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
}


function PolygonList(allLines) {
	this.list = [];
	this.allLines = allLines;
	this.addingPolygon = null;
}

PolygonList.prototype.createAddingPolygon = function() {
	if (this.addingPolygon == null) {
		this.addingPolygon = new Polygon(this, this.allLines);
		this.list.push(this.addingPolygon);
		return true;
	}
	return false;
};

PolygonList.prototype.add = function(polygon) {
	this.list.push(polygon);
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

PolygonList.prototype.serialize = function() {
	return this.list.map(function(polygon) { return polygon.serialize(); });
};

PolygonList.prototype.deserialize = function(data, dots) {
	var dotmap = {};
	var self = this;

	this.list = data.map(function(entry) {
		var polygon = new Polygon(self, self.allLines);
		entry.forEach(function(pos) {
			var key = pos.join(",");
			var dot;
			if (!(key in dotmap)) {
				dotmap[key] = dots.create(pos[0], pos[1]);
				dots.add(dotmap[key]);
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
	this.allLines.del(line);
};

PolygonList.prototype.closeAddingPolygon = function() {
	if (this.addingPolygon && this.addingPolygon.lines.length > 0) {
		this.addingPolygon.close();
	}
	this.addingPolygon = null;
};


function Polygon(container, allLines) {
	this.dots = [];
	this.allLines = allLines;
	this.lines = [];
	this.innerLines = [];
	this.lastDot = null;
	this.container = container;
	this.id = Polygon.id++;
	this.isClose = false;
}
Polygon.id = 1;

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

Polygon.prototype = {
	add: function(d) {
		var index = this.dots.indexOf(d);
		if (index >= 0) {
			return index;
		}

		this.dots.push(d);
		this.updateLines();

		var self = this;
		d.on("exit", function() { console.log('called'); self.del(d); });
		return this.dots.length - 1;
	},

	del: function(d) {
		var index = this.dots.indexOf(d);
		if (index >= 0) {
			this.dots.splice(index, 1);
			d.removeAllListeners("exit");

			this.allLines.delDot(d);

			if (this.dots.length == 0) {
				this.container.del(this);
				return;
			} else {
				this.updateLines();
			}
		}
	},

	contains: function(d) {
		return this.dots.indexOf(d) >= 0;
	},

	toPoints: function() {
		return this.dots.map(function(p) { return p.x + "," + p.y; }).join(" ");
	},

	serialize: function() {
		return this.dots.map(function(dot) {
			return [dot.x, dot.y];
		});
	},

	close: function() {
		this.isClose = true;
		this.updateLines();
	},

	splitLine: function(line, dot) {
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
		} else if (i1 == 0 && i2 == this.dots.length - 1) {
			this.dots.push(dot);
		} else {
			throw new Error('invalid polygon');
		}

		var self = this;
		dot.on("exit", function() { self.del(dot); });

		this.updateLines();
	},

	addInnerLine: function(d1, d2) {
		if (Polygon.isNeighborDot(this.dots, d1, d2)) {
			alert('cannot connect neighborhood dots!!');
			return;
		}

		this.innerLines.push(this.allLines.create(d1, d2));
	},

	updateLines: function() {
		this.lines = [];
		for (var i = 0; i < this.dots.length - 1; i++) {
			var d1 = this.dots[i];
			var d2 = this.dots[i + 1];
			this.lines.push(this.allLines.create(d1, d2));
		}

		if (this.isClose && this.dots.length > 2) {
			d1 = this.dots[0];
			d2 = this.dots[this.dots.length - 1];
			this.lines.push(this.allLines.create(d1, d2));
		}
	}
};
