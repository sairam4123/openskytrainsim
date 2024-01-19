tool
extends Area


export var speed_limit = 50 setget set_speed# KMPH
export var end_speed_limit = 250 setget set_end_sl # KMPH

## READONLY
export var extents: Vector3 setget , get_extents

func _ready():
	set_speed(speed_limit)
	set_end_sl(end_speed_limit)
	add_to_group("speed_limit")


func get_extents():
	return ($CollisionShape.shape as BoxShape).extents

func set_speed(val):
	speed_limit = val
	if not is_inside_tree():
		return
	$SpeedSign.text = str(val)
	$SpeedSign2.text = str(val)

func set_end_sl(val):
	end_speed_limit = val
	if not is_inside_tree():
		return
