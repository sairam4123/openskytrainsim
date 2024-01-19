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
export(String, FILE) var train_scene
export(bool) var current setget set_current
export(bool) var playable = false

var position: Vector3 setget , get_position
var train_brake = 0.0 setget set_train_brake

var consist: Array setget, get_consist

var _consist_with_joints = []

var joints = {}

var in_station = false
onready var coach_node: VehicleBody = get_node(coach_node_path)
onready var coupling_node: Spatial = get_node(coupling_node_path)
onready var joints_node: Spatial = get_node(joints_node_path)
onready var consist_node: Spatial = get_node(consist_node_path)
onready var engine_node: Spatial = get_node(engine_node_path)

var direction

var train_scene_packed

# Called when the node enters the scene tree for the first time.
func _ready():
	train_scene_packed = load(train_scene).duplicate(true)
	if is_network_master() and playable:
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
	if playable:
		set("current", current)
		var new_engine = engine_node.duplicate()
		var coach_new = coach_node.duplicate()
		consist_node.add_child(new_engine)
		consist_node.add_child(coach_new)
		new_engine.current = true
		$ConsistDefault.remove_child(engine_node)
		$ConsistDefault.remove_child(coach_node)
		engine_node = new_engine
		coach_new.global_transform.origin.z = engine_node.global_transform.origin.z - 8 * (2 * int(rotation_degrees.y < 0) - 1)
		new_engine.train = self
		_consist_with_joints.append_array([new_engine, null, coach_new])
		var previous_coach = coach_new
		previous_coach.train = self
		for i in num_of_coaches:
			var new_coach: VehicleBody = previous_coach.duplicate()
			consist_node.add_child(new_coach, true)
			new_coach.train = self
			new_coach.global_transform.origin.z -= 9.5 * (2 * int(rotation_degrees.y < 0) - 1)
			previous_coach = new_coach
			_consist_with_joints.append_array([null, new_coach])
		
		self.current = is_network_master()
		$Consist/Engine/Label3D.text = nick_name
	if not playable:
		$ConsistDefault.remove_child(engine_node)
		$ConsistDefault.remove_child(coach_node)

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
	var pos = Vector3.ZERO
	for consist_idx in range(0, $Consist.get_child_count()):
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

func join(coach1, coach2):
	var new_coupling = coupling_node.duplicate()
	joints_node.add_child(new_coupling, true)
	new_coupling.set("node_a", coach1.get_path())
	new_coupling.set("node_b", coach2.get_path())
	joints[[coach1, coach2]] = new_coupling

func couple(train2):
	print("COUPLING!")
	var coach1 = get_consist()[-1]
	var coach2 = train2.get_consist()[0]
	
	var new_coupling = coupling_node.duplicate()
	joints_node.add_child(new_coupling, true)
	new_coupling.set("node_a", coach1.get_path())
	new_coupling.set("node_b", coach2.get_path())
	joints[[coach1, coach2]] = new_coupling
	var consist = train2.consist
	for idx in range(0, consist.size()):
		var coach = consist[idx]
		coach.train = self
		train2.consist_node.remove_child(consist[idx])
		self.consist_node.add_child(consist[idx], true)
		if idx+1 >= consist.size():
			continue
		var new_coach = consist[idx+1]
#		print(joints)
		var joint = train2.joints[[new_coach, coach]]
		train2.joints.erase([coach, new_coach])
		self.joints[[new_coach, coach]] = joint
		train2.joints_node.remove_child(joint)
		self.add_child(joint)
	train2.queue_free()
	

const Locomotive = preload("res://trainset/PlayerEngine.gd")

func get_engine_node():
	if engine_node:
		return engine_node
	for coach in consist:
		print(coach, "CHECKING ENGINE NODE", coach is Locomotive)
		if coach is Locomotive:
			engine_node = coach
			return engine_node

func uncouple(coupling):
	var coaches
	for couple in joints:
		if joints[couple] == coupling:
			coaches = couple
	coupling.queue_free()
	var coach = coaches[0]
	var coach_idx = get_consist().find(coach)
	print(coach_idx)
	var consist = get_consist().duplicate()
	var new_train = train_scene_packed.duplicate().instance()
	new_train.playable = false
	get_parent().add_child(new_train)
	new_train.global_transform.origin = self.global_transform.origin
	for idx in range(coach_idx, consist.size()):
		coach = consist[idx]
		coach.train = new_train
		consist_node.remove_child(consist[idx])
		new_train.consist_node.add_child(consist[idx], true)
		if idx+1 >= consist.size():
			continue
		var new_coach = consist[idx+1]
#		print(joints)
		var joint = joints[[new_coach, coach]]
		joints.erase([coach, new_coach])
		new_train.joints[[new_coach, coach]] = joint
		joints_node.remove_child(joint)
		new_train.add_child(joint)
		
	
