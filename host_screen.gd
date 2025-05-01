extends Control

var Map = "Bowling"

@onready var lobby_id

func _ready() -> void:
	pass

func _process(delta):
	if Map == "Bowling":
		$CurrentMap.text = "Current Map: BOWLING"
	
	if Map == "Store":
		$CurrentMap.text = "Current Map: STORE"
	
	var Players = Network.lobby_members
	var text := ""
	for member in Players:
		text += str(member["steam_name"]) + "\n"
		$PlayerListLabel.text = text
	
	$LobbyID.text = str(Network.lobby_id)


func _on_bowling_pressed() -> void:
	Map = "Bowling"


func _on_store_pressed() -> void:
	Map = "Store"


func _on_start_pressed() -> void:
	# Tell all players to load the selected map
	Network.send_p2p_packet(0, {
		"message": "start_game",
		"map": Map
	})
	
	# Also change the host's own scene
	Network.load_game(Map)
