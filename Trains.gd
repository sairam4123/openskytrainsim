extends Spatial

export(int) var current_train_idx = 0

func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_UP and event.control and event.pressed and !event.echo:
			move_to_train_relative(1)
		if event.scancode == KEY_DOWN and event.control and event.pressed and !event.echo:
			move_to_train_relative(-1)
	

func move_to_train_relative(rel_idx):
	var idx = clamp(current_train_idx+rel_idx, 0, get_child_count()-1)
	move_to_train(idx)

func move_to_train(idx):
	get_child(current_train_idx).current = false
	get_child(idx).current = true
	current_train_idx = idx

func _ready():
	for child in get_children():
		if child.current:
			current_train_idx = child.get_index()
