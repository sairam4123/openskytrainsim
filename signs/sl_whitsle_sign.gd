tool
extends Spatial

enum WhitsleType {
	ALL,
	LEVEL_CROSSING
}


export(WhitsleType) var whitlsle_type = WhitsleType.ALL setget set_whitsle_type

func _ready():
	set_whitsle_type(whitlsle_type)

func set_whitsle_type(type):
	whitlsle_type = type
	if !is_inside_tree():
		return
	$MeshInstance2.hide()
	$MeshInstanceSplit2.hide()
	$MeshInstance.hide()
	$MeshInstanceSplit.hide()
	
	if type == WhitsleType.LEVEL_CROSSING:
		$MeshInstanceSplit.show()
		$MeshInstanceSplit2.show()
	elif type == WhitsleType.ALL:
		$MeshInstance.show()
		$MeshInstance2.show()
		
