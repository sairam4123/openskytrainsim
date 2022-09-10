extends Spatial

export var route_name: String
export var max_speed: int

func get_stations():
	return $"%Stations".get_children()
