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
		this.lines = new LineList(this.dots);
	},

	initElement: function(elm) {
		this.elm = elm;
		this.svg = d3.select(elm);
		this.canvas = this.svg.append("svg:g").attr("id", "canvas");
		this.mapContainer = this.canvas.append("svg:g").attr("id", "map_pathes");
		this.lineView = new LineView(this, this.lines);
		this.dotView = new DotView(this, this.dots);

		this.modeView = new ModeView([new PointMode(this), new LineMode(this)]);

		var self = this;
		this.dots.on('change.view', function() { self.dotView.update(); });
		this.lines.on('change.view', function() { self.lineView.update(); });
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
		this.lineView.update();
	},

	del: function() {
		if (this.selectedItem) {
			this.selectedItem.del();
			this.selectedItem = null;
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
	var prev = null;

	// add dot
	var event = d3.event;
	if (d == null && !event.ctrlKey) {
		var p = this.app.zoom.clientToWorld(event.offsetX, event.offsetY);
		d = this.app.dots.create(p.x, p.y);
		prev = this.app.select(d);
		this.app.dots.add(d);
	} else {
		prev = this.app.select(d);
	}

	// add line
	if (prev instanceof Dot && d instanceof Dot && prev != d) {
		console.log("add line");
		this.app.lines.add(prev, d);
	}
}

function LineMode(app) {
	this.app = app;
	this.name = 'line';
}
LineMode.prototype = Object.create(Mode.prototype);


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

function LineView(app, lines) {
	this.app = app;
	this.lines = lines;

	this.view = app.canvas.append("svg:g").attr("id", "lines");
}
LineView.prototype = {
	update: function() {
		var s = this.view.selectAll("line")
			.data(this.lines.list);
		s.enter()
			.append("line")
			.call(this.app.drag);
		s.exit().remove();
		s
			.classed("selected", function(d) { return d.isSelected; })
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
}
Dot.prototype = {
	del: function() {
		this.container.del(this);
	}
};

function LineList(dots) {
	this.list = [];
	this.id2line = {};

	this.dispatch = d3.dispatch("change");
	d3.rebind(this, this.dispatch, "on");

	var self = this;
	dots.on("change.lines", function(e) { self.onDotsChange(e); });
}
LineList.prototype = {
	add: function(d1, d2) {
		var id = Line.getId(d1, d2);
		if (id in this.id2line) {
			return null;
		}

		var line = new Line(d1, d2, this);
		this.list.push(line);
		this.id2line[line.id] = line;

		this.dispatch.change({added: line, deleted: null});

		return line;
	},

	del: function(line) {
		var index = this.list.indexOf(line);
		if (index >= 0) {
			this.list.splice(index, 1);
			this.dispatch.change({ added: null, deleted: line });
		}
	},

	onDotsChange: function(e) {
		var d = e.deleted;
		if (!d) {
			return;
		}

		for (var i = 0; i < this.list.length; i++) {
			var line = this.list[i];
			if (line.d1 == d || line.d2 == d) {
				line.del();
				i--;
			}
		}
	}
};

function Line(d1, d2, container) {
	if (d1 == d2) {
		throw new Error("same line is specified");
	}

	// swap
	if (d1.id > d2.id) {
		var tmp = d1;
		d1 = d2;
		d2 = tmp;
	}

	this.d1 = d1;
	this.d2 = d2;
	this.container = container;
	this.id = d1.id + "," + d2.id;
};
Line.getId = function(d1, d2) {
	return new Line(d1, d2, null).id;
}
Line.prototype = {
	del: function() {
		this.container.del(this);
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
