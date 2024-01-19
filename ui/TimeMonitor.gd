extends Panel


func _process(delta):
	$Label.text = "Time: %02d:%02d:%02d" % [TimeManager.hour, TimeManager.minute, TimeManager.secs]
