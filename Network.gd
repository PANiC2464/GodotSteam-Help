extends Node

const PACKET_READ_LIMIT: int = 32

var is_host: bool = false
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 6

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.p2p_session_request.connect(_on_p2p_session_request)

func _process(delta: float) -> void:
	if lobby_id > 0:
		read_all_p2p_packets()

func create_lobby():
	if lobby_id == 0:
		is_host = true
		Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, lobby_members_max)
		

func _on_lobby_created(connect: int, this_lobby_id: int):
	if connect == 1:
		lobby_id = this_lobby_id
		
		Steam.setLobbyJoinable(lobby_id, true)
		
		Steam.setLobbyData(lobby_id, "name", "Game Lobby")
		
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		
		get_tree().change_scene_to_file("res://Menus/host_screen.tscn")

func join_lobby(this_lobby_id: int):
	Steam.joinLobby(this_lobby_id)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		
		get_lobby_members()
		make_p2p_handshake()
		
		# Change scene once successfully joined
		get_tree().change_scene_to_file("res://Menus/host_screen.tscn")
	else:
		# Joining failed!
		# Go back to the main menu and show an error message
		var main_menu = get_tree().current_scene
		
		if main_menu.has_node("StatusLabel"):
			main_menu.get_node("StatusLabel").text = "Uh-Oh! That lobby doesn't exist!"

func get_lobby_members():
	lobby_members.clear()
	
	var num_of_lobby_members: int = Steam.getNumLobbyMembers(lobby_id)
	
	for member in range(0, num_of_lobby_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		
		lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name})
		
		

func send_p2p_packet(this_target: int, packet_data: Dictionary, send_type: int = 0):
	var channel: int = 0
	
	var this_data: PackedByteArray
	this_data.append_array(var_to_bytes(packet_data))
	
	if this_target == 0:
		if lobby_members.size() > 1:
			for member in lobby_members:
				if member['steam_id'] != Global.steam_id:
					Steam.sendP2PPacket(member['steam_id'], this_data, send_type, channel)
	else:
		Steam.sendP2PPacket(this_target, this_data, send_type, channel)

func _on_p2p_session_request(remote_id: int):
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	
	Steam.acceptP2PSessionWithUser(remote_id)

func make_p2p_handshake():
	send_p2p_packet(0, {"message" : "handshake", "steam_id" : Global.steam_id, "username" : Global.steam_username})

func read_all_p2p_packets(read_count: int = 0):
	if read_count >= PACKET_READ_LIMIT:
		return
	
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count + 1)

func read_p2p_packet():
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)
		
		var packet_sender: int = this_packet['remote_steam_id']
		
		var packet_code: PackedByteArray = this_packet['data']
		var readable_data: Dictionary = bytes_to_var(packet_code)
		
		if readable_data.has("message"):
			match readable_data["message"]:
				"handshake":
					print("PLAYER: ", readable_data["username"], " HAS JOINED!")
					get_lobby_members()
				
				"start_game":
					Network.load_game(readable_data["map"])
				
				"set_player_name":
					var new_name = readable_data["name"]
					set_player_name(new_name)  # Update the player's name on this client

func load_game(map_name: String) -> void:
	match map_name:
		"Bowling":
			get_tree().change_scene_to_file("res://Levels/BowlingAlleys/bowling_alley.tscn")
		"Store":
			get_tree().change_scene_to_file("res://Levels/Stores/grocery_store_1.tscn")
		_:
			push_error("Unknown map: " + map_name)

func send_player_name_to_all_clients(name: String):
	var name_data = {"message": "set_player_name", "name": name}
	send_p2p_packet(0, name_data)  # Send the packet to all clients

func set_player_name(name: String):
	# Assuming `Label3D` is the name of the label node above the player
	var label_3d = $Name  # Assuming `Label3D` is a direct child of the player
	label_3d.text = name  # Update the text with the received name
