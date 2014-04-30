function ModeView(app, modes) {
	this.app = app;
	this.dispatch = d3.dispatch("change");
	d3.rebind(this, this.dispatch, "on");

	var lastMode = modes.filter(function(m) { return m.name == localStorage.mode; });
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

		localStorage.mode = mode.name;
	}
};

function DotView(app) {
	this.app = app;

	this.view = app.canvas.append("svg:g").attr("id", "dots");
}
DotView.prototype = {
	update: function() {
		var dots;
		if (this.app.modeView.currentMode.name == 'polygon') {
			var p = this.app.selectedItem;
			if (p instanceof(Polygon)) {
				dots = p.dots;
			} else {
				dots = [];
			}
		} else {
			dots = this.app.polygons.getDots();
		}

		var s = this.view.selectAll("circle")
			.data(dots);
		s.enter()
			.append("circle")
			.call(this.app.drag);
		s.exit().remove();
		s
			.classed("selected", function(d) { return d.isSelected; })
			.classed("can_drop", function(d) { return d.canDrop; })
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
		var curModeName = this.app.modeView.currentMode.name;
		if (curModeName == "polygon") {
			this.updatePolygonMode();
		} else if (curModeName == "point") {
			this.updatePointMode();
		}
	},

	updatePointMode: function() {
		// delete all polygon
		this.view.selectAll("polygon").data([]).exit().remove();
	},

	updatePolygonMode: function() {
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
		var curModeName = this.app.modeView.currentMode.name;
		if (curModeName == "polygon") {
			this.updatePolygonMode();
		} else if (curModeName == "point") {
			this.updatePointMode();
		}
	},

	updatePointMode: function() {
		var s = this.view.selectAll("line.outer")
			.data(this.polygons.getOuterLines());
		s.enter()
			.append("line")
			.classed("outer", true)
			.call(this.app.drag);
		s.exit().remove();
		s
			.attr("x1", function(d) { return d.d1.x; })
			.attr("y1", function(d) { return d.d1.y; })
			.attr("x2", function(d) { return d.d2.x; })
			.attr("y2", function(d) { return d.d2.y; })
			.attr("stroke-width", 2 / this.app.zoom.scale);
	},

	updatePolygonMode: function() {
		if (!(this.app.selectedItem instanceof Polygon)) {
			this.view.selectAll("line")
				.data([]).exit().remove();
			return;
		}

		var polygon = this.app.selectedItem;
		var s = this.view.selectAll("line.outer")
			.data(polygon.lines);
		s.enter().append("line").classed("outer", true);
		s.exit().remove();
		s
			.attr("x1", function(d) { return d.d1.x; })
			.attr("y1", function(d) { return d.d1.y; })
			.attr("x2", function(d) { return d.d2.x; })
			.attr("y2", function(d) { return d.d2.y; })
			.attr("stroke-width", 2 / this.app.zoom.scale);

		s = this.view.selectAll("line.inner")
			.data(polygon.innerLines);
		s.enter().append("line").classed("inner", true);
		s.exit().remove();
		s
			.attr("x1", function(d) { return d.d1.x; })
			.attr("y1", function(d) { return d.d1.y; })
			.attr("x2", function(d) { return d.d2.x; })
			.attr("y2", function(d) { return d.d2.y; })
			.attr("stroke-width", 2 / this.app.zoom.scale);
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
		this.scaleChange({oldScale: old, newScale: this.scale});
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
