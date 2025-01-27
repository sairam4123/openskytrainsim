extends Panel

var train

onready var markers_node = $"%Markers"
#func _ready():
#	_regenerate_train_operations()

func _coupling_pressed(marker, coupling):
	prints("Uncouple", coupling.name, "from train!")
	train.uncouple(coupling)
	yield(get_tree(), "idle_frame")
	call_deferred("_regenerate_train_operations")

func _regenerate_train_operations():
	_clear_child(markers_node)
	var prev_coach = train.get_consist()[0]
	print(range(-1, -train.get_consist().size()-1, -1))
	for coach_idx in range(train.get_consist().size()):
		var coach = train.get_consist()[coach_idx]
		print(coach)
		if not is_instance_valid(coach):
			break # uncoupled!
#		if prev_coach == coach:
#			continue # engine twice, ignore!
		if coach.is_in_group("engine"):
			print("ENGINE")
			var coach_marker = $"%Coach".duplicate()
			coach_marker.text = coach.name
			markers_node.add_child(coach_marker)
#			if prev_coach:
#				var joint = train.joints[[prev_coach, coach]]
#				var coupling_marker = $"%Coupling".duplicate()
#				coupling_marker.connect("pressed", self, "_coupling_pressed", [coupling_marker, joint])
#				markers_node.add_child(coupling_marker)
		else:
			if prev_coach:
				var joint = train.joints[[coach, prev_coach]]
				var coupling_marker = $"%Coupling".duplicate()
				coupling_marker.connect("pressed", self, "_coupling_pressed", [coupling_marker, joint])
				markers_node.add_child(coupling_marker)
			var coach_marker = $"%Coach".duplicate()
			coach_marker.text = coach.name
			markers_node.add_child(coach_marker)
		prev_coach = coach

func _clear_child(node):
	for child in node.get_children():
		child.queue_free()

func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_KP_5:
			_regenerate_train_operations()
		if event.scancode == KEY_7 and event.control and event.pressed:
			_regenerate_train_operations()
