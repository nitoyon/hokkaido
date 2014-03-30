function MapEditor(elm, json) {
	this.init(elm, json);
}
MapEditor.prototype = {
	dots: null,

	init: function(elm, json) {
		this.initModel();
		this.initElement(elm);
		this.initJson(json);
		this.initEvent();
	},

	initModel: function() {
		this.dots = [];
	},

	initElement: function(elm) {
		this.elm = elm;
		this.svg = d3.select(elm);
		this.canvas = this.svg.append("svg:g").attr("id", "canvas");
		this.mapContainer = this.canvas.append("svg:g").attr("id", "map_pathes");
		this.dotContainer = this.canvas.append("svg:g").attr("id", "dots");
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
				case 187: // +
					self.zoom.zoomUp();
					break;
				case 189: // -
					self.zoom.zoomDown();
					break;
			}
		});

		this.zoom = new MapZoom(this.svg, this.canvas);

		var dragging = false;
		this.drag = d3.behavior.drag()
			.on("dragstart", function(d) {
				dragging = false;
				// drag the most foreground draggable object
				d3.event.sourceEvent.stopPropagation();
			})
			.on("dragend", function(d, i) {
				console.log("dragend", dragging);
				if (!dragging) {
					self.onClick(d, i, this, d3.event.sourceEvent);
				}
			})
			.on("drag", function(d, i) { dragging = true; self.onDrag(d, i, this); });
		this.svg.call(this.drag);
		//this.svg.on("click", function() { self.onClick(null, null, null, d3.event); });
	},

	updateView: function() {
		this.dotContainer.selectAll("circle")
			.data(this.dots)
			.enter()
			.append("circle")
			.attr("cx", function(d) { return d.x; })
			.attr("cy", function(d) { return d.y; })
			.attr("r", 5)
			.call(this.drag);
	},

	onDrag: function(d, i, elm) {
		console.log(d, i, elm);
	},

	onClick: function(d, i, elm, event) {
		console.log(d);

		var p = this.zoom.clientToGlobal(event.offsetX, event.offsetY);
		this.dots.push(new Dot(p.x, p.y));
		this.updateView();
	}
};

function Dot(x, y) {
	this.x = x;
	this.y = y;
}

function MapZoom(elm, target) {
	this.elm = elm;
	this.target = target;

	var self = this;
	/*var zoomMoved;
	this.zoom = d3.behavior.zoom()
		.scale(1)
		.scaleExtent([.1, 10])
		.on("zoom", function() { zoomMoved = true; self.onZoomed(d3.event); })
		.on("zoomstart", function() { zoomMoved = false; })
		.on("zoomend", function() {
			if (!zoomMoved && onClick) {
				onClick(d3.event.sourceEvent);
			}
		});
	this.elm.call(this.zoom);*/
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
		if (isNaN(val) || val < 1) {
			return;
		}

		this.x = (this.x - 300) / this.scale * val + 300;
		this.y = (this.y - 300) / this.scale * val + 300;
		this.scale = val;

		//this.zoom.translate([xx, yy]);
		//this.zoom.scale(val);
		this.triggerEvent();
	},

	clientToGlobal: function(x, y) {
		return {
			x: (x - this.x) / this.scale,
			y: (y - this.y) / this.scale
		};
	},

	// apply current zoom setting to view & property
	// onZoomed -> update
	triggerEvent: function() {
		//this.zoom.event(this.elm);
		this.update();
	},

	update: function() {
		this.target.attr("transform",
			"translate(" + this.x + "," + this.y + ") " +
			"scale(" + this.scale + ")");
	},

	onZoomed: function(event) {
		this.x = event.translate[0];
		this.y = event.translate[1];
		this.scale = event.scale;
		console.log("x = %d, y = %d, scale = %d", this.x, this.y, this.scale);
		this.update();
	}
};

var map;
d3.json("out.geojson", function(json) {
  map = new MapEditor(document.getElementById("map"), json);
});
