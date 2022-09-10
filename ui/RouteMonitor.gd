extends Panel


var train


var current_speed_limit

var tracking_stations = {}

var speed_limit_stack = []
func _ready():
	current_speed_limit = get_parent().get_parent().get_route_max_speed()
	speed_limit_stack.append(current_speed_limit)
	train.engine_node.get_node("RouteArea").connect("body_entered", self, "_station_entered")
	train.engine_node.get_node("RouteArea").connect("body_exited", self, "_station_exited")
	train.engine_node.get_node("RouteArea").connect("area_entered", self, "_speed_limit_entered")
	train.engine_node.get_node("RouteArea").connect("area_exited", self, "_speed_limit_exited")

func _process(delta):
	var engine_z = train.position.z
	$"%Engine".rect_position.y = lerp(0, 200, 0.5)
	if abs(train.engine_node.reverser):
		$"%Direction".show()
		$"%Direction".rect_position.y = lerp(0, 200, 0.5)
		# Convert the reverser range from -1 to 1 -> 0 to 1
		# Change the flip_v of Direction Marker
		$"%Direction".flip_v = bool(range_lerp(-train.engine_node.reverser, -1, 1, 0, 1))
	else:
		$"%Direction".hide()
	
	$"%Speed".text = "%d kmph" % (train.engine_node.speed * 3.6)
	$"%SpeedLimit".text = "%d kmph" % (current_speed_limit)
	
	for station in tracking_stations:
		var z =  (station.global_transform.origin.z - engine_z) * -train.direction
		var new_y = range_lerp(z, -500, 500, 0, 200)
		tracking_stations[station].rect_position.y = new_y
		if new_y > 190 or new_y <= 20:
			tracking_stations[station].hide()
			continue
		else:
			tracking_stations[station].show()
	

func _station_entered(body: PhysicsBody):
	if not is_instance_valid(body):
		return
	if body.is_in_group("station"):
#		prints("Noticed a station", body.name)
		tracking_stations[body] = $"%Station".duplicate()
		var marker = tracking_stations[body]
		$"%Markers".add_child(marker)
		marker.show()

func _station_exited(body: PhysicsBody):
	if not is_instance_valid(body):
		return
	if body.is_in_group("station"):
#		prints("Station went out of scope!", body.name)
		tracking_stations.get(body).queue_free()
		tracking_stations.erase(body)

func _speed_limit_entered(sl: Area):
	
	if sl.is_in_group("speed_limit"):
		prints("Detected Speed Limit Ahead!", sl)
		sl.connect("body_entered", self, "_engine_speed_limit_entered", [sl])
		sl.connect("body_exited", self, "_engine_speed_limit_exited", [sl])
		if sl.get_overlapping_bodies().has(train.engine_node):
			_engine_speed_limit_entered(train.engine_node, sl)
		

func _speed_limit_exited(sl: Area):
	if sl.is_in_group("speed_limit"):
		print("Speed Limit Out Of Scope, removing!", sl)
		sl.disconnect("body_entered", self, "_engine_speed_limit_entered")
		sl.disconnect("body_exited", self, "_engine_speed_limit_exited")

func _engine_speed_limit_entered(body, sl: Area): # sl = speed limit
	if not is_instance_valid(sl):
		return
	if not body.is_in_group("engine"):
		return
	if sl.is_in_group("speed_limit"):
		prints("Entered speed limit area")
		current_speed_limit = sl.speed_limit
		speed_limit_stack.append(sl.speed_limit)

func _engine_speed_limit_exited(body, sl: Area): # sl = speed limit
	if not is_instance_valid(sl):
		return
	if not body.is_in_group("engine"):
		return
	if sl.is_in_group("speed_limit"):
		prints("Exited speed limit area", sl)
		speed_limit_stack.pop_back()
		current_speed_limit = speed_limit_stack[-1]
		
