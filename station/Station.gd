tool
extends StaticBody

signal train_stopped

export(Array, AudioStream) var train_announcement: Array setget set_ann_player_st
export(float) var announcement_volume: float setget set_ann_player_vol
export(bool) var playing: bool setget set_ann_player_playing
export(bool) var autoplay: bool setget set_ann_player_autoplay
export(float) var time_on_station: float = 20
export(float) var time_between_ann: float = 5

export var ann_index = 0

var timers = {}
func _ready():
	if not train_announcement.empty():
		set_announcement_players_stream(train_announcement, announcement_volume, playing)
	set_board_text(name)
	
	var children = get_children_by_type($AnnouncementPlayer, "AudioStreamPlayer3D")
	var ply = children[0]
	if not ply.is_connected("finished", self, "_change_ann"):
			ply.connect("finished", self, "_change_ann")
	
	if !Engine.editor_hint:
		print(name)
		play()
#		$Signal._signal_state = $Signal.SignalState.STOP
#		$Signal2._signal_state = $Signal2.SignalState.STOP
		
	
	

func _process(_delta):
	# _handle_stop_time()
	if !Engine.editor_hint:
		return
	set_board_text(name)

func _handle_stop_time():
	for body in timers:
		if is_instance_valid(body) and is_zero_approx(body.speed):
			var timer = timers[body]
			if is_instance_valid(timer):
				if timer.is_stopped() and not timer.has_meta("ok_to_depart"):
					timer.start(time_on_station)
					emit_signal("train_stopped")
					
				elif timer.has_meta("ok_to_depart") and not timer.is_stopped():
					timer.stop()
		elif !is_instance_valid(body):
			timers.erase(body)

func set_board_text(text: String):
	for board in $Boards.get_children():
		board.text = text
	for sheets in $Sheets.get_children():
		for board in sheets.get_children():
			if board.is_in_group("station_board"):
				board.text = text

func get_children_by_type(node, type):
	var arr = []
	for child in node.get_children():
		if child.get_class() == type:
			arr.append(child)
		arr += get_children_by_type(child, type)
	return arr

func set_announcement_players_stream(streams: Array, volume: float, _playing: bool = true):
	var children = get_children_by_type($AnnouncementPlayer, "AudioStreamPlayer3D")	
	for player in children:
		player.stream = streams[0]
		player.unit_db = volume
		player.playing = _playing

func set_ann_player_st(st: Array):
	train_announcement = st
	if !is_inside_tree():
		return
	var children = get_children_by_type($AnnouncementPlayer, "AudioStreamPlayer3D")
	ann_index %= train_announcement.size()
	for player in children:
		player.stream = train_announcement[ann_index]

func set_ann_player_vol(vol: float):
	announcement_volume = vol
	if !is_inside_tree():
		return
	var children = get_children_by_type($AnnouncementPlayer, "AudioStreamPlayer3D")	
	for player in children:
		player.unit_db = announcement_volume
		player.max_db = announcement_volume

func set_ann_player_playing(play: bool):
	playing = play
	if !is_inside_tree():
		return
	var children = get_children_by_type($AnnouncementPlayer, "AudioStreamPlayer3D")
	for player in children:
		player.playing = playing

func set_ann_player_autoplay(_autoplay: bool):
	autoplay = _autoplay
	if !is_inside_tree():
		return
	var children = get_children_by_type($AnnouncementPlayer, "AudioStreamPlayer3D")
		
	for player in children:
		player.autoplay = autoplay

func play():
	prints("playing", name)
	var children = get_children_by_type($AnnouncementPlayer, "AudioStreamPlayer3D")
	
	var ply = children[0]
	if not ply.is_connected("finished", self, "_change_ann"):
			ply.connect("finished", self, "_change_ann")
	for player in children:
		player.play()


func _change_ann():
	ann_index += 1
	ann_index %= train_announcement.size()

	yield(get_tree().create_timer(time_between_ann), "timeout")
	var children = get_children_by_type($AnnouncementPlayer, "AudioStreamPlayer3D")
	
	for player in children:
		player.stream = train_announcement[ann_index]
		player.play()
	
	

func stop():
	var children = get_children_by_type($AnnouncementPlayer, "AudioStreamPlayer3D")	
	for player in children:
		player.stop()


func _on_Area_body_entered(body):
	if body.is_in_group("engine"):
		print("Engine %s entered %s" % [body.engine_name, name])
		print("press horn")
		timers[body] = Timer.new()
		add_child(timers[body])
		timers[body].wait_time = time_on_station
		timers[body].one_shot = true
		timers[body].connect("timeout", self, "_on_timer_timeout", [body])


func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_KP_0 and event.pressed and not event.echo:
			for body in $Area.get_overlapping_bodies():
				if body.is_in_group("engine"):
					_on_timer_timeout(body)


func _on_Area_body_exited(body):
	if body.is_in_group("engine"):
		print("Engine %s exited %s" % [body.engine_name, name] )
		print("press horn twice")
		var timer = timers.get(body)
		if timer:
			timer.queue_free()

func _on_timer_timeout(body: Spatial):
	var audio = preload("res://sounds/depart_steam_whistle.wav")
	var pos = body.global_transform.origin
	var point = Geometry.get_closest_point_to_segment(pos, $Boards/EndBoard.global_transform.origin, $Boards/EndBoard2.global_transform.origin)
	print(point)
#	var proceed = SoundPlayer.play(preload("res://sounds/d_perm_03.wav"), self, 150)
	yield(SoundPlayer.play_audio_3D(audio, to_local(point), self, 150), "completed")
#	yield(proceed, "completed")
	print("OK to depart, ", body.engine_name)
	prints(body.train.direction, $Signal.direction)
	if body.train.direction == $Signal.direction:
		$Signal._signal_state = $Signal.signal_inst.SignalState.PROCEED
	elif body.train.direction == $Signal2.direction:
		$Signal2._signal_state = $Signal2.signal_inst.SignalState.PROCEED
		
	
	timers[body].set_meta("ok_to_depart", true)
	timers[body].stop()


#func _on_VisibilityNotifier_camera_entered(camera):
#	if Engine.editor_hint:
#		return
#	if train_announcement:
#		set_announcement_players_stream(train_announcement, announcement_volume, playing)
#	set_board_text(name)
#	show()
#
#
#
#func _on_VisibilityNotifier_camera_exited(camera):
#	if Engine.editor_hint:
#		return
#	stop()
#	hide()




func _on_StopMarker_body_entered(body):
	if body.is_in_group("engine"):
		print("Engine %s is stopping" % body.engine_name)
		timers[body].start()
		
