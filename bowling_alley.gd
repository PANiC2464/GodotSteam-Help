extends Node3D

@onready var player_scene = preload("res://Scenes/player.tscn")
@onready var multiplayer_spawner = $MultiplayerSpawner

func _ready() -> void:
	if multiplayer.is_server():
		var player = load("res://Scenes/player.tscn").instantiate()
		player.set_multiplayer_authority(multiplayer.get_unique_id())
		add_child(player)
	
	# Connect the player spawned signal
	connect_player_spawner()

func connect_player_spawner():
	# When a player connects
	# spawn a player instance on the server
	multiplayer.peer_connected.connect(_on_new_peer_connected)

func _on_new_peer_connected(_peer_id):
	# Tell all clients to spawn a player instance
	spawn_player()

func spawn_player():
	# Spawn the player on all connected peers
	rpc("spawn_player_on_all_peers")

@rpc("any_peer")
func spawn_player_on_all_peers():
	# Spawn a player instance for the current peer
	var new_player = player_scene.instantiate()  # Instantiate the player scene
	multiplayer_spawner.add_child(new_player)  # add as child of multiplayer spawner
	new_player.set_owner(get_tree().get_network_peer().get_network_peer_id())  # Set the owner
