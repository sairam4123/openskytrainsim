extends Node

var routes = {}

func register_route(route_name, route):
	routes[route_name] = route

func get_route(route_name):
	return routes.get(route_name)
