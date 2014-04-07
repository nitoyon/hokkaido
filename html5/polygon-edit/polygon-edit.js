function MapEditor(elm, json) {
	this.init(elm, json);
}
MapEditor.prototype = {
	data: null,
	selectedItem: null,
	modes: [],

	init: function(elm, json) {
		this.initModel();
		this.initElement(elm);
		this.initJson(json);
		this.initEvent();
		this.updateView();
	},

	initModel: function() {
		this.dots = new DotList();
		this.lines = new LineList();
		this.polygons = new PolygonList(this.lines);

		if (localStorage["polygon"]) {
			var data = JSON.parse(localStorage["polygon"]);
			this.polygons.deserialize(data, this.dots);
		}
	},

	initElement: function(elm) {
		this.elm = elm;
		this.svg = d3.select(elm);
		this.canvas = this.svg.append("svg:g").attr("id", "canvas");
		this.mapContainer = this.canvas.append("svg:g").attr("id", "map_pathes");
		this.polygonView = new PolygonView(this, this.polygons);
		this.lineView = new LineView(this, this.polygons);
		this.dotView = new DotView(this, this.dots);

		this.modeView = new ModeView(this, [new PointMode(this), new PolygonMode(this)]);

		var self = this;
		this.dots.on('change.view', function() { self.dotView.update(); });
	},

	initJson: function(json) {
		var geodata = json.features;

	  var projection = d3.geo
	    .mercator()        //投影法の指定
	    .scale(1200)    //スケール（ズーム）の指定
	    .rotate([-150,0,0])
	    .translate([580, 1100]);
	 
	  var path = d3.geo.path().projection(projection); //投影
	  var color = d3.scale.category20();
	  
	  map = this.mapContainer
	    .selectAll("path")
	    .data(geodata)
	    .enter()
	    .append("svg:path")
	    .attr({
	      "d": path,
	      "fill-opacity": 0.8
	    })
	    .attr("fill", function(i) { return color(i.properties.ObjName); })
	},

	initEvent: function() {
		var self = this;
		d3.select(document).on("keydown", function() {
			//console.log(d3.event.keyCode);
			switch (d3.event.keyCode) {
				case 46:  // del
					self.del();
					break;
				case 187: // +
					self.zoom.zoomUp();
					break;
				case 189: // -
					self.zoom.zoomDown();
					break;
			}
		});

		this.zoom = new MapZoom(this.svg, this.canvas);
		this.zoom.on('scaleChange', function() {
			self.onZoomChange();
		});
		if (localStorage["zoom"]) {
			this.zoom.deserialize(JSON.parse(localStorage["zoom"]));
			this.zoom.update();
		}

		var dragging = false, drag_moved = false;
		this.drag = d3.behavior.drag()
			.on("dragstart", function(d) {
				dragging = drag_moved = false;

				// drag the most foreground draggable object
				d3.event.sourceEvent.stopPropagation();
			})
			.on("dragend", function(d, i) {
				if (!drag_moved) {
					self.onClick(d, i, this);
				} else {
					self.onDragEnd(d, i, this);
				}
			})
			.on("drag", function(d, i) {
				if (!dragging) {
					// skip first event (triggered on mouse down)
					dragging = true;
					return;
				} else if (!drag_moved) {
					// trigger onDragStart on first move
					drag_moved = true;
					self.onDragStart(d, i, this);
				}
				self.onDrag(d, i, this);
			});
		this.svg.call(this.drag);

		this.modeView.on('change', function() { self.updateView(); });
	},

	updateView: function() {
		this.dotView.update();
		this.lineView.update();
		this.polygonView.update();

		localStorage["polygon"] = JSON.stringify(this.polygons.serialize());
		localStorage["zoom"] = JSON.stringify(this.zoom.serialize());
	},

	del: function() {
		if (this.selectedItem) {
			this.selectedItem.del();
			this.selectedItem = null;
			this.updateView();
		}
	},

	select: function(item) {
		var prev = this.unselect();

		this.selectedItem = item;
		if (item) {
			item.isSelected = true;
		}
		return prev;
	},

	unselect: function() {
		var prev = null;
		if (this.selectedItem != null) {
			prev = this.selectedItem;
			this.selectedItem.isSelected = false;
		}
		this.selectedItem = null;
		return prev;
	},

	onDragStart: function(d, i, elm) {
		this.modeView.currentMode.onDragStart(d, i, elm);
		this.updateView();
	},

	onDrag: function(d, i, elm) {
		this.modeView.currentMode.onDrag(d, i, elm);
		this.updateView();
	},

	onDragEnd: function(d, i, elm) {
		this.modeView.currentMode.onDragEnd(d, i, elm);
		this.updateView();
	},

	onClick: function(d, i, elm, event) {
		var prevEvent = d3.event;
		d3.event = d3.event.sourceEvent;
		this.modeView.currentMode.onClick(d, i);
		d3.event = prevEvent;
		this.updateView();
	},

	onZoomChange: function() {
		this.updateView();
	}
};

function Mode(name, app) {
	this.name = name;
	this.app = app;
}
Mode.prototype = {
	onClick: function(d, i) {
		var prev = this.app.unselect();
		if (d != null) {
			this.app.select(d);
		}
	},

	onDragStart: function(d, i) {},

	onDrag: function(d, i) {
		var event = d3.event;
		var p = this.app.zoom.clientToWorld(event.x, event.y);
		if (d == null) {
			this.app.zoom.x += event.dx;
			this.app.zoom.y += event.dy;
			this.app.zoom.update();
		} else if (d instanceof Dot) {
			this.app.select(d);
			d.x += event.dx;
			d.y += event.dy;
		}
	},

	onDragEnd: function(d, i) {}
};

function PointMode(app) {
	this.app = app;
	this.name = 'point';
}
PointMode.prototype = Object.create(Mode.prototype);
PointMode.prototype.onClick = function(d, i) {
	var event = d3.event;

	// Ctrl + click -> close
	if (event.ctrlKey) {
		this.app.polygons.close_adding_polygon();
		Mode.prototype.onClick.call(this, d, i);
		return;
	}

	if (d == null) {
		// click none -> add dot
		var p = this.app.zoom.clientToWorld(event.offsetX, event.offsetY);
		d = this.app.dots.create(p.x, p.y);
		this.app.select(d);
		this.app.dots.add(d);

		this.app.polygons.create_adding_polygon();
		this.app.polygons.adding_polygon.add(d);
	} else if (d instanceof Dot) {
		// click dot -> connect
		var create = this.app.polygons.create_adding_polygon();
		var index = this.app.polygons.adding_polygon.add(d);

		// click first dot -> close
		if (index == 0 && !create) {
			this.app.polygons.close_adding_polygon();
		}
		this.app.select(d);
	} else if (d instanceof Line) {
		// click line -> add dot
		var p = this.app.zoom.clientToWorld(event.offsetX, event.offsetY);
		var dot = this.app.dots.create(p.x, p.y);
		this.app.dots.add(dot);
		this.app.polygons.splitLine(d, dot);
	}
}

function PolygonMode(app) {
	this.app = app;
	this.name = 'polygon';
}
PolygonMode.prototype = Object.create(Mode.prototype);
PolygonMode.prototype.onClick = function(d, i) {
	// select polygon
	var event = d3.event;
	if (d instanceof Polygon) {
		this.app.select(d);
	} else {
		this.app.unselect();
	}
};

PolygonMode.prototype.onDragStart = function(d, i) {
	if (!(d instanceof Dot)) {
		return;
	}

	var p = this.app.selectedItem;
	p.draggingLine = {
		d1: d,
		d2: {x: 0, y: 0}
	};
};

PolygonMode.prototype.onDrag = function(d, i) {
	if (!(d instanceof Dot)) {
		Mode.prototype.onDrag.call(this, d, i);
		return;
	}

	var data = d3.select(d3.event.sourceEvent.target).data();
	var src;
	if (data.length > 0 && data[0] instanceof Dot) {
		src = data[0];
	} else {
		src = d3.event;
	}

	var p = this.app.selectedItem;
	p.draggingLine.d2.x = src.x
	p.draggingLine.d2.y = src.y
}

PolygonMode.prototype.onDragEnd = function(d, i) {
	if (d instanceof Dot) {
		var p = this.app.selectedItem;
		p.draggingLine = null;
	}
}


function ModeView(app, modes) {
	this.app = app;
	this.dispatch = d3.dispatch("change");
	d3.rebind(this, this.dispatch, "on");

	var lastMode = modes.filter(function(m) { return m.name == localStorage["mode"]; });
	this.setMode(lastMode.length > 0 ? lastMode[0] : modes[0]);

	var self = this;
	var inputs = d3.select("#modes").selectAll("input").data(modes).enter()
		.append("span");
	inputs.append("input")
		.attr({
			"type": "radio",
			"name": "mode",
			"id": function(d) { return "mode-" + d.name; }
		})
		.property("checked", function(d) { return self.currentMode == d; })
		.on("click", function(d) { self.setMode(d); });

	inputs.append("label")
		.attr("for", function(d) { return "mode-" + d.name; })
		.text(function(d) { return d.name; });
}
ModeView.prototype = {
	setMode: function(mode) {
		this.currentMode = mode;
		this.app.svg.attr('class', mode.name);
		this.dispatch.change();

		localStorage["mode"] = mode.name;
	}
};

function DotView(app, dots) {
	this.app = app;
	this.dots = dots;

	this.view = app.canvas.append("svg:g").attr("id", "dots");
}
DotView.prototype = {
	update: function() {
		var dots = this.dots.list;
		if (this.app.modeView.currentMode.name == 'polygon') {
			var p = this.app.selectedItem;
			if (p instanceof(Polygon)) {
				dots = p.dots;
			} else {
				dots = [];
			}
		}

		var s = this.view.selectAll("circle")
			.data(dots);
		s.enter()
			.append("circle")
			.call(this.app.drag);
		s.exit().remove();
		s
			.classed("selected", function(d) { return d.isSelected; })
			.attr("cx", function(d) { return d.x; })
			.attr("cy", function(d) { return d.y; })
			.attr("r", 5 / this.app.zoom.scale);
	}
};

function PolygonView(app, polygons) {
	this.app = app;
	this.polygons = polygons;
	this.view = app.canvas.append("svg:g").attr("id", "polygons");
}
PolygonView.prototype = {
	update: function() {
		if (this.app.modeView.currentMode.name != "polygon") {
			this.view.selectAll("polygon").data([]).exit().remove();
			return;
		}

		var s = this.view.selectAll("polygon")
			.data(this.polygons.list);
		s.enter().append("polygon").call(this.app.drag);
		s.exit().remove();
		s
			.attr("points", function(d) { return d.toPoints(); })
			.classed("selected", function(d) { return d.isSelected; });

		var line = null;
		if (this.app.selectedItem instanceof Polygon) {
			line = this.app.selectedItem.draggingLine;
		}
		var l = this.view.selectAll("line")
			.data(line ? [line] : []);
		l.enter().append("line");
		l.exit().remove();
		l
			.attr({
				x1: function(d) { return d.d1.x; },
				y1: function(d) { return d.d1.y; },
				x2: function(d) { return d.d2.x; },
				y2: function(d) { return d.d2.y; },
				"stroke-width": 2 / this.app.zoom.scale
			});
	}
};

function LineView(app, polygons) {
	this.app = app;
	this.polygons = polygons;

	this.view = app.canvas.append("svg:g").attr("id", "lines");
}
LineView.prototype = {
	update: function() {
		var s = this.view.selectAll("line")
			.data(this.polygons.lineList.list);
		s.enter()
			.append("line")
			.call(this.app.drag);
		s.exit().remove();
		s
			.attr("x1", function(d) { return d.d1.x; })
			.attr("y1", function(d) { return d.d1.y; })
			.attr("x2", function(d) { return d.d2.x; })
			.attr("y2", function(d) { return d.d2.y; })
			.attr("stroke-width", 2 / this.app.zoom.scale);
	}
};


function DotList() {
	this.list = [];
	this.id = 1;

	this.dispatch = d3.dispatch("change");
	d3.rebind(this, this.dispatch, "on");
}
DotList.prototype = {
	create: function(x, y) {
		return new Dot(x, y, this.id++, this);
	},

	add: function(dot) {
		this.list.push(dot);
		this.dispatch.change({ added: dot, deleted: null });
		return dot;
	},

	del: function(dot) {
		var index = this.list.indexOf(dot);
		if (index >= 0) {
			this.list.splice(index, 1);
			this.dispatch.change({ added: null, deleted: dot });
		}
	}
};

function Dot(x, y, id, container) {
	this.x = x;
	this.y = y;
	this.id = id;
	this.container = container;
	this.isSelected = false;

	this.dispatch = d3.dispatch("exit");
	d3.rebind(this, this.dispatch, "on");
}
Dot.prototype = {
	del: function() {
		this.container.del(this);
		this.dispatch.exit();
	}
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

LineList.prototype.del_dot = function(d) {
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


function PolygonList(lineList) {
	this.list = [];
	this.lineList = lineList;
	this.adding_polygon = null;
}

PolygonList.prototype.create_adding_polygon = function() {
	if (this.adding_polygon == null) {
		this.adding_polygon = new Polygon(this, this.lineList);
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
	} else if (polygon == this.adding_polygon) {
		this.adding_polygon = null;
	}
};

PolygonList.prototype.serialize = function() {
	return this.list.map(function(polygon) { return polygon.serialize(); });
};

PolygonList.prototype.deserialize = function(data, dots) {
	var dotmap = {};
	var self = this;

	this.list = data.map(function(entry) {
		var polygon = new Polygon(self, self.lineList);
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
	this.lineList.del(line);
};

PolygonList.prototype.close_adding_polygon = function() {
	if (this.adding_polygon && this.adding_polygon.lines.length > 0) {
		this.adding_polygon.close();
		this.add(this.adding_polygon);
	}
	this.adding_polygon = null;
};


function Polygon(container, lineList) {
	this.dots = [];
	this.lineList = lineList;
	this.lines = [];
	this.last_dot = null;
	this.container = container;
	this.id = Polygon.id++;
	this.is_close = false;
}
Polygon.id = 1;
Polygon.prototype = {
	add: function(d) {
		var index = this.dots.indexOf(d);
		if (index >= 0) {
			return index;
		}

		this.dots.push(d);
		this.updateLines();

		var self = this;
		d.on("exit.polygon" + this.id, function() { self.del(d); });
		return this.dots.length - 1;
	},

	del: function(d) {
		var index = this.dots.indexOf(d);
		if (index >= 0) {
			this.dots.splice(index, 1);
			d.on("exit.polygon" + this.id, null);

			this.lineList.del_dot(d);

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
		this.is_close = true;
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
			throw Error('invalid polygon');
		}

		var self = this;
		dot.on("exit.polygon" + this.id, function() { self.del(dot); });

		this.updateLines();
	},

	updateLines: function() {
		this.lines = [];
		for (var i = 0; i < this.dots.length - 1; i++) {
			var d1 = this.dots[i];
			var d2 = this.dots[i + 1];
			this.lines.push(this.lineList.create(d1, d2));
		}

		if (this.is_close && this.dots.length > 2) {
			d1 = this.dots[0];
			d2 = this.dots[this.dots.length - 1];
			this.lines.push(this.lineList.create(d1, d2));
		}
	}
};

function MapZoom(elm, target) {
	this.elm = elm;
	this.target = target;

	this.dispatch = d3.dispatch("scaleChange");
	d3.rebind(this, this.dispatch, "on");
}
MapZoom.prototype = {
	x: 0,
	y: 0,
	scale: 1,

	zoomUp: function() {
		this.setScale(this.scale * 2);
	},
	
	zoomDown: function() {
		this.setScale(this.scale / 2);
	},

	setScale: function(val) {
		if (isNaN(val) || val < 1 || val == this.scale) {
			return;
		}

		var old = this.scale;
		this.x = (this.x - 300) / this.scale * val + 300;
		this.y = (this.y - 300) / this.scale * val + 300;
		this.scale = val;

		this.update();
		this.scaleChange({old_scale: old, new_scale: this.scale});
	},

	clientToWorld: function(x, y) {
		return {
			x: (x - this.x) / this.scale,
			y: (y - this.y) / this.scale
		};
	},

	update: function() {
		this.target.attr("transform",
			"translate(" + this.x + "," + this.y + ") " +
			"scale(" + this.scale + ")");
	},
	
	scaleChange: function() {
		this.dispatch.scaleChange();
	},

	serialize: function() {
		return {x: this.x, y: this.y, scale: this.scale };
	},

	deserialize: function(data) {
		if (!isNaN(data.x)) this.x = data.x;
		if (!isNaN(data.y)) this.y = data.y;
		if (!isNaN(data.scale)) this.scale = data.scale;
	}
};

var map;
d3.json("out.geojson", function(json) {
  map = new MapEditor(document.getElementById("map"), json);
});
