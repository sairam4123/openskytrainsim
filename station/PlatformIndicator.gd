tool
extends MeshInstance

export var platform_number: int = 1 setget set_platform_number

func set_platform_number(value: int):
	$Label3D.text = "PF " + str(value)
	$Label3D2.text = "PF " + str(value)
	platform_number = value
