extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var nick_name: String

export(int) var num_of_coaches = 24
export(NodePath) var coach_node_path
export(NodePath) var coupling_node_path
export(NodePath) var joints_node_path
export(NodePath) var consist_node_path
export(NodePath) var engine_node_path
export(bool) var current setget set_current

var position: Vector3 setget , get_position
var train_brake = 0.0 setget set_train_brake
var consist: Array setget, get_consist

var _consist_with_joints = []
var in_station = false
onready var coach_node: VehicleBody = get_node(coach_node_path)
onready var coupling_node: Spatial = get_node(coupling_node_path)
onready var joints_node: Spatial = get_node(joints_node_path)
onready var consist_node: Spatial = get_node(consist_node_path)
onready var engine_node: Spatial = get_node(engine_node_path)

var direction

# Called when the node enters the scene tree for the first time.
func _ready():
	if is_network_master():
		var station
		var station_name = get_tree().get_meta("station_name")
		if not station_name.to_lower().begins_with("random"):
			station = station_name
		var preferred_dir = get_tree().get_meta("preferred_dir")
		var pos = get_parent().get_position_to_spawn(station, preferred_dir)
		if pos:
			global_transform.origin.z = pos.z
			global_transform.origin.x = pos.x
			direction = pos.y
			var new_pos_y = range_lerp(pos.y, -1, 1, 0, 1)
			global_transform.basis = Basis.IDENTITY.rotated(Vector3.UP, PI * new_pos_y)
			rpc("set_position", global_transform)
	
	set("current", current)
	engine_node.train = self
	_consist_with_joints.append_array([engine_node, coupling_node, coach_node])
	var previous_coach = coach_node
	previous_coach.train = self
	for i in num_of_coaches:
		var new_coach: VehicleBody = previous_coach.duplicate()
		consist_node.add_child(new_coach, true)
		new_coach.train = self
		new_coach.global_transform.origin.z -= 9.5 * (2 * int(rotation_degrees.y < 0) - 1)
		var new_coupling = coupling_node.duplicate()
		joints_node.add_child(new_coupling, true)
		new_coupling.set("node_a", previous_coach.get_path())
		new_coupling.set("node_b", new_coach.get_path())
		previous_coach = new_coach
		_consist_with_joints.append_array([new_coupling, new_coach])
	
	self.current = is_network_master()
	$Consist/Engine/Label3D.text = nick_name

puppet func set_position(glob_xform: Transform):
	global_transform = glob_xform
	
func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_G and event.pressed:
			OS.set_window_always_on_top(!OS.is_window_always_on_top())

func set_current(value: bool):
	current = value
	if !is_inside_tree():
		return
	engine_node.current = value

func set_train_brake(value: float):
	train_brake = value
	if !is_inside_tree():
		return
	for coach_idx in range(0, $Consist.get_child_count()):
		var coach = $Consist.get_child(coach_idx)
		if coach:
			coach.brake = train_brake/($Consist.get_child_count()-1)
#		if coach.name.begins_with("engine"):
#			coach. = train_brake/($Consist.get_child_count()-1)
#func _physics_process(delta):
#	global_transform.origin = $Consist/Engine.global_transform.origin

func get_position():
	var pos = engine_node.global_transform.origin
	for consist_idx in range(1, $Consist.get_child_count()):
		var coach = $Consist.get_child(consist_idx)
		pos += coach.global_transform.origin
	return pos/$Consist.get_child_count()
		

#func _on_StationArea_area_entered(area):
#	if area.is_in_group("station"):
#		var station = area.get_parent()
#		in_station = true
##		station.connect("train_stopped", self, "_train_stopped", [self])
#
#
#func _train_stopped(train):
#	if train != self:
#		return
##	global_transform.origin = $Consist/Engine.global_transform.origin
##	$Consist/Engine.translation = Vector3(0, 0, 0)
#
#
#func _on_StationArea_area_exited(area):
#	if area.is_in_group("station"):
#		var station = area.get_parent()
#		in_station = false
##		station.disconnect("train_stopped", self, "_train_stopped")

func get_consist(with_joints = false):
	if with_joints:
		return _consist_with_joints
	else:
		return consist_node.get_children()
