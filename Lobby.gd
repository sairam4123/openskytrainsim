extends Control

enum Direction {
	FORWARD = 1,
	BACKWARD = -1,
	RANDOM = 0
}
var route_id_mapper = {
	
}
# route_name: route_file_name

func _ready():
	randomize()
	var routes = get_dir_contents("res://assets/routes/")
	for route in routes[0]:
		route = str(route) as String
		if route.ends_with(".tscn"):
			var route_loaded = load(route).instance()
			$"%RouteName".add_item(route_loaded.route_name)
			route_id_mapper[route_loaded.route_name] = route
			RouteServer.register_route(route_loaded.route_name, route_loaded)
			


func _on_Button_pressed():
	var peer = NetworkedMultiplayerENet.new()
	var ip_with_port = $"%IP".text.split(":")	
	peer.create_server(int(ip_with_port[1]))
	get_tree().network_peer = peer
	var preferred_dir = $"%PreferredDirection".text.to_upper()
	get_tree().set_meta("player_name", $"%Name".text)
	get_tree().set_meta("route_name", route_id_mapper[$"%RouteName".text])
	get_tree().set_meta("station_name", $"%StationName".text)
	get_tree().set_meta("preferred_dir", Direction[preferred_dir])
	RouteServer.routes.clear()
	get_tree().change_scene("res://TrainNewTest.tscn")

func _on_Button2_pressed():
	var peer = NetworkedMultiplayerENet.new()
	var ip_with_port = $"%IP".text.split(":")
	print(peer.create_client(ip_with_port[0], int(ip_with_port[1])))
	get_tree().network_peer = peer
	var preferred_dir = $"%PreferredDirection".text.to_upper()
	get_tree().set_meta("player_name", $"%Name".text)
	get_tree().set_meta("station_name", $"%StationName".text)
	get_tree().set_meta("preferred_dir", Direction[preferred_dir])
	RouteServer.routes.clear()
	get_tree().change_scene("res://TrainNewTest.tscn")

# taken from https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
func get_dir_contents(rootPath: String) -> Array:
	var files = []
	var directories = []
	var dir = Directory.new()

	if dir.open(rootPath) == OK:
		dir.list_dir_begin(true, false)
		_add_dir_contents(dir, files, directories)
	else:
		push_error("An error occurred when trying to access the path.")

	return [files, directories]

func _add_dir_contents(dir: Directory, files: Array, directories: Array):
	var file_name = dir.get_next()

	while (file_name != ""):
		var path = dir.get_current_dir() + "/" + file_name

		if dir.current_is_dir():
#			print("Found directory: %s" % path)
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			directories.append(path)
			_add_dir_contents(subDir, files, directories)
		else:
#			print("Found file: %s" % path)
			files.append(path)

		file_name = dir.get_next()

	dir.list_dir_end()


func _on_RouteName_item_selected(index):
	var station_selector = $"%StationName"
	var route_selector = $"%RouteName" as OptionButton
	
	var route_name = route_selector.get_item_text(index)
	var route = RouteServer.get_route(route_name)
	
	if not route:
		station_selector.clear()
		station_selector.add_item("Random")
		set_disabled_buttons(true)
		return
	
	set_disabled_buttons(false)
	station_selector.clear()
	station_selector.add_item("Random")
	
	var station_name_station_map = {}
	for station in route.get_stations():
		if station.is_in_group("ignore_spawn") or not station.is_in_group("station"):
			continue
		station_name_station_map[station.name] = station
		station_selector.add_item(station.name)
	station_selector.set_meta("station_mapping", station_name_station_map)
	
	
func set_disabled_buttons(disabled: bool):
	var station_selector = $"%StationName"
	var host_button = $"%Host"
	var join_button = $"%Join"
	station_selector.disabled = disabled
	host_button.disabled = disabled
	join_button.disabled = disabled


func _on_StationName_item_selected(index):
	# Station selected!
	var station_selector = $"%StationName"
	var direction_selector = $"%PreferredDirection"
	
	var station_name = station_selector.get_item_text(index)
	var station_mapping = {}
	if station_selector.has_meta("station_mapping"):
		station_mapping = station_selector.get_meta("station_mapping")
	var station = station_mapping.get(station_name)
	if not station:
		direction_selector.clear()
		direction_selector.add_item("Random")
		direction_selector.disabled = true
		return

	direction_selector.clear()
	if station.is_in_group("terminal_station"):
		var idx = station.get_index()
		var prev_station = station.get_parent().get_child(idx-1)
		var next_station = station.get_parent().get_child(idx+1)
		if prev_station.is_in_group('buffer'):
			direction_selector.add_item("Backward")
		elif next_station.is_in_group("buffer"):
			direction_selector.add_item("Forward")
			
	else:
		direction_selector.add_item("Random")
		
		direction_selector.add_item("Forward")
		direction_selector.add_item("Backward")
	direction_selector.disabled = false
