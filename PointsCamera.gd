extends Spatial

onready var camera = $"../PointDefault/Camera"

var index = -1

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_8 and not event.shift and not event.control and not event.echo:
				create_new_camera()
			elif event.scancode == KEY_8 and event.control:
				move_current_camera_relative(1)
			elif event.scancode == KEY_8 and event.shift:
				move_current_camera_relative(-1)

func create_new_camera():
	var new_camera = camera.duplicate()
	var _transform = get_tree().get_root().get_camera().global_transform
	add_child(new_camera)
	new_camera.global_transform = _transform
	new_camera.current = true
	if index != -1:
		var camera_child = get_child(index)
		camera_child.current = false
	index = new_camera.get_index()
	

func set_current_camera(new_index):
	var camera_child = get_child(new_index)
	camera_child.current = true
	index = camera_child.get_index()	

func move_current_camera_relative(rel_index):
	set_current_camera((index+rel_index) % get_child_count())
