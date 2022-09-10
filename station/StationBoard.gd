tool
extends Spatial

export(String, MULTILINE) var text: String setget set_text

func _ready():
	set("text", text)

func set_text(value: String):
	if !is_inside_tree():
		return
	text = value
	$MeshInstance/Label3D.text = value
	$MeshInstance/Label3D2.text = value
	
