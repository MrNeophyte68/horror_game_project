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

	
func _ready():
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

	var fuse_names = fuse_data.keys()
	fuse_names.shuffle()

	var missing_count = randi_range(1, 3)
	var missing_fuses = fuse_names.slice(0, missing_count)

	spawn_points.shuffle()

	if spawn_points.size() < missing_count:
		push_error("Not enough fuse spawn points!")
		return

	for i in range(missing_count):
		var fuse_name = missing_fuses[i]  # e.g. "FuseRed"
		var fuse_type = fuse_data[fuse_name]  # e.g. "red"

		# Remove static fuse from fusebox
		var fuse_node = $map/Puzzle/fusebox.get_node_or_null(fuse_name)
		if fuse_node:
			fuse_node.queue_free()
		else:
			push_warning("Missing fuse node in fusebox: " + fuse_name)

		# Spawn at random spawn point
		var spawn_point = spawn_points[i]
		var new_fuse = fuse_scenes[fuse_type].instantiate()
		new_fuse.global_position = spawn_point.global_position
		new_fuse.rotate_y(randf_range(0, TAU))  # optional
		add_child(new_fuse)
