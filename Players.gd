extends Node


var players = {} # ID: TRAIN

# TODO: Move this to a seperate file
func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_F1 and event.control and event.pressed:
			OS.window_fullscreen = !OS.window_fullscreen
			
