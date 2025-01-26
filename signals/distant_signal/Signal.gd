tool
extends CSGCombiner

signal state_changed

const signal_material = preload("res://materials/SignalMaterial.tres")

enum SignalState {
	ATTENTION = 0, CAUTION = 1, PROCEED = 2, STOP = 3
}



export(NodePath) var next_signal_np setget set_next_signal
onready var next_signal = get_node_or_null(next_signal_np)

export(NodePath) var previous_signal_np
onready var previous_signal = get_node_or_null(previous_signal_np)

export(SignalState) var signal_state = SignalState.STOP setget set_state

func set_state(value):
	signal_state = value
	if !is_inside_tree():
		return
	$SignalBox/AttentionLight.material = signal_material
	$SignalBox/ProceedLight.material = signal_material
	$SignalBox/CautionLight.material = signal_material
	$SignalBox/StopLight.material = signal_material
	
	$SignalBox/AttentionLight/OmniLight.hide()
	$SignalBox/ProceedLight/OmniLight.hide()
	$SignalBox/CautionLight/OmniLight.hide()
	$SignalBox/StopLight/OmniLight.hide()
	
	match signal_state:
		SignalState.ATTENTION:
			$SignalBox/AttentionLight.material = preload("res://materials/AttentionLightMaterial.tres")
			$SignalBox/AttentionLight/OmniLight.show()
			
			$SignalBox/CautionLight.material = preload("res://materials/CautionLightMaterial.tres")
			$SignalBox/CautionLight/OmniLight.show()
		
		SignalState.CAUTION:
			$SignalBox/CautionLight.material = preload("res://materials/CautionLightMaterial.tres")
			$SignalBox/CautionLight/OmniLight.show()
		
		SignalState.PROCEED:
			$SignalBox/ProceedLight.material = preload("res://materials/ProceedLightMaterial.tres")
			$SignalBox/ProceedLight/OmniLight.show()
		
		SignalState.STOP:
			$SignalBox/StopLight.material = preload("res://materials/StopLightMaterial.tres")
			$SignalBox/StopLight/OmniLight.show()


func set_next_signal(val):
	next_signal_np = val
	next_signal = get_node_or_null(val)
	
#	update()
#
#func _process(delta):
#	update()
#
#func update():
#	print("updating..", signal_state, next_signal)
#	if next_signal:
#		match next_signal.signal_state:
#			next_signal.SignalState.CAUTION:
#				self.signal_state = SignalState.ATTENTION
#			next_signal.SignalState.STOP:
#				self.signal_state = SignalState.CAUTION
#			SignalState.ATTENTION:
#				self.signal_state = SignalState.PROCEED
#			next_signal.SignalState.PROCEED:
#				self.signal_state = SignalState.PROCEED


#func _ready():
#	set("signal_state", signal_state)
