extends Panel


var train

export(Array, Gradient) var grads = []

var current_speed_limit

var tracking_stations = {}
var tracking_sls = {}
var tracking_signals = {}

var limits = {
	0.01: Color.darkgreen,
	0.25: Color.lightgreen,
	1.05: Color.darkred,
	1.2: Color.red
}

var speed_limit_stack = []
func _ready():
	current_speed_limit = get_parent().get_parent().get_route_max_speed()
	speed_limit_stack.append(current_speed_limit)

func ready():
	var route_area = train.get_engine_node().get_node("RouteArea")
	route_area.connect("body_entered", self, "_station_entered")
	route_area.connect("body_exited", self, "_station_exited")
	route_area.connect("area_entered", self, "_speed_limit_entered")
	route_area.connect("area_entered", self, "_signal_entered")
	route_area.connect("area_exited", self, "_speed_limit_exited")
	route_area.connect("area_exited", self, "_signal_exited")
	
	for body in route_area.get_overlapping_bodies() + route_area.get_overlapping_areas():
		if body is PhysicsBody:
			_station_entered(body)
		else:
			if body.is_in_group("signal"):
				_signal_entered(body)
			else:
				_speed_limit_entered(body)
	

func _process(delta):
	if not is_instance_valid(train):
		return
	var engine_z = train.position.z
	$"%Engine".rect_position.y = lerp(0, 200, 0.5)
	if is_instance_valid(train.get_engine_node()) and abs(train.get_engine_node().reverser):
		$"%Direction".show()
		$"%Direction".rect_position.y = lerp(0, 200, 0.5)
		# Convert the reverser range from -1 to 1 -> 0 to 1
		# Change the flip_v of Direction Marker
		$"%Direction".flip_v = bool(range_lerp(-train.get_engine_node().reverser, -1, 1, 0, 1))
	else:
		$"%Direction".hide()
	
	$"%Speed".text = "%d kmph" % (train.get_engine_node().speed * 3.6)
	$"%SpeedLimit".text = "%d kmph" % (current_speed_limit)
	for limit in limits:
		if (train.get_engine_node().speed * 3.6) > (current_speed_limit * limit):
			$"%VSeparator".modulate = limits[limit]
			$"%VSeparator2".modulate = limits[limit]
			
	for station in tracking_stations:
		var z =  (station.global_transform.origin.z - engine_z) * -train.direction
		var new_y = range_lerp(z, -500, 500, 0, 200)
		tracking_stations[station].rect_position.y = new_y
		
		if new_y > 190 or new_y <= 20:
			tracking_stations[station].hide()
		else:
			tracking_stations[station].show()
	
	for sl in tracking_sls:
		var z = ((sl.global_translation.z + (sl.extents.z * -train.direction)) - engine_z) * -train.direction
		var new_y = range_lerp(z, -500, 500, 0, 200)
		var z1 = ((sl.global_translation.z - (sl.extents.z * -train.direction)) - engine_z) * -train.direction
		var new_y1 = range_lerp(z1, -500, 500, 0, 200)
		tracking_sls[sl][0].rect_position.y = new_y
		tracking_sls[sl][1].rect_position.y = new_y1
		if new_y > 190 or new_y <= 20:
			tracking_sls[sl][0].hide()
		else:
			tracking_sls[sl][0].show()
		if new_y1 > 190 or new_y1 <= 20:
			tracking_sls[sl][1].hide()
		else:
			tracking_sls[sl][1].show()
	for sig in tracking_signals:
		var z = (sig.global_transform.origin.z - engine_z) * -train.direction
		var new_y = range_lerp(z, -500, 500, 0, 200)
		var marker = tracking_signals[sig]
		var texture = marker.material.get_shader_param("gradient_texture")
		texture.gradient = grads[sig.get_parent()._signal_state]
		marker.material.set_shader_param("gradient_texture", texture)
		marker.rect_position.y = new_y
		if new_y > 190 or new_y <= 20:
			tracking_signals[sig].hide()
		else:
			tracking_signals[sig].show()
	
		
func _signal_entered(body: Area):
	if not is_instance_valid(body):
		return
	if body.is_in_group("signal") and body.get_parent().visible:
		if body.get_parent().direction != train.direction:
			print(body.get_parent().direction, train.direction)
			return
		print("Noticed signal")
		tracking_signals[body] = $"%SignalMarker".duplicate()
		var marker = tracking_signals[body]
		var texture = marker.material.get_shader_param("gradient_texture").duplicate()
		texture.gradient = grads[body.get_parent()._signal_state]
		marker.material = marker.material.duplicate()
		marker.material.set_shader_param("gradient_texture", texture)
		$"%Markers".add_child(marker)
		marker.show()

func _signal_exited(body: Area):
	if not is_instance_valid(body):
		return
	if not (body.is_in_group("signal") and body.get_parent().visible):
		return
	if body.get_parent().direction != train.direction:
		return
	tracking_signals.get(body).queue_free()
	tracking_signals.erase(body)

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
	if is_instance_valid(sl) and sl.is_in_group("speed_limit"):
		prints("Detected Speed Limit Ahead!", sl)
		sl.connect("body_entered", self, "_engine_speed_limit_entered", [sl])
		sl.connect("body_exited", self, "_engine_speed_limit_exited", [sl])
		tracking_sls[sl] = [null, null]
		tracking_sls[sl][0] = $"%SpeedLimitMarker".duplicate()
		tracking_sls[sl][0].text = str(sl.speed_limit) + " kmph"
		tracking_sls[sl][1] = $"%SpeedLimitMarker".duplicate()
		tracking_sls[sl][1].text = str(get_parent().get_parent().get_route_max_speed()) + " kmph"
		
		$"%Markers".add_child(tracking_sls[sl][0])
		$"%Markers".add_child(tracking_sls[sl][1])
		if sl.get_overlapping_bodies().has(train.get_engine_node()):
			_engine_speed_limit_entered(train.get_engine_node(), sl)



func _speed_limit_exited(sl: Area):
	if sl.is_in_group("speed_limit"):
		print("Speed Limit Out Of Scope, removing!", sl)
		sl.disconnect("body_entered", self, "_engine_speed_limit_entered")
		sl.disconnect("body_exited", self, "_engine_speed_limit_exited")
		tracking_sls.get(sl)[0].queue_free()
		tracking_sls.get(sl)[1].queue_free()
		tracking_sls.erase(sl)
		

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
		
func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_KP_1 and event.pressed:
			print("SETTING UP ROUTE MAP")
			ready()
		if event.scancode == KEY_6 and event.control and event.pressed:
			print("Setting up route map Control+Key6")
			ready()
			
