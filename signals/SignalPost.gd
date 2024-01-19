tool
extends Spatial

enum SignalType {
	Distant,
	Home,
	Starter
}

enum Direction {
	FORWARD = 1, BACKWARD = -1
}

export(NodePath) var next_signal_np setget set_next_np

enum SignalState {
	ATTENTION = 0, CAUTION = 1, PROCEED = 2, STOP = 3
}

export(Direction) var direction = Direction.FORWARD 

var _signal_state = SignalState.STOP setget set_sig_state
export(SignalType) var signal_type = SignalType.Distant setget set_sig_type

var signal_inst = null

func _ready():
	set_sig_type(signal_type)
#	set_sig_state(_signal_state)

func set_sig_type(val):
	signal_type = val
	if !is_inside_tree():
		return

	
	$Signal.hide()
	$Signal2.hide()
	$Signal3.hide()
	match val:
		SignalType.Distant:
			signal_inst = $Signal
			$Signal.show()
		SignalType.Home:
			signal_inst = $Signal2
			$Signal2.show()
		SignalType.Starter:
			signal_inst = $Signal3
			$Signal3.show()
	set_sig_state(_signal_state)
	property_list_changed_notify()

func set_next_np(value):
	next_signal_np = value
	if !signal_inst:
		return
	signal_inst.next_signal_np = next_signal_np

func set_sig_state(value):
	_signal_state = value
	if !signal_inst:
		return false
	signal_inst.signal_state = value
	return true
	
func _get_property_list():
	var props = []
	props.append({
		"name": "signal_state",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint_string": _to_hint_string(signal_inst.SignalState if signal_inst else SignalState)
	})
	return props

func _to_hint_string(enum_):
	var str_ = ""
	for key in enum_.keys():
		str_ += key.capitalize()+":"+str(enum_[key])
		str_ += ","
	return str_.rstrip(",")

func _get(property):
	match property:
		"signal_state":
			if !signal_inst:
				return _signal_state
			return signal_inst.signal_state

func _set(property, value):
	match property:
		"signal_state":
			return set_sig_state(value)
	return false


func _on_Area_body_entered(body):
	if body.is_in_group("engine"):
		set_sig_state(signal_inst.SignalState.STOP)
