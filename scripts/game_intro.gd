extends Node3D

@export var finger_scene: PackedScene
@onready var finger_spawn_points := $FingerSpawnPoints.get_children()

# Fuse scene exports
@export var red_fuse_scene: PackedScene
@export var green_fuse_scene: PackedScene
@export var blue_fuse_scene: PackedScene
@export var yellow_fuse_scene: PackedScene
@onready var spawn_points := $fuse_spawn_points.get_children()

var fuse_data = {
	"FuseRed": "red",
	"FuseGreen": "green",
	"FuseBlue": "blue",
	"FuseYellow": "yellow",
}

var fuse_scenes = {}

@export var note_scene: PackedScene
@onready var note_spawn_points := $note_spawn_points.get_children()
@onready var lights := $map/lights.get_children()
@onready var lights_poweroff := $map/lights_power_off.get_children()
var power_on: bool = false

#powerSwitches
@onready var power_switches:= $PowerSwitches.get_children()
var switch_check:int = 0

@onready var game_timer: Timer = $Game_Duration
const TOTAL_SECONDS: float = 1200
@onready var shadowCam = $shadowCam
@onready var cutsceneCam = $cutscene_camera

#doll roaming
@onready var roaming_floor1_locations = $doll_floor1_roaming_locations.get_children()
	
func _ready():
	shadowCam.current = false
	for switch in power_switches:
		if switch.name != "PowerSwitch4":
			switch.activate = true
	
	$cutscene_ui/AnimationPlayer.play("fade")
	#$AnimationPlayer.play("cutscene")
	#await get_tree().create_timer(5.0, false).timeout  # Wait for cutscene
	#$cutscene_ui/AnimationPlayer.play_backwards("fade")
	#await get_tree().create_timer(6.0, false).timeout
	#$cutscene_ui/AnimationPlayer.play("fade")
	#$AnimationPlayer.play("cutscene1")
	#await get_tree().create_timer(15.0, false).timeout
	$cutscene_camera.current = false
	
	randomize()
	_spawn_fingers()
	_spawn_fuses()
	_spawn_note()

func _spawn_note():
	var selected_points = note_spawn_points.duplicate()
	selected_points.shuffle()
	selected_points = selected_points.slice(0, 1)
	
	for point in selected_points:
		var note = note_scene.instantiate()
		note.global_position = point.global_position
		note.rotate_y(randf_range(0, TAU))
		add_child(note)
	

func _spawn_fingers():
	var selected_points = finger_spawn_points.duplicate()
	selected_points.shuffle()
	selected_points = selected_points.slice(0, 16)

	for point in selected_points:
		var finger = finger_scene.instantiate()
		finger.global_position = point.global_position
		finger.rotate_y(randf_range(0, TAU))
		add_child(finger)

func _spawn_fuses():
	# Map fuse types to scene exports
	fuse_scenes = {
		"red": red_fuse_scene,
		"green": green_fuse_scene,
		"blue": blue_fuse_scene,
		"yellow": yellow_fuse_scene,
	}

	# Sanity check: all scenes must be assigned
	for key in fuse_scenes.keys():
		if fuse_scenes[key] == null:
			push_error("Missing fuse scene for: " + key)
			return

	var fuse_names = fuse_data.keys()  # All 4 fuses
	spawn_points.shuffle()

	if spawn_points.size() < fuse_names.size():
		push_error("Not enough fuse spawn points!")
		return

	for i in range(fuse_names.size()):
		var fuse_name = fuse_names[i]  # e.g. "FuseRed"
		var fuse_type = fuse_data[fuse_name]  # e.g. "red"

		# Remove static fuse from fusebox
		var fuse_node = $map/Puzzle/fusebox.get_node_or_null(fuse_name)
		if fuse_node:
			fuse_node.visible = false
		else:
			push_warning("Missing fuse node in fusebox: " + fuse_name)

		# Spawn at random spawn point
		var spawn_point = spawn_points[i]
		var new_fuse = fuse_scenes[fuse_type].instantiate()
		new_fuse.global_position = spawn_point.global_position
		new_fuse.rotate_y(randf_range(0, TAU))  # optional
		add_child(new_fuse)

func _process(_delta: float) -> void:
	if power_on:
		$WorldEnvironment.environment.tonemap_exposure = 1.5
		for light in lights:
			light.light_on = true
		for lightpo in lights_poweroff:
			lightpo.light_on = false
	else:
		$WorldEnvironment.environment.tonemap_exposure = 0.8
		for light in lights:
			light.light_on = false
		for lightpo in lights_poweroff:
			lightpo.light_on = true
			
	switch_check = 0
	for switch in power_switches:
		if switch.activate:
			switch_check += 1

	if switch_check == power_switches.size():
		power_on = true
	else:
		power_on = false
	
	

func _on_area_3d_body_entered(body: CharacterBody3D):
	if body.name == "Player" and $Stalker.first_time_aggressive == false and $Stalker.first_time_attack == false and $Stalker.first_time_near == false and power_on == false:
		$map/lights_power_off/Node3D.animation.play("blink")
		$Stalker.first_time_near = true

func _on_game_duration_timeout() -> void:
	$cutscene_ui/AnimationPlayer.play("RESET")
	$cutscene_ui/CanvasLayer/Label.visible = true

func turn_off_random_lights():
	if power_on:
		var number = randi_range(2, 4)
		var count = 0
		var random_power_switches = power_switches
		random_power_switches.shuffle()
		for switch in random_power_switches:
			if switch.activate and count != number:
				switch.activate = false
				switch.reset()
				count += 1

func spawn_monster_far_from_player() -> void:
	var marker := _get_furthest_marker_by_distance($Player.global_position)
	if marker == null:
		push_warning("No Marker3D found to spawn the monster.")
		return

	$Stalker.global_transform = marker.global_transform

func _get_furthest_marker_by_distance(player_pos: Vector3) -> Marker3D:
	var best: Marker3D = null
	var best_d2 := -INF
	for child in $doll_floor1_spawn_points.get_children():
		if child is Marker3D:
			var d2 := player_pos.distance_squared_to(child.global_position)
			if d2 > best_d2:
				best_d2 = d2
				best = child
	return best
