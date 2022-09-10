extends Spatial

var current_sound
var squeaking


export var vehicle_body_np: NodePath
export(int, LAYERS_3D_PHYSICS) var area_mask = 5

var vehicle_body

func _ready():
	if vehicle_body_np:
		vehicle_body = get_node(vehicle_body_np)


func _physics_process(delta):
	var speed = vehicle_body.speed
	var del_speed = vehicle_body.previous_speed-speed
	
	$CoachSoundPlayer.set_param("speed", speed * 3.6)
	if (del_speed) > 0.008 and not is_zero_approx(speed*3.6):
		squeaking = true
		if !$Squeal.playing:
			$Squeal.play()
		SoundPlayer.play_audio_fade_in_apn($Squeal, 0.25)
	elif squeaking:
		SoundPlayer.play_audio_fade_out_apn($Squeal)
		squeaking = false
	if is_equal_approx($Squeal.unit_db, linear2db(0.01)) and $Squeal.playing and !squeaking:
		$Squeal.stop()


func _on_CoachSoundPlayer_transited(from, to) -> void:
	match to:
		"Idle":
			current_sound = SoundPlayer.play_audio_crossfade(current_sound, null, self, 3, $Position3D.translation, 100, area_mask)
		"Speed 10":
##			print("test")
			current_sound = SoundPlayer.play_audio_crossfade(current_sound, preload("res://sounds/coach_sounds/SLOW.wav"), self, 3, $Position3D.translation, 100, area_mask)
##			print(current_sound)
		"Speed 20":
			current_sound = SoundPlayer.play_audio_crossfade(current_sound, preload("res://sounds/coach_sounds/SPEEDRESTRICTION.wav"), self, 3, $Position3D.translation, 100, area_mask)
		"Speed 40":
			current_sound = SoundPlayer.play_audio_crossfade(current_sound, preload("res://sounds/coach_sounds/SPEEDAT40.wav"), self, 3, $Position3D.translation, 100, area_mask)
		"Speed 60":
			current_sound = SoundPlayer.play_audio_crossfade(current_sound, preload("res://sounds/coach_sounds/SPEEDAT55.wav"), self, 3, $Position3D.translation, 100, area_mask)
		"Speed 80":
			current_sound = SoundPlayer.play_audio_crossfade(current_sound, preload("res://sounds/coach_sounds/SPEEDAT65.wav"), self, 3, $Position3D.translation, 100, area_mask)
		"Speed 100":
			current_sound = SoundPlayer.play_audio_crossfade(current_sound, preload("res://sounds/coach_sounds/SPEED80TO120.wav"), self, 3, $Position3D.translation, 100, area_mask)
		"Speed 120":
			current_sound = SoundPlayer.play_audio_crossfade(current_sound, preload("res://sounds/coach_sounds/SPEED120TO140.wav"), self, 3, $Position3D.translation, 100, area_mask)
		"Speed 140":
			current_sound = SoundPlayer.play_audio_crossfade(current_sound, preload("res://sounds/coach_sounds/SPEED140TO200.wav"), self, 3, $Position3D.translation, 100, area_mask)
