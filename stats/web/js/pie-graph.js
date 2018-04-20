make_pie_graph = function(data, elem_id){
	clear_elem(elem_id);
	var keys = Object.keys(data);
	var values = Object.values(data);
	//FIXME: thanks to sorting, keys are in wrong order
	//values.sort(function(a, b){return a-b});
	//console.log("sorted:" + values);

	var total = values.reduce((a, b) => a + b, 0);
	var lower = [];
	var higher = [];
	values.forEach(element => {
		if (element > (total / 50)){ // 2%
			higher.push(element);
		} else {
			lower.push(element);
		}
	});
	higher.push(lower.reduce((a, b) => a + b, 0));
	console.log(higher);
	console.log(higher.length);
	var last = higher.length - 1;
	keys[last] = "other";
	values = higher;

// ------------------------	
	var width = 400,
		height = 400,
		radius = Math.min(width, height) / 2;

	var color = d3.scaleOrdinal()
		.range(["#98abc5", "#8a89a6", "#7b6888"]);

	var arc = d3.arc()
		.outerRadius(radius - 10)
		.innerRadius(0);

	var labelArc = d3.arc()
		.outerRadius(radius - 40)
		.innerRadius(radius - 40);

	var pie = d3.pie()
		.sort(null)
		.value(function(d) { return d; });

	var svg = d3.select(elem_id).append("svg")
		.attr("width", width)
		.attr("height", height)
	.append("g")
		.attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

	var g = svg.selectAll(".arc")
		.data(pie(values))
		.enter().append("g")
		.attr("class", "arc");

	g.append("path")
		.attr("d", arc)
		.style("fill", function(d) { return color(d.data); });

	g.append("text")
		.attr("transform", function(d) { return "translate(" + labelArc.centroid(d) + ")"; })
		.attr("dy", ".35em")
		.text(function(d) {console.log(keys[d.index]);return keys[d.index]});
}