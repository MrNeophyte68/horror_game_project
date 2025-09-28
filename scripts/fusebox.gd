extends Node3D

@onready var inspect_target := $InspectTarget  # A Marker3D inside fusebox
var player_camera: Camera3D
var original_camera_transform: Transform3D
var tween: Tween
var inspecting := false
var opened := false
var can_exit = false

@onready var interactable := $fuse_box_etx_1/Interactable
var meshes := []
var selected_index := 0
var is_rotating = false

func _ready():
	# Get the actual camera node inside the player
	player_camera = get_node("/root/Level/Player/head/eyes/Camera3D")
	meshes = interactable.get_children()
	
func handle_input():
	if is_rotating:
		return  # Don't allow selection or rotation while tweening
		
	# Selection logic with WASD
	if Input.is_action_just_pressed("move_right"):
		change_selection(1)
	elif Input.is_action_just_pressed("move_left"):
		change_selection(-1)
	elif Input.is_action_just_pressed("move_forward"):
		change_selection(-3)
	elif Input.is_action_just_pressed("move_backward"):
		change_selection(3)

	# Rotate current mesh with E
	if Input.is_action_just_pressed("interact"):  # 'E' key
		rotate_selected()

func change_selection(delta: int):
	unhighlight_selected()
	selected_index = (selected_index + delta) % meshes.size()
	highlight_selected()

func highlight_selected():
	var mesh = meshes[selected_index]
	if mesh and mesh.has_node("HighlightMesh"):
		mesh.get_node("HighlightMesh").visible = true

func unhighlight_selected():
	var mesh = meshes[selected_index]
	if mesh and mesh.has_node("HighlightMesh"):
		mesh.get_node("HighlightMesh").visible = false

func rotate_selected():
	if is_rotating:
		return  # Prevent rotation while already rotating

	var mesh = meshes[selected_index]
	if not mesh:
		return

	is_rotating = true  # Lock input
	unhighlight_selected()  # Hide highlight while rotating
	can_exit = false

	var current_rotation = mesh.rotation_degrees
	var target_rotation = current_rotation + Vector3(0, 90, 0)

	var tween = create_tween()
	tween.tween_property(
		mesh, "rotation_degrees",
		target_rotation,
		2.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Pass the rotated mesh as an argument to re-highlight it later
	tween.connect("finished", Callable(self, "_on_rotation_finished"))

func _on_rotation_finished():
	is_rotating = false
	can_exit = true
	if inspecting:
		highlight_selected()


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
		unhighlight_selected()
	else:
		enter_inspect_mode()
		await get_tree().create_timer(0.8, false).timeout
		highlight_selected()

func enter_inspect_mode():
	if inspecting:
		return
	inspecting = true

	original_camera_transform = player_camera.global_transform

	var player = get_node("/root/Level/Player")
	var raycast = get_node("/root/Level/Player/head/RayCast3D")
	player.can_move = false
	player.can_sprint = false
	raycast.enabled = false
	

	tween = create_tween()
	tween.tween_property(
		player_camera, "global_transform",
		inspect_target.global_transform,
		0.8
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.connect("finished", Callable(self, "_on_tween_finished_enter"))

func _on_tween_finished_enter():
	can_exit = true


func exit_inspect_mode():
	if not inspecting:
		return
	inspecting = false

	tween = create_tween()
	tween.tween_property(
		player_camera, "global_transform",
		original_camera_transform,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.connect("finished", Callable(self, "_on_tween_finished_exit"))

func _on_tween_finished_exit():
	var player = get_node("/root/Level/Player")
	var raycast = get_node("/root/Level/Player/head/RayCast3D")
	raycast.enabled = true
	player.can_move = true
	player.can_sprint = true

func _process(delta: float) -> void:
	if inspecting and can_exit:
		if Input.is_action_just_pressed("interact2"):
			can_exit = false
			try_inspect()
		
		handle_input()
