extends Spatial

var positions = {}
var name_position = {}
var num_of_stations: int

func _ready():
	randomize()
#	num_of_stations = $Stations.get_child_count()-1

#	for i in range(16):
#		print(get_position_to_spawn())

func get_position_to_spawn(station = null, preferred_dir = 0):
	if not positions.size():
		_generate_positions()
#	print(positions)
	var position
	if station:
		position = name_position[station]
	else:
		position = _pick_station(num_of_stations)
	if positions[position].used:
		push_error("Couldn't find a station to spawn, bailing out!")
		return Vector3(INF, INF, INF)

	var place = _choose_pos(position, preferred_dir)
	var idx = num_of_stations
	while is_vec_inf(place) and idx > 1:
		position = _pick_station(position)
		if positions[position].used:
			push_error("Couldn't find a station to spawn, bailing out!")
			return Vector3(INF, INF, INF)
		place = _choose_pos(position, preferred_dir)
		idx -= 1
	return place


func _choose_place(random_pos):
	var avail_pos = positions[random_pos].avail_pos
	var choosen_pos = []
	var choosen_rot = []
	for position in avail_pos:
		if avail_pos[position].avail:
			var avail_rot = avail_pos[position].avail_rot
			for rot in avail_rot:
				if avail_rot[rot]:
					avail_rot[rot] = false
					return Vector3(position * -rot, rot, random_pos.z + (45 * rot))
				choosen_rot.append(rot)
			if choosen_rot.size() == avail_rot.size():
				avail_pos[position].avail = false
		choosen_pos.append(position)
	if choosen_pos.size() == avail_pos.size():
		positions[random_pos].used = true
	return Vector3(INF, INF, INF)

func _choose_rot(pos, avail_pos, preferred_dir = 0) -> int:
	var avail_rot = avail_pos[pos].avail_rot
	var rot
	if preferred_dir:
		rot = preferred_dir
		print("preferring!", rot)
	else:
		rot = avail_rot.keys()[randi() % avail_rot.size()]
	var idx = 20
	while not avail_rot[rot] and idx > 1:
		rot = avail_rot.keys()[randi() % avail_rot.size()]
		idx -= 1
	if not avail_rot[rot]:
		avail_pos[pos].avail = false
		return 0
	return rot

func _choose_pos(station, preferred_dir = 0) -> Vector3:
	var avail_pos = positions[station].avail_pos
	var pos = avail_pos.keys()[randi() % avail_pos.size()]
	var idx = 20
	while not avail_pos[pos].avail and idx > 1:
		pos = avail_pos.keys()[randi() % avail_pos.size()]
		idx -= 1
	var rot = _choose_rot(pos, avail_pos, preferred_dir)
	if rot in [-1, 1]:
		return _construct_position(station, pos, rot)
	if not avail_pos[pos].avail:
		positions[station].used = true
	return Vector3(INF, INF, INF)
#					prints(position * -rot, rot, random_position.z, random_position.z+(45 * rot))

func _construct_position(station, pos, rot):
	prints(pos, rot)
	return Vector3(pos * -rot, rot, station.z + (45 * rot))


func _generate_positions():
	var route = get_tree().get_meta("route_name", null)
	if route:
		print("route selected")
		var stations = load(route).instance()
		$Route.add_child(stations)
	for child in $Route.get_child(0).get_stations():
		positions[child.global_transform.origin] = {
			"used": false,
			"avail_pos": {
				-3.125: {
					"avail": true,
					"avail_rot": {
						+1: true,
						-1: true
					}
				},
#				2.5: {
#					"avail": true,
#					"avail_rot": {
#						+1: true,
##						-1: true
#					}
#				},
				
#				-7.5: {
#					"avail": true,
#					"avail_rot": {
#						+1: true,
#						-1: true
#					}
#				},
			}
		}
		name_position[child.name] = child.global_transform.origin
		

func is_vec_inf(vec):
	return is_inf(vec.x) and is_inf(vec.y) and is_inf(vec.z)

func _pick_station(trials = 20):
	var random_position = positions.keys()[randi() % positions.size()]
	var jdx = trials
	while positions[random_position].used and jdx > 1:
		random_position = positions.keys()[randi() % positions.size()]
		jdx -= 1
	return random_position

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

func get_route_max_speed():
	return $Route.get_child(0).max_speed
