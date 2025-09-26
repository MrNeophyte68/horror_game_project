extends Node3D

@export var finger_scene: PackedScene
@onready var spawn_points := $FingerSpawnPoints.get_children()

# Called when the node enters the scene tree for the first time.
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
	
	var selected_points = spawn_points.duplicate()
	selected_points.shuffle()
	selected_points = selected_points.slice(0, 10)
	
	for point in selected_points:
		var finger_instance = finger_scene.instantiate()
		finger_instance.global_position = point.global_position
		var random_y_angle = randf_range(0, TAU)  # TAU = 2π radians
		finger_instance.rotate_y(random_y_angle)
		add_child(finger_instance)
