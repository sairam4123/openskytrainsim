extends Spatial

##################
# { new_audio: [audio_file, manual_looping]}
##################

var currently_playing = {}

func play_audio(audio_file: AudioStream, node: Node = null, loop = false, backward = false, audio_class = AudioStreamPlayer, position = null, volume = 100, area_mask = 1, dopple_idle = true):
	var new_audio = audio_class.new()
	if audio_class in [AudioStreamPlayer2D, AudioStreamPlayer3D]:
		new_audio.area_mask = area_mask
	new_audio.stream = audio_file
	match audio_class:
		AudioStreamPlayer2D:
			new_audio.position = position
		AudioStreamPlayer3D:
			new_audio.translation = position
	(node if node else self).add_child(new_audio)
	currently_playing[new_audio] = audio_file
#	print(new_audio.stream)
	var sound_loop = audio_file.loop_mode != AudioStreamSample.LOOP_DISABLED
	if loop and not sound_loop:
		audio_file.loop_mode = AudioStreamSample.LOOP_FORWARD if not backward else AudioStreamSample.LOOP_BACKWARD
	if not loop and sound_loop:
		audio_file.loop_mode = AudioStreamSample.LOOP_DISABLED
	if audio_class == AudioStreamPlayer3D: new_audio.unit_db = linear2db(float(volume)/100.0)
	else: new_audio.volume_db = linear2db(float(volume)/100.0)
	if audio_class == AudioStreamPlayer3D:
		new_audio.max_distance = 55
		if dopple_idle:
			new_audio.doppler_tracking = audio_class.DOPPLER_TRACKING_IDLE_STEP
	new_audio.play()
	if not loop:
		yield(new_audio, "finished")
		currently_playing.erase(new_audio)
		(node if node else self).call_deferred('remove_child', new_audio)
	else:
		return new_audio


func play_audio_3D(audio_file: AudioStream, position: Vector3, node: Node, volume = 100, loop = false, backward = false):
#	var new_audio = AudioStreamPlayer3D.new()
#	new_audio.stream = audio_file.sound
#	new_audio.translation = position
#	(node if node else self).add_child(new_audio)
##	print(new_audio.stream)
#	new_audio.play()
#	yield(new_audio, "finished")
#	(node if node else self).call_deferred('remove_child', new_audio)
#	print(audio_file.sound.loop_mode)
	return play_audio(audio_file, node, loop, backward, AudioStreamPlayer3D, position, volume)

func play(audio_file, node: Node, volume = 100, loop = false, backward = false):
	return play_audio(audio_file, node, loop, backward, AudioStreamPlayer, null, volume)

func stop(new_audio):
	if currently_playing.has(new_audio):
		new_audio.stop()
		if new_audio and new_audio.get_parent():
			new_audio.get_parent().call_deferred('remove_child', new_audio)
	else:
		push_error("Something went wrong! Trying to delete the audio.")
		new_audio.stop()
		new_audio.queue_free()

func play_audio_2D(audio_file: AudioStream, position: Vector2, node: Node, loop = false, backward = false, volume = 100):
	return play_audio(audio_file, node, loop, backward, AudioStreamPlayer2D, position, volume)
#
#func play_random(sound_type = "residential"):
#	play_audio(sounds[randi() % sounds.size()])
#
func play_audio_crossfade(previous_audio_player, audio_stream: AudioStream, node: Node, duration = 1, position = null, volume = 100, area_mask: int = 1, audio_class = AudioStreamPlayer3D, loop = true, backward = false, doppler_idle = true):
	var new_audio
	if previous_audio_player != null and !currently_playing.has(previous_audio_player):
		return
	var tween = Tween.new()
	if previous_audio_player:
		if previous_audio_player is AudioStreamPlayer3D:
			tween.interpolate_property(previous_audio_player, "unit_db", previous_audio_player.unit_db, linear2db(0.01), duration, Tween.TRANS_QUINT, Tween.EASE_IN)
		else:
			tween.interpolate_property(previous_audio_player, "volume_db", previous_audio_player.volume_db, linear2db(0.01), duration, Tween.TRANS_QUINT, Tween.EASE_IN)
	if audio_stream:
		new_audio = play_audio(audio_stream, node, loop, backward, audio_class, position, 0.01, area_mask, doppler_idle)
		if new_audio is AudioStreamPlayer3D:
			tween.interpolate_property(new_audio, "unit_db", new_audio.unit_db, linear2db(float(volume)/100.0), duration, Tween.TRANS_QUINT, Tween.EASE_OUT)
		else:
			tween.interpolate_property(new_audio, "volume_db", new_audio.volume_db, linear2db(float(volume)/100.0), duration, Tween.TRANS_QUINT, Tween.EASE_OUT)
	if not (previous_audio_player or audio_stream):
		tween.free()
		return
	add_child(tween)
	tween.connect("tween_completed", self, "_tween_completed", [tween, previous_audio_player])
	tween.start()
	return new_audio

func play_audio_fade_in(audio_stream: AudioStream, node: Node, duration = 1, position = null, volume = 100, audio_class = AudioStreamPlayer, loop = true, backward = false):
	var new_audio = play_audio(audio_stream, node, loop, backward, audio_class, position, 0.01)
	var tween = Tween.new()
	if new_audio is AudioStreamPlayer3D:
		tween.interpolate_property(new_audio, "unit_db", new_audio.unit_db, linear2db(float(volume)/100.0), duration, Tween.TRANS_QUINT, Tween.EASE_OUT)
	else:
		tween.interpolate_property(new_audio, "volume_db", new_audio.volume_db, linear2db(float(volume)/100.0), duration, Tween.TRANS_QUINT, Tween.EASE_OUT)
	add_child(tween)
	tween.start()
	yield(get_tree().create_timer(duration), "timeout")
	tween.queue_free()
	return new_audio

func play_audio_fade_out(new_audio, node: Node, duration: = 1):
	if !currently_playing.has(new_audio):
		return
	var playing = new_audio
	var tween = Tween.new()
	if playing is AudioStreamPlayer3D:
		tween.interpolate_property(playing, "unit_db", playing.unit_db, linear2db(0.01), duration, Tween.TRANS_QUINT, Tween.EASE_IN)
	else:
		tween.interpolate_property(playing, "volume_db", playing.volume_db, linear2db(0.01), duration, Tween.TRANS_QUINT, Tween.EASE_IN)
	tween.connect("tween_completed", self, "_tween_completed", [tween, playing])
	add_child(tween)
	tween.start()
	return null

func _tween_completed(object, _property, tween, object_tc): # tc = to compare
	if object == object_tc:
		stop(object)
	
	tween.queue_free()

func play_audio_fade_in_apn(apn, duration: int = 1, volume: int = 100):
	var tween = Tween.new()
	if apn is AudioStreamPlayer3D:
		tween.interpolate_property(apn, "unit_db", apn.unit_db, linear2db(float(volume)/100), duration, Tween.TRANS_QUINT, Tween.EASE_IN)
	else:
		tween.interpolate_property(apn, "volume_db", apn.volume_db, linear2db(float(volume)/100), duration, Tween.TRANS_QUINT, Tween.EASE_IN)
	add_child(tween)
	tween.connect("tween_all_completed", tween, "queue_free")	
	tween.start()
	return apn

func play_audio_fade_out_apn(apn, duration: int = 1):
	var tween = Tween.new()
	if apn is AudioStreamPlayer3D:
		tween.interpolate_property(apn, "unit_db", apn.unit_db, linear2db(0.01), duration, Tween.TRANS_QUINT, Tween.EASE_IN)
	else:
		tween.interpolate_property(apn, "volume_db", apn.volume_db, linear2db(0.01), duration, Tween.TRANS_QUINT, Tween.EASE_IN)
	add_child(tween)
	tween.connect("tween_all_completed", tween, "queue_free")
	tween.start()
	return apn
