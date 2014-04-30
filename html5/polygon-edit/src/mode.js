function Mode(name, app) {
	this.name = name;
	this.app = app;
}
Mode.prototype = {
	onClick: function(d, i) {
		var prev = this.app.unselect();
		if (d !== null) {
			this.app.select(d);
		}
	},

	onDragStart: function(d, i) {},

	onDrag: function(d, i) {
		var event = d3.event;
		var p = this.app.zoom.clientToWorld(event.x, event.y);
		if (d === undefined) {
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
		this.app.polygons.closeAddingPolygon();
		Mode.prototype.onClick.call(this, d, i);
		return;
	}

	var p;
	if (d === undefined) {
		// click none -> add dot
		p = this.app.zoom.clientToWorld(event.offsetX, event.offsetY);
		d = new Dot(p.x, p.y);
		this.app.select(d);

		this.app.polygons.createAddingPolygon();
		this.app.polygons.addingPolygon.add(d);
	} else if (d instanceof Dot) {
		// click dot -> connect
		var create = this.app.polygons.createAddingPolygon();
		var index = this.app.polygons.addingPolygon.add(d);

		// click first dot -> close
		if (index === 0 && !create) {
			this.app.polygons.closeAddingPolygon();
		}
		this.app.select(d);
	} else if (d instanceof Line) {
		// click line -> add dot
		p = this.app.zoom.clientToWorld(event.offsetX, event.offsetY);
		var dot = new Dot(p.x, p.y);
		this.app.polygons.splitLine(d, dot);
	}
};

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

	var hover = d3.select(d3.event.sourceEvent.target).datum();
	var src;
	if (hover instanceof Dot) {
		src = hover;
	} else {
		src = d3.event;
	}

	var p = this.app.selectedItem;
	p.draggingLine.d2.x = src.x;
	p.draggingLine.d2.y = src.y;
};

PolygonMode.prototype.onDragEnd = function(d, i) {
	if (!(d instanceof Dot)) {
		return;
	}

	var p = this.app.selectedItem;
	p.draggingLine = null;
	var hover = d3.select(d3.event.sourceEvent.target).datum();
	if (hover instanceof Dot) {
		p.addInnerLine(d, hover);
	}
};
