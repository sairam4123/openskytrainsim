tool
extends AudioStreamPlayer3D


export(float) var loop_start = 0.61 # 0.8
export(float) var loop_middle = 3.34
export(float) var loop_end = 3.38
export(bool) var horn_playing setget set_horn_playing

func play(from_pos: float = 0):
	.play(from_pos)
	horn_playing = true
	
func stop():
	.stop()
	horn_playing = false
	.play(loop_end)

func _process(delta):
	if horn_playing and get_playback_position() > loop_middle:
		seek(loop_start)
	if horn_playing and is_equal_approx(get_playback_position(), stream.get_length()):
		.stop()

func set_horn_playing(play: bool):
	if horn_playing == play:
		return
	horn_playing = play
	if horn_playing:
		play()
	elif !horn_playing:
		stop()
