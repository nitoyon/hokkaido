var pointsXY = [122.502,57.912,114.462,54.182,109.50874999999999,50.19375,106.194,47.578,102.715,45.082,99.861125,42.558499999999995,96.893,39.083,94.196,36.21,92.155,34.193,89.45125,30.539,87.768,27.804499999999997,86.239375,25.057375,84.2645,21.23225,81.669,18.417,78.77,14.888,76.35,11.913,73.38900000000001,7.9555,69.45325,4.158875,66.814875,1.51025,63.571,4.402,58.8576875,5.0275,57.3335,8.73175,55.695,12.565999999999999,56.087,16.901,60.446,27.967,61.933,36.058,61.49875,42.5925,59.895375,48.9398125,58.140875,53.478375,57.974,58.592,58.226,64.54,56.8018125,69.68325,52.442,72.844875,49.1525,75.40350000000001,48.295,78.832,49.556,82.9025,49.19,85.9525,51.119,90.804,50.142250000000004,95.6435,47.586,98.976375,45.359125,100.819125,42.2575,101.69149999999999,39.494375000000005,100.576375,37.04775,98.607875,32.565375,99.3635,29.4265,97.76599999999999,26.16825,95.75625,21.354984375,93.59771875,17.909375,95.673875,17.465,98.9855,19.6325,101.733,22.317625,105.633125,22.1785,109.207,19.9045,110.90799999999999,18.2105,113.4795,16.5715,116.09525,12.891874999999999,117.03718749999999,9.475999999999999,119.884,6.5645,121.0695,2.758375,123.118,2.279,127.8245,2.519,131.945,1.108,134.83775,0.328,138.46075000000002,2.4610000000000003,141.003,4.713,144.321,8.053,145.7825,10.8065,150.1655,10.883,155.707,9.622,158.51075,7.6495,162.5565,6.7925,167.887,8.116,172.071,10.587,173.558,13.183,174.742,15.035499999999999,172.0515,18.502000000000002,169.8275,20.316499999999998,167.6205,20.9345,163.0465,24.21675,161.4145,27.095750000000002,158.00574999999998,30.228875000000002,159.304125,33.119,159.821,37.079375,161.21300000000002,40.49875,159.6535,42.9435,157.69650000000001,41.525,155.3465,38.3625,154.0225,36.176249999999996,152.3785,34.2675,149.8515,31.2365,146.34699999999998,28.29975,144.39300000000003,24.576,144.88400000000001,21.8415,143.15699999999998,18.9425,140.94549999999998,15.817,138.3305,17.165,131.614,21.526,125.589,24.3305,125.78450000000001,28.003249999999998,125.48225,31.135375000000003,127.87584375,33.6545,130.7695,35.539,134.135,37.9388125,136.075875,42.646,131.8395,50.435,125.991,57.668,123.647,62.3686875,124.52362500000001,66.432,126.81825,68.8135,129.01075,71.555,130.051,74.731,131.286,78.524,135.2175,81.52250000000001,137.14550000000003,85.06524999999999,139.26325,88.6445,141.12900000000002,93.07499999999999,143.284,98.488,145.4015,102.256,147.897,105.44512499999999,150.7061875,108.77825,146.20925,109.38900000000001,142.0875,108.923,138.71,114.733,126.877,122.193,118.735,128.596,112.786,133.4865,109.80625,140.5885625,108.7851875,145.29,110.48675,150.388,110.72,153.30575,110.33525,153.424,106.687,156.81644531249998,107.45056249999999,160.95625,108.041625,163.4635,105.18675,165.15875,102.62825000000001,168.984,101.61325,173.338,100.586,176.42753125000002,100.250125,177.93625,97.3545625,180.0025625,95.27353124999999,183.343546875,93.512828125,180.62650000000002,92.166,178.590125,94.06575,176.28078125000002,96.9585625,172.4978671875,96.750765625,169.4563046875,94.0518671875,168.731,89.898,168.1245,86.5205,168.8187734375,83.2359296875,165.40050000000002,81.2385,163.837,78.40299999999999,163.0574375,74.4030625,163.8685,70.457,165.124,67.79775000000001,167.401625,63.994625,169.1695,59.877250000000004,171.23575,56.204125,170.099390625,53.152984375,167.69400000000002,55.3155,165.6495,58.255375,162.01024999999998,61.35925,158.97975000000002,64.13825,155.697,67.655,149.597,69.734,139.19675,66.549,136.49093749999997,63.4271875,133.58100000000002,65.299,134.465625,62.356,128.54137500000002,61.182312499999995,125.161,61.642250000000004,122.3081875,61.1596875,121.2926875,58.255624999999995];

function Point(x, y, i) {
	this.x = x;
	this.y = y;
	this.index = i;
}
Point.prototype = {
};

function SeparateLine(from, to) {
	this.from = from;
	this.to = to;
}
SeparateLine.prototype = {
};


Point.parseFlatArray = function(a) {
	var ret = [];
	for (var i = 0; i < pointsXY.length / 2; i++) {
		ret.push(new Point(a[i * 2], a[i * 2 + 1], i / 2));
	}
	return ret;
}

function Canvas(svg, points) {
	this.svg = svg;
	this.points = points;
	this.groups = [this.points.slice()];
	this.lines = [];
}

Canvas.prototype = {
	init: function() {
		var self = this;

		this.view = {
			zoom: 3,
			x: 10,
			y: 10
		};

		this.container = this.svg.append('g')
			.attr("transform", "scale(3) translate(10 10)")
			.on("click", function() { self.onClick(); });

		this.container
			.append("polygon").attr("class", "shape");
		this.lineContainer = this.container.append("g");
		this.hullContainer = this.container.append('g')
			.attr("class", "hull");
		this.dragLine = this.container.append('svg:path')
			.attr("class", "dragline hidden")
			.attr('d', 'M0,0L0,0');
		this.pointContainer = this.container.append("g");

		this.drag = d3.behavior.drag()
			.on("dragstart", function(d, i) { self.onPointDragStart(this, d, i); })
			.on("drag", function(d, i) { self.onPointDrag(this, d, i); })
			.on('dragend', function(d, i) { self.onPointDragEnd(this, d, i); });
	
		d3.select(document).on("keydown", function() { self.onKeyDown(); });
	},

	onClick: function() {
		if (d3.event.target.tagName == "line") {
			d3.select(d3.event.target).classed("selected", true);
		} else {
			d3.select(".selected").classed("selected", false);
		}
	},

	onKeyDown: function() {
		switch (d3.event.keyCode) {
			case 46: // delete
				if (!d3.select(".selected").empty()) {
					this.removeLine(d3.select(".selected").datum());
					this.updateShape();
				}
				break;
			case 34: // page down
				this.view.zoom--;
				break;
			case 33: // page up
				this.view.zoom++;
				break;
			case 39: // right
				this.view.x -= 10;
				break;
			case 38: // up
				this.view.y += 10;
				break;
			case 40: // down
				this.view.y -= 10;
				break;
			case 37: // left
				this.view.x += 10;
				break;
			default:
				return;
		}

		this.container.attr("transform", "scale(" + this.view.zoom + ") translate("
			+ this.view.x + "," + this.view.y + ")");
	},

	addLine: function(from, to) {
		for (var i = 0; i < this.groups.length; i++) {
			var g = this.groups[i];
			
			// check whether we can divide the group
			var s = g.indexOf(from);
			var e = g.indexOf(to);
			if (s == -1 || e == -1 || s == e ||
				Math.abs(s - e) == 1 || Math.abs(s - e) == g.lenth - 1) {
				continue;
			}

			// swap
			if (s > e) {
				var tmp = e;
				e = s; s = tmp;
			}

			console.log(s, e);
			var g2 = g.splice(s, e - s + 1, g[s], g[e]);
			this.groups.push(g2);

			this.lines.push(new SeparateLine(from, to));
			this.updateShape();
			return;
		}
	},

	removeLine: function(line) {
		var groups = [];
		for (var i = 0; i < this.groups.length; i++) {
			var g = this.groups[i];
			var s = g.indexOf(line.from);
			var e = g.indexOf(line.to);
			if (s != -1 && g != -1) {
				groups.push(g);
			}
		}

		if (groups.length != 2) {
			alert("cannot remove");
		}
		Array.prototype.push.apply(groups[0], groups[1]);
		groups[0].splice(groups[0].indexOf(line.from), 1);
		groups[0].splice(groups[0].indexOf(line.to), 1);
		groups[0].sort(function(a, b) { return a.index - b.index; });
		this.groups.splice(this.groups.indexOf(groups[1]), 1);
		this.lines.splice(this.lines.indexOf(line), 1);
	},

	updateShape: function() {
		this.container.select("polygon.shape")
			.attr("points", this.points.map(function(p) { return p.x + ',' + p.y; }).join(' '));

		var self = this;
		var p = this.pointContainer.selectAll("circle")
			.data(this.points);
		p.enter().append("circle");
		p.exit().remove();
		p
			.attr("class", "point")
			.attr("cx", function(d) { return d.x; })
			.attr("cy", function(d) { return d.y; })
			.attr("r", 1.1)
			.on('mouseover', function(d, i) { self.onPointMouseOver(this, d, i); })
			.on('mouseout', function(d, i) { self.onPointMouseOut(this, d, i); })
			.call(this.drag);
	
		var lines = this.lineContainer.selectAll("line")
			.data(this.lines);
		lines.enter().append("line");
		lines.exit().remove();
		lines
			.attr("x1", function(d) { return d.from.x; })
			.attr("y1", function(d) { return d.from.y; })
			.attr("x2", function(d) { return d.to.x; })
			.attr("y2", function(d) { return d.to.y; });

		var hulls = this.groups.map(function(g) {
			return d3.geom.hull(g.map(function(p) { return [p.x, p.y]; }));
		});

		var h = this.hullContainer.selectAll("polygon")
			.data(hulls);
		h.enter().append("polygon");
		h.exit().remove();
		h.attr("points", function(d) { return d.join(" ")});
	},

	onPointMouseOver: function(elm, d, i) {
		if (!this.dragging) { return; }
		this.dropTarget = { elm: elm, p: d };
		d3.select(elm).classed('hover', true);
	},

	onPointMouseOut: function(elm, d, i) {
		if (this.dropTarget) {
			this.dropTarget = null;
			d3.select(elm).classed('hover', false);
		}
	},

	onPointDragStart: function(elm, d, i) {
		this.dragging = true;
		this.dragStart = { elm: elm, p: d };
	},

	onPointDrag: function(elm, d, i) {
		this.dragLine.classed('hidden', false);
		d3.select(this.dragStart.elm).classed('hover', true);

		if (this.dropTarget) {
			this.dragLine.attr('d', 'M' + d.x + ',' + d.y + 'L' + this.dropTarget.p.x + ',' + this.dropTarget.p.y);
		} else {
			this.dragLine.attr('d', 'M' + d.x + ',' + d.y + 'L' + d3.event.x + ',' + d3.event.y);
		}
	},

	onPointDragEnd: function(elm, d, i) {
		d3.select(this.dragStart.elm).classed('hover', false);
		if (this.dropTarget) {
			d3.select(this.dropTarget.elm).classed('hover', false);
		}

		this.dragLine.classed('hidden', true);
		this.dragging = false;

		if (this.dropTarget) {
			this.addLine(this.dragStart.p, this.dropTarget.p);
		}

		this.dragStart = this.dropTarget = this.dropTarget = null;
	}
};

var canvas;
(function() {
	var points = Point.parseFlatArray(pointsXY);
	canvas = new Canvas(d3.select("body").append("svg"), points);
	canvas.init();
	canvas.updateShape();
})();
/*
hullGroup.append("polygon").attr("points", hull.join(" "))
	.attr("fill", "transparent");
hullGroup.selectAll("circle").data(hull).enter().append("circle")
	.attr("cx", function(d) { return d[0]; })
	.attr("cy", function(d) { return d[1]; })
	.attr("r", 2);

var shape = svg.append("g")
	.attr("class", "shape")
	.attr("stroke", "skyblue")
	.attr("stroke-width", 1)
	.attr("fill", "skyblue");
shape.append("polygon").attr("points", points.join(" "))
	.attr("fill", "lightgreen");

// line displayed when dragging new nodes
var drag_line = shape.append('svg:path')
  .attr("stroke", "green")
  .attr("stroke-width", .5)
  .attr('d', 'M0,0L0,0');
var dragging = false;
var drop_target = null;

var drag = d3.behavior.drag()
    .on("drag", function(d,i) {
    	dragging = true;
    	if (drop_target) {
    		drag_line.attr('d', 'M' + d.join(',') + 'L' + drop_target.join(','));
    	} else {
    		drag_line.attr('d', 'M' + d.join(',') + 'L' + d3.event.x + ',' + d3.event.y);
    	}
    })
    .on("dragend", function(d, i){
    	if (drop_target) {
    		
    	}
    	
    	dragging = false;
 		drop_target = null;
    	drag_line.attr("d", "M0,0L0,0");
    });

shape.selectAll("circle").data(points).enter().append("circle")
	.attr("cx", function(d) { return d[0]; })
	.attr("cy", function(d) { return d[1]; })
	.attr("r", 1)
	.style("cursor", "hand")
	.on("mouseover", function(d) {
		if (!dragging) { return; }
 		drop_target = d;
		d3.select(this).attr("fill", "red").attr("stroke", "red");
	})
	.on("mouseout", function() {
 		drop_target = null;
		d3.select(this).attr("fill", "skyblue").attr("stroke", "skyblue");
	})
	.call(drag);

console.log("hoge");*/
