extends CharacterBody3D

enum DollState1 {FIRST_TIME, WAIT, ROAM, CHASE, SPAWN}
var current_state: DollState1 = DollState1.FIRST_TIME
var first_time_attack: bool = false
var first_time_aggressive: bool = false
@onready var first_switch = get_tree().root.get_node("Level/PowerSwitches/PowerSwitch4")
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var player = get_tree().root.get_node("Level/Player")
@onready var animation: AnimationPlayer = $Doll1/AnimationPlayer
@onready var level = get_tree().root.get_node("Level")
@onready var first_time_timer = $firsttime_attack
var first_time_near: bool = false
@export var speed := 2.0
@export var turn_speed := 8.0
@export var side_push := 0.4
@export var gravity := 9.8
var playerVaultCount = 0
var window_location
var play_block_window = false
@onready var wait_time = $wait_time
var cover_eyes = false

func _ready() -> void:
	first_time_timer.start()

func _physics_process(delta: float):

	if current_state == DollState1.FIRST_TIME:
		if level.power_on or first_time_near:
			nav_agent.target_position = player.global_position
			var next_point: Vector3 = nav_agent.get_next_path_position()
			var dir: Vector3 = (next_point - global_position)
			dir = dir.normalized()
			velocity.x = dir.x * 0.0
			velocity.z = dir.z * 0.0
			animation.play("RESET")
			$SpotLight3D.visible = true
			global_position = Vector3(-8.72, -0.044, -9.716)
			current_state = DollState1.WAIT
			animation.play("cover_eyes")
			return
			
		if !first_time_attack and !first_time_aggressive:
			animation.play("idle")
			
		if first_time_attack and !first_time_aggressive:
			nav_agent.target_position = player.global_position
			var next_point: Vector3 = nav_agent.get_next_path_position()
			var dir: Vector3 = (next_point - global_position)
			if dir.length() > 0.001:
				dir = dir.normalized()
				velocity.x = dir.x * 0.5
				velocity.z = dir.z * 0.5
				_face_player_flat()
		
		elif !first_time_attack and !first_time_aggressive:
			nav_agent.target_position = player.global_position
			var next_point: Vector3 = nav_agent.get_next_path_position()
			var dir: Vector3 = (next_point - global_position)
			if dir.length() > 0.001:
				dir = dir.normalized()
				velocity.x = dir.x * 0.0
				velocity.z = dir.z * 0.0

		elif first_time_aggressive:
			first_time_attack = false
			if !player.spamming:
				chase_player(delta)
			else:
				var target_marker = find_nearest_window()
				if target_marker:
					nav_agent.target_position = target_marker.global_transform.origin
					var next_point := nav_agent.get_next_path_position()
					var dir := (next_point - global_transform.origin).normalized()
					velocity = dir * 5.0 #adjust speed
				if nav_agent.is_target_reached() and !play_block_window:
					var look_at_pos = window_location.global_position
					look_at_pos.y = global_position.y  # keep upright
					smooth_face_yaw_toward(look_at_pos, delta, 8.0)
					animation.play("raise_hand")
				else:
					if velocity.length() > 0.05 and !play_block_window:
						var ang := atan2(-velocity.x, -velocity.z)
						rotation.y = lerp_angle(rotation.y, ang, turn_speed * delta)
				if not is_on_floor():
					velocity.y -= gravity * delta
				else:
					if velocity.y > 0.0:
						velocity.y = 0.0

	elif current_state == DollState1.WAIT:
		if wait_time.is_stopped():
			wait_time.start()
		rotation_degrees.y = -180.0
		if wait_time.time_left < 90.0 and wait_time.time_left > 60.0:
			if !player.staring:
				await get_tree().create_timer(1.0, false).timeout
				global_position = Vector3(-8.72, -0.044, -8)
		elif wait_time.time_left < 90.0 and wait_time.time_left > 30.0:
			if !player.staring:
				await get_tree().create_timer(1.0, false).timeout
				global_position = Vector3(-8.72, -0.044, -7)
		elif wait_time.time_left < 30.0:
			if !player.staring:
				await get_tree().create_timer(1.0, false).timeout
				global_position = Vector3(-8.72, -0.044, -6)
		if player.staring:
			if $abyss_time_before_attack.is_stopped():
				$abyss_time_before_attack.start()
			if $abyss_time_before_attack.time_left < 5.0 and $abyss_time_before_attack.time_left > 4.9:
				animation.play_backwards("cover_eyes")
				cover_eyes = true
		else:
			$abyss_time_before_attack.stop()
			if cover_eyes:
				cover_eyes = false
				await get_tree().create_timer(1.0, false).timeout
				animation.play("cover_eyes")


	move_and_slide()


func _process(_delta: float) -> void:
	if first_switch.switch.rotation_degrees.x != 0.0 and !first_time_aggressive and current_state == DollState1.FIRST_TIME:
		first_time_attack = true
	else:
		first_time_attack = false

func _face_player_flat() -> void:
	var look_at_pos = player.global_position
	look_at_pos.y = global_position.y  # keep upright
	look_at(look_at_pos, Vector3.UP)


func _on_firsttime_attack_timeout() -> void:
	first_time_aggressive = true

func chase_player(delta):
	if animation.current_animation != "death":
		animation.play("run")
	nav_agent.target_position = player.global_position

	if nav_agent.is_navigation_finished():
				# optional: slow down when close
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		velocity.y -= gravity * delta
		move_and_slide()
		return
	var next_point: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = next_point - global_position
	dir.y = 0.0
	if dir.length() < 0.001:
		velocity.y -= gravity * delta
		move_and_slide()
		return
	dir = dir.normalized()
			# --- Gentle anti-scrape steering using both probes ---
	var wall_n: Vector3 = Vector3.ZERO
	if $check_wall_left.is_colliding():
		var n = $check_wall_left.get_collision_normal()
		n.y = 0.0
		wall_n += n
	if $check_wall_right.is_colliding():
		var n = $check_wall_right.get_collision_normal()
		n.y = 0.0
		wall_n += n
	var steer := dir
	if wall_n != Vector3.ZERO:
		wall_n = wall_n.normalized()
		steer = (dir + wall_n * side_push).normalized()
			# --- Move ---
	velocity.x = steer.x * speed
	velocity.z = steer.z * speed
	velocity.y -= gravity * delta
	move_and_slide()
			# --- Face movement smoothly (not the player) ---
	if velocity.length() > 0.05:
		var ang := atan2(-velocity.x, -velocity.z)
		rotation.y = lerp_angle(rotation.y, ang, turn_speed * delta)

func find_nearest_window():
	var best: Marker3D = null
	var best_d2 := INF
	var my_pos := global_transform.origin
	
	for n in get_tree().get_nodes_in_group("windowBlockPosition"):
		if n is Marker3D:
			var parent = n.get_parent()
			# Safely read a custom property on the parent; only accept if true.
			if parent.locked == false:
				var d2 := my_pos.distance_squared_to(n.global_transform.origin)
				window_location = parent.window_location
				if d2 < best_d2:
					best_d2 = d2
					best = n
	return best

func smooth_face_yaw_toward(target_pos: Vector3, delta: float, turn_speed := 8.0) -> void:
	var to_flat := Vector2(target_pos.x, target_pos.z) - Vector2(global_position.x, global_position.z)
	if to_flat.length_squared() < 0.000001:
		return  # too close; do nothing
	var desired_yaw := atan2(-to_flat.x, -to_flat.y)  # radians
	var current_yaw := global_rotation.y
	var t = clamp(turn_speed * delta, 0.0, 1.0)
	var new_yaw := lerp_angle(current_yaw, desired_yaw, t)
	global_rotation = Vector3(0.0, new_yaw, 0.0)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "raise_hand":
		play_block_window = true
		animation.play("block_window")
		window_location.get_parent().animation.play("blocked")
		await get_tree().create_timer(2.5, false).timeout
		window_location.get_parent().locked = true
		await get_tree().create_timer(2.0, false).timeout
		animation.play("lower_hand")
		await get_tree().create_timer(1.0, false).timeout
		player.spamming = false
		play_block_window = false


func _on_area_3d_body_entered(body: CharacterBody3D) -> void:
	if body.name == "Player" and current_state != DollState1.WAIT:
		player.can_move = false
		player.ui.stamina.visible = false
		player.ui.score.visible = false
		$deathcam.current = true
		animation.play("death")
		player.dead = true


func _on_abyss_time_before_attack_timeout() -> void:
	player.can_move = false
	player.ui.stamina.visible = false
	player.ui.score.visible = false
	$deathcam.current = true
	animation.play("death")
	player.dead = true


func _on_wait_time_timeout() -> void:
	current_state = DollState1.SPAWN
	level.turn_off_random_lights()
