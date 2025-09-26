extends Node3D

@onready var inspect_target := $InspectTarget  # A Marker3D inside fusebox
var player_camera: Camera3D
var original_camera_transform: Transform3D
var tween: Tween
var inspecting := false
var opened := false

func _ready():
	# Get the actual camera node inside the player
	player_camera = get_node("/root/Level/Player/head/eyes/Camera3D")

func toggle_door():
	if $AnimationPlayer.is_playing():
		return
	opened = !opened
	if opened:
		$AnimationPlayer.play("open")
	else:
		$AnimationPlayer.play_backwards("open")

func try_inspect():
	if not opened:
		return

	if inspecting:
		exit_inspect_mode()
	else:
		enter_inspect_mode()

func enter_inspect_mode():
	if inspecting:
		return
	inspecting = true

	# Save original transform so we can return later
	original_camera_transform = player_camera.global_transform

	# Disable player movement
	var player = get_node("/root/Level/Player")
	player.can_move = false

	# Tween to the inspect view
	tween = create_tween()
	tween.tween_property(
		player_camera, "global_transform", 
		inspect_target.global_transform, 
		0.8
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	print("Entered inspect mode")

func exit_inspect_mode():
	if not inspecting:
		return
	inspecting = false

	# Re-enable movement
	var player = get_node("/root/Level/Player")
	player.can_move = true

	# Tween back to original camera position
	tween = create_tween()
	tween.tween_property(
		player_camera, "global_transform", 
		original_camera_transform, 
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	print("Exited inspect mode")
