extends Camera

var train

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (Input.is_key_pressed(KEY_2) or Input.is_key_pressed(KEY_3)) and train.current:
		current = false
	if Input.is_key_pressed(KEY_1) and train.current:
		current = true
	if current:
#		if !AudioServer.is_bus_effect_enabled(0, 1):
##			print(AudioServer.is_bus_effect_enabled(0, 0), "Test")
#			AudioServer.set_bus_effect_enabled(0, 1, true)
		AudioServer.set_bus_volume_db(0, -20)
	else:
#		if AudioServer.is_bus_effect_enabled(0, 1):
##			print(AudioServer.is_bus_effect_enabled(0, 0), "WOW")
#			AudioServer.set_bus_effect_enabled(0, 1, false)
			AudioServer.set_bus_volume_db(0, -4)
