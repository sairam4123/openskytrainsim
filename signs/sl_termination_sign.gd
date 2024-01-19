tool
extends Spatial

enum TerminationType {
	ALL,
	PASSENGER,
	GOODS
}

var type_dict = {
	TerminationType.PASSENGER: "P",
	TerminationType.GOODS: "G"
}

export(TerminationType) var termination_type = TerminationType.ALL setget set_term_type

func _ready():
	set_term_type(termination_type)

func set_term_type(type):
	termination_type = type
	if !is_inside_tree():
		return
	$MeshInstance.hide()
	$MeshInstanceSplit.hide()
	
	if type in [TerminationType.PASSENGER, TerminationType.GOODS]:
		$MeshInstanceSplit.show()
		$MeshInstanceSplit/Label3D3.text = type_dict[type]
		$MeshInstanceSplit/Label3D5.text = type_dict[type]
	elif type == TerminationType.ALL:
		$MeshInstance.show()
		return
