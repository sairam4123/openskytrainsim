extends Panel

var train

onready var markers_node = $"%Markers"
func _ready():
	_regenerate_train_operations()

func _coupling_pressed(marker, coupling):
	prints("Uncouple", coupling.name, "from train!")
	coupling.queue_free()
	yield(get_tree(), "idle_frame")
	call_deferred("_regenerate_train_operations")

func _regenerate_train_operations():
	_clear_child(markers_node)
	for coach in train.get_consist(true):
		if not is_instance_valid(coach):
			break # uncoupled!
		if coach.is_in_group("engine"):
			var coach_marker = $"%Coach".duplicate()
			coach_marker.text = coach.name
			markers_node.add_child(coach_marker)
		elif coach.name.match("*Coupling*"):
			var coupling_marker = $"%Coupling".duplicate()
			coupling_marker.connect("pressed", self, "_coupling_pressed", [coupling_marker, coach])
			markers_node.add_child(coupling_marker)
		else:
			var coach_marker = $"%Coach".duplicate()
			coach_marker.text = coach.name
			markers_node.add_child(coach_marker)

func _clear_child(node):
	for child in node.get_children():
		child.queue_free()

func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_KP_5:
			_regenerate_train_operations()
