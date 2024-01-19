tool
extends Spatial

export var flip = true setget set_flip_right

func set_flip_right(val: bool):
	flip = val
	if is_inside_tree():
		$Sign.rotation.y = PI * int(flip)
