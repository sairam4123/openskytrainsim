extends Spatial


export(PackedScene) var train

func _ready():
	get_tree().connect("network_peer_connected", self, "create_player")
	get_tree().connect("network_peer_disconnected", self, "delete_player")
	get_tree().connect("connected_to_server", self, "joined_server")
	get_tree().connect("server_disconnected", self, "server_disconnected")
	
	if get_tree().is_network_server():
		var player = create_player(get_tree().get_network_unique_id())
		$"../Control/Panel".train = player
		$"../Control/TrainOperations".train = player
		OS.set_window_title("OpenSkyTrainSim Server")
	else:
		OS.set_window_title("OpenSkyTrainSim Client")

remotesync func create_player(id: int):
	var player: Spatial = train.instance()
	Players.players[id] = player
	player.nick_name = get_tree().get_meta("player_name")
	player.name = str(id)
	player.set_network_master(id)
	add_child(player)
	prints(id, "joined the world.")
	return player

func delete_player(id: int):
	var player = Players.players[id]
	player.queue_free()
	Players.players.erase(id)
	prints(id, "left the world.")

func joined_server():
	print("Joining server")
	var id = get_tree().get_network_unique_id()
	if not Players.players.has(id):
		create_player(id)
	print(get_tree().get_network_connected_peers())
	for peer in get_tree().get_network_connected_peers():
		if not Players.players.has(peer) and peer != id:
			create_player(peer)

func server_disconnected():
	print("Server disconnected")
	delete_player(get_tree().get_network_unique_id())
	for peer in get_tree().get_network_connected_peers():
		delete_player(peer)
	get_tree().change_scene("res://Lobby.tscn")

func get_position_to_spawn(station = null):
	return get_parent().get_position_to_spawn(station)
