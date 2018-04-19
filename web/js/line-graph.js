make_line_graph = function(elem_id, graph){
	clear_elem(elem_id);
	// set the dimensions and margins of the graph
	var margin = graph.margin,
		width = graph.size.width - margin.left - margin.right,
		height = graph.size.height - margin.top - margin.bottom;
	
	// parse the date / time
	var parseTime = d3.timeParse("%d-%b-%Y");
	
	// set the ranges
	var x = d3.scaleTime().range([0, width]);
	var y = d3.scaleLinear().range([height, 0]);
	
	var x_fun = function(d) { return x(d.date); } 

	// define the line
	var main_line = d3.line()
			.x(x_fun)
			.y(function(d) { return y(d.value); })
			.curve(d3.curveLinear);
	// define moving average line for 7 days
	var average7_line = d3.line()
			.x(x_fun)
			.y(function(d) { return y(d.avg7); })
			.curve(d3.curveCardinal);	
	// define moving average line for 30 days			
	var average30_line = d3.line()
			.x(x_fun)
			.y(function(d) { return y(d.avg30); })
			.curve(d3.curveBasis);	

	// append the svg obgect to the body of the page
	// appends a 'group' element to 'svg'
	// moves the 'group' element to the top left margin
	var svg = d3.select(elem_id).append("svg")
	.attr("width", width + margin.left + margin.right)
	.attr("height", height + margin.top + margin.bottom)
	.append("g")
	.attr("transform",
			"translate(" + margin.left + "," + margin.top + ")");
	
	// Get the data
	var file = graph.source;
	console.log("file: " + graph.source);	
	d3.csv(file, function(error, data) {
		if (error) throw error;
		
		// format the data
		data.forEach(function(d) {
			d.date = parseTime(d.date);
			d.value = +d.value;
	});
	
	// Scale the range of the data
	x.domain(d3.extent(data, function(d) { return d.date; }));
	y.domain([0, d3.max(data, function(d) { return d.value; })]);

	var draw_line = function(line){
		svg.append("path")   
		.data([data])
		.attr("class", "line")
		.style("stroke", line.stroke)
		.style("stroke-width", line.width)
		.attr("d", line.data);	
	}

	// Add paths
	if (settings.main_line){
		draw_line({stroke: "rgb(170,196,158)", width: "1px", data: main_line});
	}
	if (settings.d7_line){
		draw_line({stroke: "rgb(85,148,79)", width: "2px", data: average7_line});
	}
	if (settings.d30_line){
		draw_line({stroke: "rgb(0,100,0)", width: "3px", data: average30_line});	
	}

	// Add the X Axis
	svg.append("g")
		.attr("transform", "translate(0," + height + ")")
		.call(d3.axisBottom(x));
	
	// Add the Y Axis
	svg.append("g")
		.call(d3.axisLeft(y));	
	});
}

movingAvg = function(n) {
	return function (points) {
		console.log(typeof points);
		console.log(points);
		points = points.map(function(each, index, array) {
			var to = index + n - 1;
			var subSeq, sum;
			if (to < points.length) {
				subSeq = array.slice(index, to + 1);
				sum = subSeq.reduce(function(a,b) { return [a[0] + b[0], a[1] + b[1]]; });
				return sum.map(function(each) { return each / n; });
			}
			return undefined;
		});
		points = points.filter(function(each) { return typeof each !== 'undefined' });
		// Transform the points into a basis line
		pathDesc = d3.svg.line().curve("basis")(points);
		// Remove the extra "M"
		return pathDesc.slice(1, pathDesc.length);
	}
}
