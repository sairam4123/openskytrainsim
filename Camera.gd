extends Spatial

var parent_of_current_parent: Node
var current

func _ready():
	var index = get_parent().get_index()
	parent_of_current_parent = get_parent().get_parent()

func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_RIGHT and event.alt and not event.echo and event.pressed:
			move_to_parent_relative(1)
		elif event.scancode == KEY_LEFT and event.alt and not event.echo and event.pressed:
			move_to_parent_relative(-1)
		if event.scancode == KEY_2 and event.pressed:
			move_to_parent(0)
		if event.scancode == KEY_3 and event.pressed:
			move_to_parent(parent_of_current_parent.get_child_count()-1)
	
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * 0.001)
			$CameraROT.rotate_x(-event.relative.y * 0.001)
		
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
func _process(delta):
	if (Input.is_key_pressed(KEY_2) or Input.is_key_pressed(KEY_3)) and current:
		$CameraROT/Camera.current = true
	if Input.is_key_pressed(KEY_1) and current:
		$CameraROT/Camera.current = false
	if Input.is_key_pressed(KEY_Z):
		$CameraROT/Camera.translation.z += 10 * delta
	if Input.is_key_pressed(KEY_X):
		$CameraROT/Camera.translation.z += -10 * delta
	if Input.is_key_pressed(KEY_Q):
		rotate_y(deg2rad(45 * delta))
	if Input.is_key_pressed(KEY_E):
		rotate_y(deg2rad(-45 * delta))
	if Input.is_key_pressed(KEY_R):
		$CameraROT.rotate_x(deg2rad(45 * delta))
	if Input.is_key_pressed(KEY_F):
		$CameraROT.rotate_x(deg2rad(-45 * delta))

	
func move_to_parent_relative(amount: int):
	var index = get_parent().get_index()
	index = clamp(index+amount, 0, parent_of_current_parent.get_child_count()-1)
	move_to_parent(index)

func move_to_parent(idx: int) -> void:
	var child = parent_of_current_parent.get_child(idx)
	get_parent().remove_child(self)
	child.add_child(self)
