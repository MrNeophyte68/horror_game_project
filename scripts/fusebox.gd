extends Node3D

# === Camera & Inspection ===
@onready var inspect_target := $InspectTarget
@onready var inspect_target_fuses := $InspectTarget2
var player_camera: Camera3D
var original_camera_transform: Transform3D
var tween: Tween
var inspecting := false
var opened := false
var can_exit = false
var inspecting_fuses := false

# === Interaction & Rotation ===
@onready var interactable := $fuse_box_etx_1/Interactable
var meshes := []
var selected_index := 0
var selected_index_fuses := 0
var is_rotating = false

# === Fuse Inventory ===
@onready var fuse_list = get_node("/root/Level/Player/head/RayCast3D")

@onready var highlight = [$fuse_box_etx_1/connect/start/HighlightMesh, $fuse_box_etx_1/connect/end/HighlightMesh, $fuse_box_etx_1/Interactable/straight/HighlightMesh,
	$fuse_box_etx_1/Interactable/corner/HighlightMesh, $fuse_box_etx_1/Interactable/corner2/HighlightMesh, $fuse_box_etx_1/Interactable/straight2/HighlightMesh,
	$fuse_box_etx_1/Interactable/corner3/HighlightMesh, $fuse_box_etx_1/Interactable/corner4/HighlightMesh, $fuse_box_etx_1/Interactable/straight3/HighlightMesh]

@onready var mesh_list: Array[MeshInstance3D] = [
		$fuse_box_etx_1/locations/location0,
		$fuse_box_etx_1/locations/location1,
		$fuse_box_etx_1/locations/location2,
		$fuse_box_etx_1/locations/location3,
		$fuse_box_etx_1/locations/location4,
		$fuse_box_etx_1/locations/location5,
		$fuse_box_etx_1/locations/location6,
		$fuse_box_etx_1/locations/location7,
		$fuse_box_etx_1/locations/location8
	]

@onready var highlight_fuse = [$highlight_fuses/FuseGreen2, $highlight_fuses/FuseYellow2, $highlight_fuses/FuseBlue2, $highlight_fuses/FuseRed2]
var blueFuse = false
var redFuse = false
var yellowFuse = false
var greenFuse = false
var allFuses = false
@onready var mesh_list_fuses = [$fuses/FuseGreen, $fuses/FuseYellow, $fuses/FuseBlue, $fuses/FuseRed]
var swap_targets = []
var counter = 0
var wire_check #check if player put right combination
var wire_finished: bool = false #true if player put right combination
var fuse_finished: bool = false
var set_fuse_comb: int = randi_range(1, 4)

#elevator
@onready var elevator = get_tree().root.get_node("Level/map/Elevator")
var played_once := false

func _ready():
	randomize()
	# Setup the random path first
	_setup_random_path()

	# Initialize camera & meshes
	player_camera = get_node("/root/Level/Player/head/eyes/Camera3D")
	#meshes = interactable.get_children()

	# Show any fuses the player already has
	fuse_visible()

func fuse_visible():
	if "blue_fuse" in fuse_list.fuse_check:
		$fuses/FuseBlue.visible = true
		blueFuse = true
	if "red_fuse" in fuse_list.fuse_check:
		$fuses/FuseRed.visible = true
		redFuse = true
	if "yellow_fuse" in fuse_list.fuse_check:
		$fuses/FuseYellow.visible = true
		yellowFuse = true
	if "green_fuse" in fuse_list.fuse_check:
		$fuses/FuseGreen.visible = true
		greenFuse = true

func _process(_delta: float) -> void:
	if blueFuse and redFuse and yellowFuse and greenFuse:
		allFuses = true

	if inspecting and can_exit:
		if Input.is_action_just_pressed("interact2"):
			can_exit = false
			try_inspect()
		handle_input()

	if inspecting_fuses and can_exit:
		if Input.is_action_just_pressed("interact2"):
			can_exit = false
			try_inspect_fuses()
		if !allFuses:
			if Input.is_action_just_pressed("interact"):
				fuse_visible()
		elif allFuses:
			handle_input_fuses()
			
	wire_combination_check()
	if wire_finished:
		var col := get_node_or_null("fuse_box_etx_1/fusebox/CollisionShape3D")
		if col:
			col.queue_free()
		exit_inspect_mode()
		
	fuse_combination_check()
	if fuse_finished:
		var col := get_node_or_null("fuse_box_etx_1/fuses/CollisionShape3D")
		if col:
			col.queue_free()
		exit_inspect_mode_fuses()
	
	if wire_finished and fuse_finished:
		$GPUParticles3D.visible = false
		if not played_once:
			elevator.power_on()
			played_once = true

func handle_input():
	if is_rotating:
		return
	if Input.is_action_just_pressed("move_right"):
		change_selection(1)
	elif Input.is_action_just_pressed("move_left"):
		change_selection(-1)
	#elif Input.is_action_just_pressed("move_forward"):
	#	change_selection(-3)
	#elif Input.is_action_just_pressed("move_backward"):
	#	change_selection(3)
	if Input.is_action_just_pressed("interact"):
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
		return
	var mesh = meshes[selected_index]
	if not mesh:
		return
	is_rotating = true
	unhighlight_selected()
	can_exit = false
	var current_rot = mesh.rotation_degrees
	var target_rot = current_rot + Vector3(0, 90, 0)
	var tw = create_tween()
	tw.tween_property(mesh, "rotation_degrees", target_rot, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.connect("finished", Callable(self, "_on_rotation_finished"))

func _on_rotation_finished():
	is_rotating = false
	can_exit = true

	var mesh = meshes[selected_index]
	if mesh:
		var rd = mesh.rotation_degrees
		# Normalize each axis so it stays within [0, 360)
		rd.x = fposmod(rd.x, 360.0)
		rd.y = fposmod(rd.y, 360.0)
		rd.z = fposmod(rd.z, 360.0)
		mesh.rotation_degrees = rd

	if inspecting:
		highlight_selected()

func try_inspect():
	if not opened:
		return
	if inspecting:
		exit_inspect_mode()
		unhighlight_selected()
	else:
		enter_inspect_mode()
		for mesh in highlight:
			mesh.visible = false
		await get_tree().create_timer(0.8).timeout
		highlight_selected()

func enter_inspect_mode():
	if inspecting:
		return
	inspecting = true
	can_exit = false
	original_camera_transform = player_camera.global_transform
	var player = get_node("/root/Level/Player")
	var raycast = get_node("/root/Level/Player/head/RayCast3D")
	player.can_move = false
	player.can_sprint = false
	raycast.enabled = false
	tween = create_tween()
	tween.tween_property(player_camera, "global_transform", inspect_target.global_transform, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.connect("finished", Callable(self, "_on_tween_finished_enter"))

func _on_tween_finished_enter():
	can_exit = true

func exit_inspect_mode():
	if not inspecting:
		return
	inspecting = false
	tween = create_tween()
	tween.tween_property(player_camera, "global_transform", original_camera_transform, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.connect("finished", Callable(self, "_on_tween_finished_exit"))

func _on_tween_finished_exit():
	var player = get_node("/root/Level/Player")
	var raycast = get_node("/root/Level/Player/head/RayCast3D")
	raycast.enabled = true
	player.can_move = true
	player.can_sprint = true

func toggle_door():
	if $AnimationPlayer.is_playing():
		return
	opened = !opened
	if opened:
		$AnimationPlayer.play("open")
	else:
		$AnimationPlayer.play_backwards("open")

# --- The random layout logic you originally had ---
func _setup_random_path():
	var chosen_location = [0, 4].pick_random()
	
	if chosen_location == 4:
		$fuse_box_etx_1/connect/start.global_position = mesh_list[chosen_location].global_position
		var pick_direction = randi_range(1, 4)
		if pick_direction == 1:
			$fuse_box_etx_1/connect/start.rotation_degrees.y = 0
			var locations = [2, 8]
			var chosen_location_end = locations.pick_random()
			locations.erase(chosen_location_end)
			$fuse_box_etx_1/connect/end.rotation_degrees.y = 0
			$fuse_box_etx_1/connect/end.global_position = mesh_list[chosen_location_end].global_position
			$fuse_box_etx_1/Interactable/corner.global_position = mesh_list[5].global_position
			$fuse_box_etx_1/Interactable/corner2.global_position = mesh_list[locations[0]].global_position
			$fuse_box_etx_1/Interactable/corner3.global_position = mesh_list[0].global_position
			$fuse_box_etx_1/Interactable/corner4.global_position = mesh_list[6].global_position
			$fuse_box_etx_1/Interactable/straight.global_position = mesh_list[1].global_position
			$fuse_box_etx_1/Interactable/straight2.global_position = mesh_list[3].global_position
			$fuse_box_etx_1/Interactable/straight3.global_position = mesh_list[7].global_position
			if chosen_location_end == 2:
				meshes = [$fuse_box_etx_1/Interactable/corner3, $fuse_box_etx_1/Interactable/straight, $fuse_box_etx_1/Interactable/straight2,
				$fuse_box_etx_1/Interactable/corner, $fuse_box_etx_1/Interactable/corner4, $fuse_box_etx_1/Interactable/straight3, $fuse_box_etx_1/Interactable/corner2]
				wire_check = "01011100001"
			else:
				meshes = [$fuse_box_etx_1/Interactable/corner3, $fuse_box_etx_1/Interactable/straight, $fuse_box_etx_1/Interactable/corner2,
				$fuse_box_etx_1/Interactable/straight2, $fuse_box_etx_1/Interactable/corner, $fuse_box_etx_1/Interactable/corner4, $fuse_box_etx_1/Interactable/straight3]
				wire_check = "01010110001"
		elif pick_direction == 2:
			$fuse_box_etx_1/connect/start.rotation_degrees.y = 90
			var locations = [0, 2]
			var chosen_location_end = locations.pick_random()
			locations.erase(chosen_location_end)
			$fuse_box_etx_1/connect/end.rotation_degrees.y = 90
			$fuse_box_etx_1/connect/end.global_position = mesh_list[chosen_location_end].global_position
			$fuse_box_etx_1/Interactable/corner.global_position = mesh_list[1].global_position
			$fuse_box_etx_1/Interactable/corner2.global_position = mesh_list[locations[0]].global_position
			$fuse_box_etx_1/Interactable/corner3.global_position = mesh_list[6].global_position
			$fuse_box_etx_1/Interactable/corner4.global_position = mesh_list[8].global_position
			$fuse_box_etx_1/Interactable/straight.global_position = mesh_list[3].global_position
			$fuse_box_etx_1/Interactable/straight2.global_position = mesh_list[5].global_position
			$fuse_box_etx_1/Interactable/straight3.global_position = mesh_list[7].global_position
			if chosen_location_end == 0:
				meshes = [$fuse_box_etx_1/Interactable/corner, $fuse_box_etx_1/Interactable/corner2, $fuse_box_etx_1/Interactable/straight,
				$fuse_box_etx_1/Interactable/straight2, $fuse_box_etx_1/Interactable/corner3, $fuse_box_etx_1/Interactable/straight3, $fuse_box_etx_1/Interactable/corner4]
				wire_check = "11000110110"
			else:
				meshes = [$fuse_box_etx_1/Interactable/corner2, $fuse_box_etx_1/Interactable/corner, $fuse_box_etx_1/Interactable/straight,
				$fuse_box_etx_1/Interactable/straight2, $fuse_box_etx_1/Interactable/corner3, $fuse_box_etx_1/Interactable/straight3, $fuse_box_etx_1/Interactable/corner4]
				wire_check = "11011000110"
		elif pick_direction == 3:
			$fuse_box_etx_1/connect/start.rotation_degrees.y = 180
			var locations = [0, 6]
			var chosen_location_end = locations.pick_random()
			locations.erase(chosen_location_end)
			$fuse_box_etx_1/connect/end.rotation_degrees.y = 180
			$fuse_box_etx_1/connect/end.global_position = mesh_list[chosen_location_end].global_position
			$fuse_box_etx_1/Interactable/corner.global_position = mesh_list[3].global_position
			$fuse_box_etx_1/Interactable/corner2.global_position = mesh_list[locations[0]].global_position
			$fuse_box_etx_1/Interactable/corner3.global_position = mesh_list[2].global_position
			$fuse_box_etx_1/Interactable/corner4.global_position = mesh_list[8].global_position
			$fuse_box_etx_1/Interactable/straight.global_position = mesh_list[1].global_position
			$fuse_box_etx_1/Interactable/straight2.global_position = mesh_list[5].global_position
			$fuse_box_etx_1/Interactable/straight3.global_position = mesh_list[7].global_position
			if chosen_location_end == 0:
				meshes = [$fuse_box_etx_1/Interactable/straight, $fuse_box_etx_1/Interactable/corner3, $fuse_box_etx_1/Interactable/corner,
				$fuse_box_etx_1/Interactable/straight2, $fuse_box_etx_1/Interactable/corner2, $fuse_box_etx_1/Interactable/straight3, $fuse_box_etx_1/Interactable/corner4]
				wire_check = "01000011110"
			else:
				meshes = [$fuse_box_etx_1/Interactable/corner2, $fuse_box_etx_1/Interactable/straight, $fuse_box_etx_1/Interactable/corner3,
				$fuse_box_etx_1/Interactable/corner, $fuse_box_etx_1/Interactable/straight2, $fuse_box_etx_1/Interactable/straight3, $fuse_box_etx_1/Interactable/corner4]
				wire_check = "01001001110"
		elif pick_direction == 4:
			$fuse_box_etx_1/connect/start.rotation_degrees.y = 270
			var locations = [6, 8]
			var chosen_location_end = locations.pick_random()
			locations.erase(chosen_location_end)
			$fuse_box_etx_1/connect/end.rotation_degrees.y = -90
			$fuse_box_etx_1/connect/end.global_position = mesh_list[chosen_location_end].global_position
			$fuse_box_etx_1/Interactable/corner.global_position = mesh_list[7].global_position
			$fuse_box_etx_1/Interactable/corner2.global_position = mesh_list[locations[0]].global_position
			$fuse_box_etx_1/Interactable/corner3.global_position = mesh_list[0].global_position
			$fuse_box_etx_1/Interactable/corner4.global_position = mesh_list[2].global_position
			$fuse_box_etx_1/Interactable/straight.global_position = mesh_list[1].global_position
			$fuse_box_etx_1/Interactable/straight2.global_position = mesh_list[3].global_position
			$fuse_box_etx_1/Interactable/straight3.global_position = mesh_list[5].global_position
			if chosen_location_end == 6:
				meshes = [$fuse_box_etx_1/Interactable/corner3, $fuse_box_etx_1/Interactable/straight, $fuse_box_etx_1/Interactable/corner4,
				$fuse_box_etx_1/Interactable/straight2, $fuse_box_etx_1/Interactable/straight3, $fuse_box_etx_1/Interactable/corner, $fuse_box_etx_1/Interactable/corner2]
				wire_check = "01101100011"
			else:
				meshes = [$fuse_box_etx_1/Interactable/corner3, $fuse_box_etx_1/Interactable/straight, $fuse_box_etx_1/Interactable/corner4,
				$fuse_box_etx_1/Interactable/straight2, $fuse_box_etx_1/Interactable/straight3, $fuse_box_etx_1/Interactable/corner2, $fuse_box_etx_1/Interactable/corner]
				wire_check = "01110010011"
	elif chosen_location == 0:
		$fuse_box_etx_1/connect/start.global_position = mesh_list[chosen_location].global_position
		var pick_direction = [1, 4].pick_random()
		if pick_direction == 1:
			$fuse_box_etx_1/connect/start.rotation_degrees.y = 0
			var chosen_location_end = [4, 8].pick_random()
			$fuse_box_etx_1/connect/end.global_position = mesh_list[chosen_location_end].global_position
			if chosen_location_end == 4:
				$fuse_box_etx_1/connect/end.rotation_degrees.y = 0
				$fuse_box_etx_1/Interactable/corner.global_position = mesh_list[2].global_position
				$fuse_box_etx_1/Interactable/corner2.global_position = mesh_list[8].global_position
				$fuse_box_etx_1/Interactable/corner3.global_position = mesh_list[6].global_position
				$fuse_box_etx_1/Interactable/corner4.global_position = mesh_list[3].global_position
				$fuse_box_etx_1/Interactable/straight.global_position = mesh_list[1].global_position
				$fuse_box_etx_1/Interactable/straight2.global_position = mesh_list[5].global_position
				$fuse_box_etx_1/Interactable/straight3.global_position = mesh_list[7].global_position
				meshes = [$fuse_box_etx_1/Interactable/straight, $fuse_box_etx_1/Interactable/corner, $fuse_box_etx_1/Interactable/corner4,
				$fuse_box_etx_1/Interactable/straight2, $fuse_box_etx_1/Interactable/corner3, $fuse_box_etx_1/Interactable/straight3, $fuse_box_etx_1/Interactable/corner2]
				wire_check = "01011100100"
			elif chosen_location_end == 8:
				$fuse_box_etx_1/connect/end.rotation_degrees.y = 0
				$fuse_box_etx_1/Interactable/corner.global_position = mesh_list[2].global_position
				$fuse_box_etx_1/Interactable/corner2.global_position = mesh_list[5].global_position
				$fuse_box_etx_1/Interactable/corner3.global_position = mesh_list[3].global_position
				$fuse_box_etx_1/Interactable/corner4.global_position = mesh_list[6].global_position
				$fuse_box_etx_1/Interactable/straight.global_position = mesh_list[1].global_position
				$fuse_box_etx_1/Interactable/straight2.global_position = mesh_list[4].global_position
				$fuse_box_etx_1/Interactable/straight3.global_position = mesh_list[7].global_position
				meshes = [$fuse_box_etx_1/Interactable/straight, $fuse_box_etx_1/Interactable/corner, $fuse_box_etx_1/Interactable/corner3,
				$fuse_box_etx_1/Interactable/straight2, $fuse_box_etx_1/Interactable/corner2, $fuse_box_etx_1/Interactable/corner4, $fuse_box_etx_1/Interactable/straight3]
				wire_check = "00011100001"
		elif pick_direction == 4:
			$fuse_box_etx_1/connect/start.rotation_degrees.y = 270
			var chosen_location_end = [4, 8].pick_random()
			$fuse_box_etx_1/connect/end.global_position = mesh_list[chosen_location_end].global_position
			if chosen_location_end == 4:
				$fuse_box_etx_1/connect/end.rotation_degrees.y = -90
				$fuse_box_etx_1/Interactable/corner.global_position = mesh_list[6].global_position
				$fuse_box_etx_1/Interactable/corner2.global_position = mesh_list[8].global_position
				$fuse_box_etx_1/Interactable/corner3.global_position = mesh_list[2].global_position
				$fuse_box_etx_1/Interactable/corner4.global_position = mesh_list[1].global_position
				$fuse_box_etx_1/Interactable/straight.global_position = mesh_list[3].global_position
				$fuse_box_etx_1/Interactable/straight2.global_position = mesh_list[7].global_position
				$fuse_box_etx_1/Interactable/straight3.global_position = mesh_list[5].global_position
				meshes = [$fuse_box_etx_1/Interactable/corner4, $fuse_box_etx_1/Interactable/corner3, $fuse_box_etx_1/Interactable/straight,
				$fuse_box_etx_1/Interactable/straight3, $fuse_box_etx_1/Interactable/corner, $fuse_box_etx_1/Interactable/straight2, $fuse_box_etx_1/Interactable/corner2]
				wire_check = "10101101100"
			elif chosen_location_end == 8:
				$fuse_box_etx_1/connect/end.rotation_degrees.y = -90
				$fuse_box_etx_1/Interactable/corner.global_position = mesh_list[1].global_position
				$fuse_box_etx_1/Interactable/corner2.global_position = mesh_list[2].global_position
				$fuse_box_etx_1/Interactable/corner3.global_position = mesh_list[6].global_position
				$fuse_box_etx_1/Interactable/corner4.global_position = mesh_list[7].global_position
				$fuse_box_etx_1/Interactable/straight.global_position = mesh_list[3].global_position
				$fuse_box_etx_1/Interactable/straight2.global_position = mesh_list[4].global_position
				$fuse_box_etx_1/Interactable/straight3.global_position = mesh_list[5].global_position
				meshes = [$fuse_box_etx_1/Interactable/corner, $fuse_box_etx_1/Interactable/corner2, $fuse_box_etx_1/Interactable/straight,
				$fuse_box_etx_1/Interactable/straight2, $fuse_box_etx_1/Interactable/straight3, $fuse_box_etx_1/Interactable/corner3, $fuse_box_etx_1/Interactable/corner4]
				wire_check = "11100110110"

func try_inspect_fuses():
	if not opened:
		return
	if inspecting_fuses:
		exit_inspect_mode_fuses()
		#unhighlight_selected()
	else:
		enter_inspect_mode_fuses()
		for mesh in highlight_fuse:
			mesh.visible = false
		await get_tree().create_timer(0.8).timeout
		#highlight_selected()

func enter_inspect_mode_fuses():
	if inspecting_fuses:
		return
	inspecting_fuses = true
	original_camera_transform = player_camera.global_transform
	var player = get_node("/root/Level/Player")
	var raycast = get_node("/root/Level/Player/head/RayCast3D")
	can_exit = false
	player.can_move = false
	player.can_sprint = false
	raycast.enabled = false
	tween = create_tween()
	tween.tween_property(player_camera, "global_transform", inspect_target_fuses.global_transform, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.connect("finished", Callable(self, "_on_tween_finished_enter_fuses"))

func _on_tween_finished_enter_fuses():
	can_exit = true

func exit_inspect_mode_fuses():
	if not inspecting_fuses:
		return
	inspecting_fuses = false
	tween = create_tween()
	tween.tween_property(player_camera, "global_transform", original_camera_transform, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.connect("finished", Callable(self, "_on_tween_finished_exit_fuses"))

func _on_tween_finished_exit_fuses():
	var player = get_node("/root/Level/Player")
	var raycast = get_node("/root/Level/Player/head/RayCast3D")
	raycast.enabled = true
	player.can_move = true
	player.can_sprint = true

func handle_input_fuses():
	if Input.is_action_just_pressed("move_right"):
		change_selection_fuses(1)
	elif Input.is_action_just_pressed("move_left"):
		change_selection_fuses(-1)
	if Input.is_action_just_pressed("interact"):
		counter += 1
		swap_targets.append(mesh_list_fuses[selected_index_fuses])
	if counter == 1:
		highlight_selected_fuses()
		swap_targets[0].visible = true
	elif counter == 2:
		for mesh in highlight_fuse:
			if mesh.visible:
				mesh.visible = false
		swap_selected()
		counter = 0

func change_selection_fuses(delta: int):
	unhighlight_selected_fuses()
	selected_index_fuses = (selected_index_fuses + delta) % highlight_fuse.size()
	highlight_selected_fuses()

func highlight_selected_fuses():
	var mesh = highlight_fuse[selected_index_fuses]
	if mesh:
		mesh.visible = true

func unhighlight_selected_fuses():
	var mesh = highlight_fuse[selected_index_fuses]
	var real_mesh = mesh_list_fuses[selected_index_fuses]
	if real_mesh not in swap_targets:
		mesh.visible = false

func swap_selected():
	var fuse_temp = swap_targets[0].global_position
	swap_targets[0].global_position = swap_targets[1].global_position
	swap_targets[1].global_position = fuse_temp
	for elem in mesh_list_fuses:
		if elem in swap_targets:
			var index_temp0 = mesh_list_fuses.find(swap_targets[0])
			var index_temp1 = mesh_list_fuses.find(swap_targets[1])
			mesh_list_fuses[index_temp0] = swap_targets[1]
			mesh_list_fuses[index_temp1] = swap_targets[0]
			swap_targets.clear()

func wire_combination_check():
	var s1
	var s2
	var s3
	var c1
	var c2
	var c3
	var c4
	var total
	if $fuse_box_etx_1/Interactable/straight.rotation_degrees.y == 0.0 or $fuse_box_etx_1/Interactable/straight.rotation_degrees.y == 180.0:
		s1 = "0"
	elif $fuse_box_etx_1/Interactable/straight.rotation_degrees.y == 90.0 or $fuse_box_etx_1/Interactable/straight.rotation_degrees.y == 270.0:
		s1 = "1"
	else:
		s1 = "x"
		
	if $fuse_box_etx_1/Interactable/straight2.rotation_degrees.y == 0.0 or $fuse_box_etx_1/Interactable/straight2.rotation_degrees.y == 180.0:
		s2 = "1"
	elif $fuse_box_etx_1/Interactable/straight2.rotation_degrees.y == 90.0 or $fuse_box_etx_1/Interactable/straight2.rotation_degrees.y == 270.0:
		s2 = "0"
	else:
		s2 = "x"
		
	if $fuse_box_etx_1/Interactable/straight3.rotation_degrees.y == 0.0 or $fuse_box_etx_1/Interactable/straight3.rotation_degrees.y == 180.0:
		s3 = "1"
	elif $fuse_box_etx_1/Interactable/straight3.rotation_degrees.y == 90.0 or $fuse_box_etx_1/Interactable/straight3.rotation_degrees.y == 270.0:
		s3 = "0"
	else:
		s3 = "x"
		
	if $fuse_box_etx_1/Interactable/corner.rotation_degrees.y == 0.0:
		c1 = "00"
	elif $fuse_box_etx_1/Interactable/corner.rotation_degrees.y == 90.0:
		c1 = "01"
	elif $fuse_box_etx_1/Interactable/corner.rotation_degrees.y == 180.0:
		c1 = "10"
	elif $fuse_box_etx_1/Interactable/corner.rotation_degrees.y == 270.0:
		c1 = "11"
	else:
		c1 = "xx"
		
	if $fuse_box_etx_1/Interactable/corner2.rotation_degrees.y == 0.0:
		c2 = "01"
	elif $fuse_box_etx_1/Interactable/corner2.rotation_degrees.y == 90.0:
		c2 = "10"
	elif $fuse_box_etx_1/Interactable/corner2.rotation_degrees.y == 180.0:
		c2 = "11"
	elif $fuse_box_etx_1/Interactable/corner2.rotation_degrees.y == 270.0:
		c2 = "00"
	else:
		c2 = "xx"
		
	if $fuse_box_etx_1/Interactable/corner3.rotation_degrees.y == 0.0:
		c3 = "11"
	elif $fuse_box_etx_1/Interactable/corner3.rotation_degrees.y == 90.0:
		c3 = "00"
	elif $fuse_box_etx_1/Interactable/corner3.rotation_degrees.y == 180.0:
		c3 = "01"
	elif $fuse_box_etx_1/Interactable/corner3.rotation_degrees.y == 270.0:
		c3 = "10"
	else:
		c3 = "xx"
		
	if $fuse_box_etx_1/Interactable/corner4.rotation_degrees.y == 0.0:
		c4 = "10"
	elif $fuse_box_etx_1/Interactable/corner4.rotation_degrees.y == 90.0:
		c4 = "11"
	elif $fuse_box_etx_1/Interactable/corner4.rotation_degrees.y == 180.0:
		c4 = "00"
	elif $fuse_box_etx_1/Interactable/corner4.rotation_degrees.y == 270.0:
		c4 = "01"
	else:
		c4 = "xx"
		
	total = s1 + s2 + s3 + c1 + c2 + c3 + c4
	
	if total == wire_check:
		wire_finished = true

func fuse_combination_check():
	var fuse_check1 = [$fuses/FuseYellow,$fuses/FuseBlue,$fuses/FuseGreen,$fuses/FuseRed]
	var fuse_check2 = [$fuses/FuseRed,$fuses/FuseBlue,$fuses/FuseYellow,$fuses/FuseGreen]
	var fuse_check3 = [$fuses/FuseBlue,$fuses/FuseRed,$fuses/FuseYellow,$fuses/FuseGreen]
	var fuse_check4 = [$fuses/FuseBlue,$fuses/FuseYellow,$fuses/FuseRed,$fuses/FuseGreen]
	if set_fuse_comb == 1:
		if mesh_list_fuses == fuse_check1:
			fuse_finished = true
	elif set_fuse_comb == 2:
		if mesh_list_fuses == fuse_check2:
			fuse_finished = true
	elif set_fuse_comb == 3:
		if mesh_list_fuses == fuse_check3:
			fuse_finished = true
	elif set_fuse_comb == 4:
		if mesh_list_fuses == fuse_check4:
			fuse_finished = true
