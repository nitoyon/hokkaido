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
		this.polygons = new PolygonList();

		if (localStorage.polygon) {
			var data = JSON.parse(localStorage.polygon);
			this.polygons.deserialize(data);
		}
	},

	initElement: function(elm) {
		this.elm = elm;
		this.svg = d3.select(elm);
		this.canvas = this.svg.append("svg:g").attr("id", "canvas");
		this.mapContainer = this.canvas.append("svg:g").attr("id", "map_pathes");
		this.polygonView = new PolygonView(this, this.polygons);
		this.lineView = new LineView(this, this.polygons);
		this.dotView = new DotView(this);

		this.modeView = new ModeView(this, [new PointMode(this), new PolygonMode(this)]);

		var self = this;
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
	    .attr("fill", function(i) { return color(i.properties.ObjName); });
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
		if (localStorage.zoom) {
			this.zoom.deserialize(JSON.parse(localStorage.zoom));
			this.zoom.update();
		}

		var dragging = false, dragMoved = false;
		this.drag = d3.behavior.drag()
			.on("dragstart", function(d) {
				dragging = dragMoved = false;

				// drag the most foreground draggable object
				d3.event.sourceEvent.stopPropagation();
			})
			.on("dragend", function(d, i) {
				if (!dragMoved) {
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
				} else if (!dragMoved) {
					// trigger onDragStart on first move
					dragMoved = true;
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

		localStorage.polygon = JSON.stringify(this.polygons.serialize());
		localStorage.zoom = JSON.stringify(this.zoom.serialize());
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

		if (item) {
			this.selectedItem = item;
			item.isSelected = true;
		} else {
			this.selectedItem = null;
		}
		return prev;
	},

	unselect: function() {
		var prev = null;
		if (this.selectedItem !== null) {
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

var map;
d3.json("out.geojson", function(json) {
  map = new MapEditor(document.getElementById("map"), json);
});
