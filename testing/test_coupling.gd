tool
extends Spatial

export var distance_tolerance: float = 9.8

export var consist_np: NodePath setget set_consist_np
export var joints_np: NodePath setget set_joints_np
export var coupling_np: NodePath setget set_coupling_np


var consist: Spatial
var coupling: Spatial
var joints: Spatial


func _get_tool_buttons():
	return ['create_joints', 'delete_joints']

func create_joints():
	print("Creating joints!")
	var prev_wagon = consist.get_child(0)
	for wagon in consist.get_children():
		if prev_wagon == wagon:
			continue
		var dist = prev_wagon.global_transform.origin.distance_to(wagon.global_transform.origin)
		if dist < distance_tolerance:
			var new_coupling = coupling.duplicate()
			joints.add_child(new_coupling)
			new_coupling.owner = self
			new_coupling.node_a = new_coupling.get_path_to(prev_wagon)
			new_coupling.node_b = new_coupling.get_path_to(wagon)
		prev_wagon = wagon

func delete_joints():
	print("Deleting joints!")
	for child in joints.get_children():
		child.queue_free()
	
func set_consist_np(value: NodePath):
	consist_np = value
	consist = get_node_or_null(consist_np)

func set_joints_np(value: NodePath):
	joints_np = value
	joints = get_node_or_null(joints_np)

func set_coupling_np(value: NodePath):
	coupling_np = value
	coupling = get_node_or_null(coupling_np)
