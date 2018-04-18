console.log("%main.js");

rooms = null;
users = null;

// load room names
load_rooms = function (){
	d3.csv("data/room-list.csv", function(error, data) {
		if (error) throw error;
		console.log("loading rooms");
		rooms = {}; 
		data.forEach(function(d) {
			rooms[d["name"]] = d["file"];
		});
		// call next function, because F*ck JS!@#@$$%!!!
		load_users(); 
	});
}

// JS is stupid evil thing
load_users = function (){
	d3.csv("data/user-list.csv", function(error, data) {
		if (error) throw error;
		console.log("loading users");
		users = {}; 
		data.forEach(function(d) {
			users[d["name"]] = d["id"];
		});
		console.log(rooms);
		// call next function, because callback hell reeeaaalllyyyy rulz!!!
		run_main();
	});
}

clear_elem = function(name){
	d3.select(name).html("");
}


graph = {
	margin: {top: 20, right: 20, bottom: 30, left: 70},
	size: {width: 1100, height: 500},
};
msg_count_graph = Object.create(graph);
msg_count_graph.source = "data/msg-count.csv";
msg_count_graph.active = true;
msg_count_graph.mouseover = function(data, d, i){
	var room_graph = Object.create(graph);
	var name = data[i].name;
	d3.select("#room-title").text("Activity in room " + name);
	room_graph.source = "data/rooms/" + rooms[name] + ".csv";
	settings.room_graph = room_graph;
	make_line_graph("#line-graph", room_graph);
};

top20_graph = Object.create(graph);
top20_graph.source = "data/top20-messages.csv";
top20_graph.active = false;
top20_graph.mouseover = function(data, d, i){
	console.log(data[i].name);
	select_user(data[i].name, show_user_info);
};

// just to show something on load. rename or rework
test_graph = Object.create(graph);
test_graph.source = "data/rooms/5565a1d415522ed4b3e10094.csv";

run_main = function(){
	settings.room_graph = test_graph;
	make_bar_graph("#rooms-graph", msg_count_graph);
	make_bar_graph("#users-graph", top20_graph);
	make_line_graph("#line-graph",test_graph);

	populate_user_list();
}

init = function(){
	// setting value in HTML doesn't seem to work, so let's do it from here
	document.getElementById("checkbox-main").checked = true;
	document.getElementById("checkbox-7-days").checked = true;
	document.getElementById("checkbox-30-days").checked = true;		
	
	// let's start callback hell, because who needs readable code
	load_rooms();
}

select_user = function(name, callback){
	var filename = "data/users/" + users[name] + ".json";
	console.log(filename);
	d3.json(filename, function(error, data) {
		if (error) throw error;
		// call next function, because F*ck JS!@#@$$%!!!
		callback(data);
	});
}

show_user_info = function(data){
	console.log("user info for " + data.name);
	console.log(data);
	d3.select("#user-name").text(data.name);
	d3.select("#user-joined").text(data.first);
	// _groups[0][0] is so great, I have no idea what it is
	// just some JS sh*t, f*ck that, f*ck this, f*ck everything JS
	let image = d3.select("#user-image")._groups[0][0];
	image.src = data.avatar;
	make_pie_graph(data.rooms, "#pie-graph");
	// some images are bigger, so set the size right
	image.width = 128;
	image.height = 128;
}

show_user_avatar = function(name){
	var filename = "data/users/" + users[name] + ".json";
	d3.json(filename, function(error, data) {
		if (error) throw error;
		var avatar = data.avatar;
		render_user(avatar);
	});
}

// this adds image, so is not `render`, i will fix it later
render_user = function(image){
	console.log("image is "+image);
	var users = d3.select("#user-list-img")
		.append("img").attr("src", image)
		.style("width","60px").style("height","60px");
}

show_all_users = function(){
	var keys = Object.keys(users); 
	keys.forEach(
		function(user){
			console.log(user);
			show_user_avatar(user);
		}
	)
}

// populate user list

populate_user_list = function(){
	let keys = Object.keys(users).sort(); 
	let user_list = document.getElementById("user-list");
	let click_fun = function(act){
		let name = act.target.innerText;
		user = users[name];
		console.log(name);
		select_user(name, show_user_info);
	};
	keys.forEach(
		function(user){
			console.log(users[user]);
			let elem = document.createElement("div");
			elem.className = "user-list-item";
			elem.innerText = user;
			elem.onclick = click_fun;
			user_list.appendChild(elem);
		}
	)	
}

// various settings

settings = {
	main_line: true,
	d7_line: true,
	d30_line: true,
	room_graph: null
}

toggle_activity = function(type){
	console.log("activity: " + type);
	let id = "checkbox-" + type;
	let elem = document.getElementById(id);
	console.log(elem.checked);
	switch (type){
		case "main":
			settings.main_line = elem.checked;
			break;
		case "7-days":
			settings.d7_line = elem.checked;
			break;
		case "30-days":
			settings.d30_line = elem.checked;
			break;
	}
	make_line_graph("#line-graph",settings.room_graph); // TODO: how to get data here?
}

// main code
init();
