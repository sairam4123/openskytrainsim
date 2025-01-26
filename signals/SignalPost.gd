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

export(NodePath) var prev_signal_np setget set_prev_np
export(NodePath) var next_signal_np setget set_next_np

enum SignalState {
	ATTENTION = 0, CAUTION = 1, PROCEED = 2, STOP = 3
}

export(Direction) var direction = Direction.FORWARD 

var _signal_state = SignalState.STOP setget set_sig_state
export(SignalType) var signal_type = SignalType.Distant setget set_sig_type

export(bool) var is_automatic = false
var _section_occupied = false setget set_section_occupied

var signal_inst = null

func _ready():
	set_sig_type(signal_type)
#	set_next_np(next_signal_np)
#	set_sig_state(_signal_state)

func set_sig_type(val):
	signal_type = val
	if !is_inside_tree():
		return
	# Automatic signal handling (automatic in IR world)
	if is_automatic:
		signal_type = SignalType.Distant
	
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
	set_next_np(next_signal_np)
	set_prev_np(prev_signal_np)
	_update()
	property_list_changed_notify()

func set_next_np(value):
	print("set next np", signal_inst, next_signal_np)
	next_signal_np = value
	if !signal_inst:
		return
	signal_inst.next_signal_np = next_signal_np

func set_sig_state(value):
	_signal_state = value
	if !signal_inst:
		return false
	signal_inst.signal_state = value
	
	var prev_signal = get_node_or_null(prev_signal_np)
	if not prev_signal:
		return
	prev_signal._update()
	
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

func set_prev_np(value):
	prev_signal_np = value
	if !signal_inst:
		return

func _update():
	if not next_signal_np:
		print("Next signal not set.")
		return
	var next_signal = get_node_or_null(next_signal_np)
	if not next_signal:
		print("Next signal does not exist.")
		return
	if not next_signal.signal_inst:
		print("Next signal not initialzied.")
		return
	
	if not signal_inst:
		print("Signal not initialized.")
		return
	
	if _section_occupied:
		return
	
	match signal_type:
		SignalType.Distant:
			match next_signal.signal_inst.signal_state:
				next_signal.SignalState.CAUTION:
					set_sig_state(signal_inst.SignalState.ATTENTION)
				next_signal.SignalState.STOP:
					set_sig_state(signal_inst.SignalState.CAUTION)
				next_signal.SignalState.ATTENTION:
					if next_signal.signal_type == next_signal.SignalType.Distant and not is_automatic:
						set_sig_state(signal_inst.SignalState.ATTENTION)
					else:
						set_sig_state(signal_inst.SignalState.PROCEED)
				next_signal.SignalState.PROCEED:
					set_sig_state(signal_inst.SignalState.PROCEED)
		SignalType.Home:
			match next_signal.signal_inst.signal_state:
				next_signal.SignalState.STOP:
					set_sig_state(signal_inst.SignalState.CAUTION)
					print("Caution needs to be shown.")
				next_signal.SignalState.PROCEED:
					set_sig_state(signal_inst.SignalState.PROCEED)
				_:
					set_sig_state(signal_inst.SignalState.PROCEED)
		SignalType.Starter:
			match next_signal.signal_inst.signal_state:
				next_signal.SignalState.STOP:
					set_sig_state(signal_inst.SignalState.STOP)
				next_signal.SignalState.PROCEED:
					set_sig_state(signal_inst.SignalState.PROCEED)
#
#func _process(delta):
#	_update()

func set_section_occupied(value: bool):
	_section_occupied = value
	if _section_occupied:
		set_sig_state(signal_inst.SignalState.STOP)
	else:
		_update()

func _on_Area_body_entered(body):
	if body.is_in_group("engine"):
		self._section_occupied = true
		set_sig_state(signal_inst.SignalState.STOP)
		
		var prev_signal = get_node_or_null(prev_signal_np)
		if prev_signal:
			prev_signal.set_section_occupied(false)
		
		
