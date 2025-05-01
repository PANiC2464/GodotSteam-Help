extends Control

@onready var lobby_id = $LobbyID

# Called when the node enters the scene tree for the first time.
func _ready():
	Steam.steamInit()
	
	if Steam.steamInit():
		print("Steam initialized successfully!")
	else:
		push_error("Steam failed to initialize!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_host_pressed():
	Network.create_lobby()
	#get_tree().change_scene_to_file("res://Menus/host_screen.tscn")


func _on_join_pressed() -> void:
	var id: int = int(lobby_id.text)
	
	if $StatusLabel.text == "":
		$StatusLabel.text = "Please enter a Lobby ID!"
	
	else:
		$StatusLabel.text = "Joining Lobby..." # <--- update status
		Network.join_lobby(id)
