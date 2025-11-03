extends CharacterBody3D

enum DollState1 {FIRST_TIME, WAIT}
var current_state: DollState1 = DollState1.FIRST_TIME
var first_time_attack: bool = false
@onready var first_switch = get_tree().root.get_node("Level/PowerSwitches/PowerSwitch4")
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var player = get_tree().root.get_node("Level/Player")
@onready var animation: AnimationPlayer = $Doll1/AnimationPlayer
@onready var level = get_tree().root.get_node("Level")

func _physics_process(delta: float):

	if current_state == DollState1.FIRST_TIME:
		if level.power_on:
			current_state = DollState1.WAIT
			$Doll1.visible = false
			$CollisionShape3D.disabled = true
			set_physics_process(false)
			return
		animation.play("idle")
		if first_time_attack:
			nav_agent.target_position = player.global_position
			var next_point: Vector3 = nav_agent.get_next_path_position()
			var dir: Vector3 = (next_point - global_position)
			if dir.length() > 0.001:
				dir = dir.normalized()
				velocity.x = dir.x * 0.5
				velocity.z = dir.z * 0.5
				_face_player_flat()

		
	move_and_slide()


func _process(delta: float) -> void:
	if first_switch.switch.rotation_degrees.x != 0.0:
		first_time_attack = true

func _face_player_flat() -> void:
	var look_at_pos = player.global_position
	look_at_pos.y = global_position.y  # keep upright
	look_at(look_at_pos, Vector3.UP)
