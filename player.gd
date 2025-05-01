extends CharacterBody3D


var SPEED = 5.0
const JUMP_VELOCITY = 4.5

#Assume that the default sensitivity is 50%, divide 50 by 50,000 and thats the sensitivity :) (it would equal 0.001)
var sensitivity = 0.001

@onready var debugMenu = $DebugCanvasLayer
var debug_enabled = false

@onready var Camera = $Camera3D
@onready var NameLabel = $Name

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var raycast = $Camera3D/RayCast3D
@onready var grab_anchor = $Camera3D/SpringArm3D/Grabber
var grabbing = false

var grabbed_object: RigidBody3D = null

@onready var object_name_label = $ObjectNameLabel

func _ready():
	if is_multiplayer_authority():
		# Hide the player mesh for the local player (only they won't see themselves)
		self.visible = false
	
	var player_name = Steam.getFriendPersonaName(Steam.getSteamID())
	NameLabel.text = player_name

func _unhandled_input(event):
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		Camera.rotate_x(-event.relative.y * sensitivity)
		Camera.rotation.x = clamp(Camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	
	# DEBUG MENU STUFF RAAAAHHHHHHHHHHHHHHH
	# DEBUG MENU STUFF RAAAAHHHHHHHHHHHHHHH
	# DEBUG MENU STUFF RAAAAHHHHHHHHHHHHHHH
	# DEBUG MENU STUFF RAAAAHHHHHHHHHHHHHHH
	# DEBUG MENU STUFF RAAAAHHHHHHHHHHHHHHH
	# REMOVE BEFORE RELEASE!!!
	
	if Input.is_action_just_pressed("debug"):
		debug_enabled = !debug_enabled
		debugMenu.visible = debug_enabled
	
	$DebugCanvasLayer/DebugPanel/FPS.text = "FPS: " + str(Engine.get_frames_per_second()) + "\n"
	
	if grabbing == true:
		$DebugCanvasLayer/DebugPanel/Grabbing.text = "Grabbing = true"
	if grabbing == false:
		$DebugCanvasLayer/DebugPanel/Grabbing.text = "Grabbing = false"
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if raycast.is_colliding():
		var body = raycast.get_collider()
		if body.has_method("get") and "object" in body:
				object_name_label.text = str(body.get("object"))
		else:
			object_name_label.text = ""
	
	if not raycast.is_colliding():
		object_name_label.text = ""
	
	
	
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	if raycast.is_colliding() and grabbing == false:
		var body = raycast.get_collider()
		if body is RigidBody3D:
			$MuttsCursor.self_modulate = "ffff00"
	
	if not raycast.is_colliding() and grabbing == false:
		$MuttsCursor.self_modulate = "ffffff73"
	
	if grabbing == true:
		$MuttsCursor.self_modulate = "00ff00"
	
	
	
	if Input.is_action_just_pressed("lmb"):
		if grabbed_object:
			_release_object()
		else:
			_try_grab()

	if grabbed_object:
		_drag_object(delta)

func _try_grab():
	if raycast.is_colliding():
		var body = raycast.get_collider()
		if body is RigidBody3D:
			grabbing = true
			grabbed_object = body
			grabbed_object.freeze = false
			grabbed_object.gravity_scale = 1.0

func _release_object():
	grabbed_object = null
	grabbing = false
	object_name_label.text = ""

func _drag_object(delta):
	var target_pos = grab_anchor.global_transform.origin
	var current_pos = grabbed_object.global_transform.origin
	var direction = target_pos - current_pos
	var force = direction * 40.0 - grabbed_object.linear_velocity * 6.0  # spring + damping
	grabbed_object.apply_central_force(force)
