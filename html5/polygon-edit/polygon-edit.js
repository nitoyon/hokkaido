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
	},

	initModel: function() {
		this.dots = new DotList();
		this.polygons = new PolygonList();
	},

	initElement: function(elm) {
		this.elm = elm;
		this.svg = d3.select(elm);
		this.canvas = this.svg.append("svg:g").attr("id", "canvas");
		this.mapContainer = this.canvas.append("svg:g").attr("id", "map_pathes");
		this.polygonView = new PolygonView(this, this.polygons);
		this.dotView = new DotView(this, this.dots);

		this.modeView = new ModeView([new PointMode(this), new LineMode(this)]);

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
			console.log(d3.event.keyCode);
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

		var dragging = false;
		this.drag = d3.behavior.drag()
			.on("dragstart", function(d) {
				console.log("dragstart");
				dragging = false;
				// drag the most foreground draggable object
				d3.event.sourceEvent.stopPropagation();
			})
			.on("dragend", function(d, i) {
				if (!dragging) {
					self.onClick(d, i, this);
				}
			})
			.on("drag", function(d, i) {
				console.log("dragging");
				dragging = true;
				self.onDrag(d, i, this);
			});
		this.svg.call(this.drag);
	},

	updateView: function() {
		this.dotView.update();
		this.polygonView.update();
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

	onDrag: function(d, i, elm) {
		this.modeView.currentMode.onDrag(d, i, elm);
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
	}
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

		if (this.app.polygons.adding_polygon == null) {
			this.app.polygons.adding_polygon = new Polygon();
		}
		this.app.polygons.adding_polygon.add(d);
	} else if (d instanceof Dot) {
		// click dot -> connect
		var create = false;
		if (this.app.polygons.adding_polygon == null) {
			this.app.polygons.adding_polygon = new Polygon();
			create = true;
		}
		var index = this.app.polygons.adding_polygon.add(d);

		// click first dot -> close
		if (index == 0 && !create) {
			this.app.polygons.close_adding_polygon();
		}
		this.app.select(d);
	}
}

function LineMode(app) {
	this.app = app;
	this.name = 'line';
}
LineMode.prototype = Object.create(Mode.prototype);
LineMode.prototype.onClick = function(d, i) {
	var prev = null;

	// add dot
	var event = d3.event;
	if (d instanceof Dot) {
		if (this.line) {
			this.line.add(d);
		}
	} else {
		this.line = null;
	}
}


function ModeView(modes) {
	this.currentMode = modes[0];

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
		.on("click", function(d) { self.currentMode = d; });

	inputs.append("label")
		.attr("for", function(d) { return "mode-" + d.name; })
		.text(function(d) { return d.name; });
}

function DotView(app, dots) {
	this.app = app;
	this.dots = dots;

	this.view = app.canvas.append("svg:g").attr("id", "dots");
}
DotView.prototype = {
	update: function() {
		var s = this.view.selectAll("circle")
			.data(this.dots.list);
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

	this.view = app.canvas.append("svg:g").attr("id", "lines");
}
PolygonView.prototype = {
	update: function() {
		var s = this.view.selectAll("polygon")
			.data(this.polygons.list);
		s.enter()
			.append("polygon")
			.call(this.app.drag);
		s.exit().remove();
		s
			.attr("points", function(d) { return d.points(); })
			.attr("stroke-width", 2 / this.app.zoom.scale);

		var s = this.view.selectAll("polyline")
			.data(this.polygons.adding_polygon ? [this.polygons.adding_polygon] : []);
		s.enter()
			.append("polyline")
			.call(this.app.drag);
		s.exit().remove();
		s
			.attr("points", function(d) { return d.points(); })
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


function PolygonList() {
	this.list = [];
	this.adding_polygon = null;
}

PolygonList.prototype.add = function(polygon) {
	this.list.push(polygon);
};

PolygonList.prototype.del = function(polygon) {
	var index = this.list.indexOf(polygon);
	if (index >= 0) {
		this.list.splice(index, 1);
	}
};

PolygonList.prototype.close_adding_polygon = function() {
	if (this.adding_polygon && this.adding_polygon.points() != "") {
		this.add(this.adding_polygon);
	}
	this.adding_polygon = null;
};


function Polygon() {
	this.list = [];
}
Polygon.prototype = {
	add: function(d) {
		var index = this.list.indexOf(d);
		if (index >= 0) {
			return index;
		}

		this.list.push(d);
		var self = this;
		d.on("exit.polygon", function() { self.del(d); });
		return this.list.length - 1;
	},

	del: function(d) {
		var index = this.list.indexOf(d);
		if (index >= 0) {
			this.list.splice(index, 1);
		}
	},

	points: function() {
		return this.list.map(function(d) { return [d.x, d.y]; }).join(" ");
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
	}
};

var map;
d3.json("out.geojson", function(json) {
  map = new MapEditor(document.getElementById("map"), json);
});
