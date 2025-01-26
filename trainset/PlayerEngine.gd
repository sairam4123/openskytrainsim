extends "res://trainset/Engine.gd"

var current setget set_current
var in_station = false

func _input(event):
	if not is_network_master():
		return
	if event is InputEventKey:
		
		if event.scancode == KEY_SHIFT:
			$StateMachinePlayer.set_param("shift_pressed", event.pressed)
		if event.scancode == KEY_P and $StateMachinePlayer.current == "Stopped" and event.pressed:
			$StateMachinePlayer.set_trigger("start_button_pressed")
			_state_machine_rpc("start_button_pressed")
		elif event.scancode == KEY_P and $StateMachinePlayer.current != "Stopped" and event.pressed:
			$StateMachinePlayer.set_trigger("stop_button_pressed")
			_state_machine_rpc("stop_button_pressed")
		
		if event.scancode == KEY_SPACE and event.pressed and not event.echo:
			horn_pressed = true
		elif event.scancode == KEY_SPACE and !event.pressed:
			horn_pressed = false
			horn_pressed_time = OS.get_unix_time()
		
		if event.scancode == KEY_N and event.pressed and not event.echo:
			bell_pressed = true
		elif event.scancode == KEY_N and !event.pressed:
			bell_pressed = false
		
		if event.scancode == KEY_W and event.pressed:
			reverser += 1
		elif event.scancode == KEY_S and event.pressed:
			reverser -= 1
		
		if event.scancode == KEY_SLASH and event.shift and event.pressed:
			tnc_applied = false
			horn_pressed_time = OS.get_unix_time()
		
		if event.scancode == KEY_H and !event.shift and event.pressed:
			headlight += 1
		elif event.scancode == KEY_H and event.shift and event.pressed:
			headlight -= 1
		
		if event.scancode == KEY_F2 and event.pressed:
			debug = !debug
			$Label.visible = debug and train.current

func _physics_process(delta):
	if is_network_master():
		_handle_input(delta)

func _handle_input(delta):
	if Input.is_key_pressed(KEY_A):
		if Input.is_key_pressed(KEY_CONTROL):
			new_throttle = 110
			starting_throttle = throttle
		else:
			throttle += delta * 5
			new_throttle = throttle
	elif Input.is_key_pressed(KEY_D):
		if Input.is_key_pressed(KEY_CONTROL):
			new_throttle = -10
			starting_throttle = throttle
		else:
			throttle -= delta * 5
			new_throttle = throttle
	if Input.is_key_pressed(KEY_SEMICOLON):
		if Input.is_key_pressed(KEY_CONTROL):
			new_train_brake = -10
			starting_train_brake = train_brake
		else:
			train_brake -= 10 * delta
			new_train_brake = train_brake
			
	if Input.is_key_pressed(KEY_APOSTROPHE):
		if Input.is_key_pressed(KEY_CONTROL):
			new_train_brake = 110
			starting_train_brake = train_brake
		else:
			train_brake += 10 * delta
			new_train_brake = train_brake
	
	if Input.is_key_pressed(KEY_BRACKETLEFT):
		if Input.is_key_pressed(KEY_CONTROL):
			new_engine_brake = -10
			starting_brake = engine_brake
		else:
			engine_brake -= 10 * delta
			new_engine_brake = engine_brake
			
	if Input.is_key_pressed(KEY_BRACKETRIGHT):
		if Input.is_key_pressed(KEY_CONTROL):
			new_engine_brake = 110
			starting_brake = engine_brake
		else:
			engine_brake += 10 * delta
			new_engine_brake = engine_brake
			
	if Input.is_key_pressed(KEY_C):
		throttle = 100
		new_throttle = 100
	if Input.is_key_pressed(KEY_V):
		throttle = 0
		new_throttle = 0
	
	if Input.is_key_pressed(KEY_K):
		steering += 0.5 * delta
	if Input.is_key_pressed(KEY_L):
		steering += -0.5 * delta
	
	var progress = abs(((idle_pitch) - current_pitch)/((new_pitch - current_pitch)+0.001))
	idle_pitch += delta * ease(progress+0.001, -0.4) * (new_pitch - idle_pitch)

	if is_equal_approx(new_pitch, current_pitch):
		current_pitch = new_pitch
	
	if $StateMachinePlayer.get_current() == "Throttling":
		new_pitch = 1 + range_lerp(throttle, 0, 100, 0, 5) * delta * 8
	
	var throttle_progress = abs((throttle - starting_throttle)/((new_throttle - starting_throttle)+0.001))
	throttle += delta * ease(throttle_progress+0.001, -0.4) * (new_throttle - throttle)
	throttle = clamp(throttle, 0, 100)
	
	var brake_progress = abs((engine_brake - starting_brake)/((new_engine_brake - starting_brake)+0.001))
	engine_brake += delta * ease(brake_progress+0.001, -0.4) * (new_engine_brake - engine_brake)
	engine_brake = clamp(engine_brake, 0, 100)
	
	var train_brake_progress = abs((train_brake - starting_train_brake)/((new_train_brake - starting_train_brake)+0.001))
	train_brake += delta * ease(train_brake_progress+0.001, -0.4) * (new_train_brake - train_brake)
	self.train_brake = clamp(train_brake, 0, 100)
	
	reverser = clamp(reverser, -1, 1)

func _process(delta):
	var current_time = OS.get_unix_time()
	var engine_power_state = $StateMachinePlayer.get_current() in ["Idle", "Throttling"]	
	if debug and current:
		$Label.text = "Throttle: %d%%\n" % throttle
		$Label.text += "Brake: %s\n" % str(brake)
		$Label.text += "Engine Brake: %s\n" % str(engine_brake)
		$Label.text += "Train Brake: %s\n" % str(train_brake)
		$Label.text += "Reverser: %d\n" % reverser
		$Label.text += "Speed: %.2f mps\n" % speed
		$Label.text += "Speed: %.2f kmph\n" % (speed * 3.6)
		$Label.text += "Engine Force: %d N\n" % abs(engine_force)
		$Label.text += "Power: %s\n" % str(engine_power_state)
		$Label.text += "Power Mode: %s\n" % str($StateMachinePlayer.current)
		$Label.text += "Traction lock active: %s\n" % str(traction_lock_active)
		$Label.text += "Current Position: %s\n" % str(global_transform.origin)
		$Label.text += "TNC: %s\n" % str(tnc_applied)
		$Label.text += "Horn Pressed: %s\n" % str(horn_pressed)
		$Label.text += "TNC in %s seconds\nPress horn before TNC!" % str(abs(time_between_horns - (current_time - horn_pressed_time)))

func set_current(value: bool):
	current = value
	$"%CameraBase".current = value
	$"%Camera2".current = value
	$"%Camera2".train = train
#	$"%CameraBase".train = train


func _on_StationArea_area_entered(area):
	if area.is_in_group("station"):
		in_station = true

func _on_StationArea_area_exited(area):
	if area.is_in_group("station"):
		in_station = false


func _on_Couplers_area_entered(area):
	prints("ENGINE Front", area, $Couplers)

func _on_Couplers2_area_entered(area):
	prints("ENGINE Back", area, $Couplers2)
