extends VehicleBody

export(String) var engine_name

var throttle = 0 # SYNC
var train_brake = 0 setget set_train_brake # SYNC 
var current_pitch = 0.01
var new_throttle = 0
var new_engine_brake = 0
var new_train_brake = 0
var starting_brake = 0
var starting_throttle = 0
var starting_train_brake = 0
var new_pitch = 0.02
var horn_pressed = false # SYNC
var bell_pressed = false # SYNC
var horn_pressed_time = 0
var reverser = 0 # SYNC
var engine_brake = 0 # SYNC
var tnc_applied = false # SYNC
var time_between_horns = 2*60
var headlight = 0 # SYNC
var debug = false
var idle_pitch = current_pitch # SYNC
var traction_lock_active = false

var previous_position = Vector3.INF
export(float, 100, 15000) var engine_torque_hp = 100

var speed
var previous_speed = INF
var previous_translation = Vector3.ZERO

var train

func _ready():
	$StateMachinePlayer.set_param("throttle", throttle)

func set_train_brake(value:float):
	train_brake = value
	if !is_inside_tree():
		return
	if train:
		train.train_brake = train_brake

func _physics_process(delta):
	var engine_power_state = $StateMachinePlayer.get_current() in ["Idle", "Throttling"]
	var current_time = OS.get_unix_time()
	
	_calc_speed(delta)
	if is_network_master():
		_rpc_data()
	
#	_procss_sounds(delta)
	headlight = clamp(headlight, 0, 3)
	
	if abs(current_time-horn_pressed_time) > time_between_horns and throttle > 1 and speed > 1 and not train.in_station:
		train_brake = 100
		new_train_brake = 100
		tnc_applied = true
#		$StateMachinePlayer.set_trigger("stop_button_pressed")
#		_state_machine_rpc("stop_button_pressed")
	
#	if (speed >= 1 and speed < 40) and throttle < 1 and engine_brake <= 0:
#		brake = -lerp(1, 50, clamp(speed, 1, 40)/40)
#	else:
	if engine_brake > 0 or train_brake > 0:
		traction_lock_active = true
	elif engine_brake < 1 and train_brake < 1 and throttle < 1:
		traction_lock_active = false
	
	brake = engine_brake
	
	if engine_brake >= 100 and tnc_applied:
		brake = engine_brake
	
	if engine_power_state and !traction_lock_active:
		engine_force = (clamp(-throttle + engine_brake, -100, 0)/100) * engine_torque_hp * 0.746 * 0.8 * reverser
	else:
		engine_force = 0
	
	
	if is_equal_approx(idle_pitch, 0.01):
		if $IdleSoundPlayer.is_playing():
			$IdleSoundPlayer.stop()
	
	$HornPlayer.horn_playing = horn_pressed
	$HornPlayer2.horn_playing = horn_pressed
	$BellPlayer.horn_playing = bell_pressed
	$BellPlayer2.horn_playing = bell_pressed
	
	match headlight:
		0:
			$OmniLight.hide()
			$OmniLight2.hide()
			$SpotLight.hide()
			$SpotLight2.hide()
		1:
			$OmniLight.show()
			$OmniLight2.show()
			$SpotLight.show()
			$SpotLight2.show()
			
			$OmniLight.light_energy = 0.5
			$OmniLight2.light_energy = 0.5
			$SpotLight.light_energy = 2.5
			$SpotLight2.light_energy = 2.5
		2:
			$OmniLight.show()
			$OmniLight2.show()
			$SpotLight.show()
			$SpotLight2.show()
			
			$OmniLight.light_energy = 1
			$OmniLight2.light_energy = 1
			$SpotLight.light_energy = 5
			$SpotLight2.light_energy = 5
	
	
	$StateMachinePlayer.set_param("throttle", throttle)
	
	$IdleSoundPlayer.pitch_scale = idle_pitch

func _calc_speed(delta):
	if previous_position == Vector3.INF:
		previous_position = global_transform.origin
	if is_inf(previous_speed):
		previous_speed = speed
	speed = abs((previous_position.z - global_transform.origin.z) / delta)
	previous_position = global_transform.origin
	previous_speed = speed
	
	if is_zero_approx(speed):
		pass

func _rpc_data():
	rpc("sync_props", {
		"idle_pitch": idle_pitch, 
		"headlight": headlight, 
		"tnc_applied": tnc_applied, 
		"engine_brake": engine_brake,
		"reverser": reverser,
		"throttle": throttle,
		"horn_pressed": horn_pressed,
		"bell_pressed": bell_pressed,
		"horn_pressed_time": horn_pressed_time,
		"traction_lock_active": traction_lock_active,
		})

func _state_machine_rpc(trigger):
	rpc("sync_state_machine", trigger)

remote func sync_state_machine(trigger):
	$StateMachinePlayer.set_trigger(trigger)

remote func sync_props(synced_props):
	for synced_prop in synced_props:
		set(synced_prop, synced_props[synced_prop])
#	$Label3D.text = str(get_tree().get_rpc_sender_id()) + " " + str($StateMachinePlayer.get_current()) + " " + str(horn_pressed)

func _on_StateMachinePlayer_transited(from, to):
	if from == "Stopped" and to in ["Starting", "Starting2"]:
		$PantoUpPlayer.play()
		$IdleSoundPlayer.play()
		match to:
			"Starting":
				$PantoUpPlayer.translation.z = $Pantograph.translation.z
				$AnimationPlayer.play("PantoUpAnim")
			"Starting2":
				$PantoUpPlayer.translation.z = $Pantograph2.translation.z
				$AnimationPlayer.play("Panto2UpAnim")
		new_pitch = 1
		current_pitch = $IdleSoundPlayer.pitch_scale
		print("starting engine", get_tree().get_network_unique_id())
		yield($PantoUpPlayer, "finished")
		$StateMachinePlayer.set_trigger("started")
	if from in ["Idle", "Throttling"] and to in ["Stopping", "Stopping2"]:
		new_pitch = 0.01
		current_pitch = $IdleSoundPlayer.pitch_scale
		print("Stopping Engine", get_tree().get_network_unique_id())
		$PantoDownPlayer.play()
		match to:
			"Stopping":
				$AnimationPlayer.play_backwards("PantoUpAnim")
				$PantoDownPlayer.translation.z = $Pantograph.translation.z
			"Stopping2":
				$AnimationPlayer.play_backwards("Panto2UpAnim")
				$PantoDownPlayer.translation.z = $Pantograph2.translation.z
		
		yield($PantoDownPlayer, "finished")
		$StateMachinePlayer.set_trigger("stopped")
	if from == "Idle" and to == "Throttling":
		new_pitch = 1.15
		current_pitch = $IdleSoundPlayer.pitch_scale
		$IdleSoundPlayer.unit_db = linear2db(0.75 - 0.005)
	if from == "Throttling" and to == "Idle":
		new_pitch = 1
		current_pitch = $IdleSoundPlayer.pitch_scale
		$IdleSoundPlayer.unit_db = linear2db(0.75)
		
	match to:
		"Idle":
			prints("Idling", get_tree().get_network_unique_id())
#			if not $IdleSoundPlayer.is_playing():
#				$IdleSoundPlayer.play()
#			$IdleSoundPlayer.pitch_scale = 1
			new_pitch = 1
			current_pitch = $IdleSoundPlayer.pitch_scale
			$IdleSoundPlayer.unit_db = linear2db(0.75)
			
		"Throttling":
			print("Throttling!", get_tree().get_network_unique_id())
		"Stopped":
			if !is_inside_tree():
				return
			print("Stopped", get_tree().get_network_unique_id())
