tool
extends AudioStreamPlayer3D

export(Array, AudioStream) var streams setget set_streams
export(float) var announcement_wait_time = 2

var timer = Timer.new()
export var idx = -1

func _ready():
	print(name)
	if not streams.empty():
		idx = 0
		stream = streams[idx]
	add_child(timer)
	timer.connect("timeout", self, "_on_timeout")
	timer.one_shot = true
	connect("finished", self, "_on_finished")

func _on_finished():
	timer.start(announcement_wait_time)
	stop()
	idx = (idx + 1) % streams.size()

func play(from_pos=0.0):
	if streams.empty():
		push_error("Streams empty!, %s" % [streams])
		return
	stream = streams[idx]
	.play(from_pos)

func _on_timeout():
	stream = streams[idx]
	play()

func set_streams(_streams):
	streams = _streams
	if not streams.empty():
		print("test")
		idx = 0
		stream = streams[idx]
