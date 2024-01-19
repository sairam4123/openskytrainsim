extends Spatial

export var route_name: String
export var max_speed: int
export var station_layout_reversed: bool = false

func get_stations():
	return $"%Stations".get_children()
