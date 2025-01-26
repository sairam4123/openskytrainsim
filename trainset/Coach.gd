extends VehicleBody

var speed = 0
var squeaking = false
var previous_speed = INF

var current_sound = null

var debug = false
var train

var del_speed
var previous_position = Vector3.INF

func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_F2 and event.pressed:
			debug = !debug
			$Label.visible = debug and train.current

func _physics_process(delta):
	if previous_position == Vector3.INF:
		previous_position = global_transform.origin
	speed = abs((previous_position.z - global_transform.origin.z) / delta)
	if previous_speed == INF:
		previous_speed = speed
	previous_position = global_transform.origin
	
	del_speed = previous_speed-speed
	
	previous_speed = speed

func _process(delta):
	if debug and train.current:
		$Label.text = "Speed: %.2f km/h\n" % (speed * 3.6)
		$Label.text += "Del Speed: %f\n" % (del_speed)
		$Label.text += "Squeaking: %s\n" % str(squeaking)
		$Label.text += "Squeal Playing: %s\n" % str($Sounds/Squeal.playing)
		$Label.text += "Squeal Sound: %s\n" % str($Sounds/Squeal.unit_db)
		$Label.text += "Brake: %s\n" % str(brake)
		$Label.text += "FPS: %s\n" % str(Engine.get_frames_per_second())

func _on_Couplers_area_entered(area):
	if train.joints.has([self, area.get_parent()]):
		return
	if train != area.get_parent().train:
		print(train, area.get_parent().train)
		train.call_deferred('couple', area.get_parent().train)
#	prints(name, "front", area, $Couplers)
	train.call_deferred('join', self, area.get_parent())
#	print(train.joints)


func _on_Couplers2_area_entered(area):
	if train.joints.has([area.get_parent(), self]):
		return
	if train != area.get_parent().train:
		print(train, area.get_parent().train)
		area.get_parent().train.call_deferred('couple', train)
#	prints(name, "back", area, $Couplers2)
	train.join(self, area.get_parent())
#	print(train.joints)
	
