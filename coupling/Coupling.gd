tool
extends Spatial

export var node_a: NodePath setget set_node_a
export var node_b: NodePath setget set_node_b

func _ready():
	set("node_a", node_a)
	set("node_b", node_b)

func set_node_a(value):
	node_a = value
	if !is_inside_tree():
		return
	var node = get_node_or_null(node_a)
	for child in get_children():
		if ClassDB.is_parent_class(child.get_class(), "Joint"):
			if node:
				child.set("nodes/node_a", node.get_path())
			else:
				child.set("nodes/node_a", null)

func set_node_b(value):
	node_b = value
	if !is_inside_tree():
		return
	var node = get_node_or_null(node_b)
	for child in get_children():
		if ClassDB.is_parent_class(child.get_class(), "Joint"):
			if node:
				child.set("nodes/node_b", node.get_path())
			else:
				child.set("nodes/node_b", null)
