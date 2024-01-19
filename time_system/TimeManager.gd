extends Node

func to_time(hr, mi, sec):
	return hr * 60 * 60 + mi * 60 + sec

var hour = 12
var minute = 1
var secs = 1


func get_time():
	return to_time(hour, minute, secs)

func _process(delta):
	secs += delta
	if secs >= 60:
		secs = 0
		minute += 1
	if minute >= 60:
		minute = 0
		hour += 1
	hour %= 24
