// TODO: Just return DOM object, do not append
// TODO: size settings
make_bar_graph = function(elem_id, graph){	
	clear_elem(elem_id);
	
	// set the dimensions and margins of the graph
	var margin = graph.margin,
		width = graph.size.width - margin.left - margin.right,
		height = graph.size.height - margin.top - margin.bottom;
	
	// set the ranges
	var x = d3.scaleBand()
		.range([0, width])
		.padding(0.1);
	var y = d3.scaleLinear()
		.range([height, 0]);

	// append the svg object to the body of the page
	// append a 'group' element to 'svg'
	// moves the 'group' element to the top left margin
	var svg = d3.select(elem_id).append("svg")
		.attr("width", width + margin.left + margin.right)
		.attr("height", height + margin.top + margin.bottom)
		.append("g")
		.attr("transform", "translate(" + margin.left + "," + margin.top + ")");
	
	// get the data
	var file = graph.source;
	console.log("file: " + graph.source);
	d3.csv(file, function(error, data) {
		if (error) throw error;

		// format the data
		data.forEach(function(d) {
			d.count = +d.count;
		});
	
		// Scale the range of the data in the domains
		x.domain(data.map(function(d) { return d.name; }));
		y.domain([0, d3.max(data, function(d) { return d.count; })]);

		// append the rectangles for the bar chart
		svg.selectAll(".bar")
			.data(data)
			.enter().append("rect")
			.attr("class", "bar")
			.attr("x", function(d) { return x(d.name); })
			.attr("width", x.bandwidth())
			.attr("y", function(d) { return y(d.count); })
			.attr("height", function(d) { return height - y(d.count);})
			.on("mouseover", function(d, i){graph.mouseover(data, d, i)})
			.on("mousedown", function(d, i){graph.mousedown(data, d, i)})
		;

		// add the x Axis
		svg.append("g")
		.attr("transform", "translate(0," + height + ")")
		.call(d3.axisBottom(x));
	
		// add the y Axis
		svg.append("g")
		.call(d3.axisLeft(y));	
	});
}