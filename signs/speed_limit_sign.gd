tool
extends Spatial

var font_sizes = {
	0: 128,
	1: 106,
	2: 84,
	3: 62,
	4: 41
}

export(String, MULTILINE) var text: String setget set_text
export(bool) var hide_station_board = false setget set_hide_board

func _ready():
	set("text", text)
	set("hide_station_board", hide_station_board)

func set_text(value: String):
	if !is_inside_tree():
		return
	text = value
	$MeshInstance/Label3D.text = value
	$MeshInstance/Label3D2.text = value
	($MeshInstance/Label3D.font as DynamicFont).size = font_sizes[len(value)]
	
	
func set_hide_board(value):
	hide_station_board = value
	if !is_inside_tree():
		return
	$MeshInstance.visible = !value
