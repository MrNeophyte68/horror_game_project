extends CharacterBody3D

enum DollState1 {FIRST_TIME, WAIT, ROAM, CHASE, DEATH}
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

#roaming
@onready var roam1_locations = get_tree().get_nodes_in_group("roaming1_locations")
var last_roam_target: Vector3 = Vector3.INF
@onready var chosen = randi_range(0, roam1_locations.size() - 1)
var roam_waiting = false

func _ready() -> void:
	first_time_timer.start()

func _physics_process(delta: float):

	if current_state == DollState1.FIRST_TIME:
		if level.power_on:
			first_time_near = true
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
			
		elif first_time_near:
			current_state = DollState1.ROAM
			level.spawn_monster_far_from_player()
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
			if player.no_longer_staring:
				global_position = Vector3(-8.72, -0.044, -8)
		elif wait_time.time_left < 90.0 and wait_time.time_left > 30.0:
			if player.no_longer_staring:
				global_position = Vector3(-8.72, -0.044, -7)
		elif wait_time.time_left < 30.0:
			if player.no_longer_staring:
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
				
	elif current_state == DollState1.DEATH:
		var next_point: Vector3 = nav_agent.get_next_path_position()
		var dir: Vector3 = (next_point - global_position)
		dir = dir.normalized()
		velocity.x = dir.x * 0.0
		velocity.z = dir.z * 0.0
		
		
	elif current_state == DollState1.ROAM:
		wait_time.stop()
		if level.power_on:
			first_time_near = true
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
			
		if roam_waiting:
			if animation.current_animation != "death":
				animation.play("idle")
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			velocity.y -= gravity * delta
			for body in $fov.get_overlapping_bodies():
				if body == player:
					$line_of_sight.look_at(player.global_position, Vector3.UP)
					$line_of_sight.force_raycast_update()
					if $line_of_sight.is_colliding() and $line_of_sight.get_collider() == player:
						current_state = DollState1.CHASE
			move_and_slide()
			return
			
		if animation.current_animation != "death":
			animation.play("run")
		
		nav_agent.target_position = roam1_locations[chosen].global_position
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
		#line of sight
		for body in $fov.get_overlapping_bodies():
			if body == player:
				$line_of_sight.look_at(player.global_position, Vector3.UP)
				$line_of_sight.force_raycast_update()
				if $line_of_sight.is_colliding() and $line_of_sight.get_collider() == player:
					current_state = DollState1.CHASE
	
	elif current_state == DollState1.CHASE:
		wait_time.stop()
		if level.power_on:
			first_time_near = true
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
		if animation.current_animation != "death":
			animation.play("lower_hand")
		await get_tree().create_timer(1.0, false).timeout
		player.spamming = false
		play_block_window = false
		current_state = DollState1.ROAM


func _on_area_3d_body_entered(body: CharacterBody3D) -> void:
	if body.name == "Player" and current_state != DollState1.WAIT:
		current_state = DollState1.DEATH
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
	$abyss_time_before_attack.stop()
	wait_time.stop()
	if cover_eyes:
		animation.play("fade_away2")
	else:
		animation.play("fade_away")
	await get_tree().create_timer(2.0).timeout
	level.turn_off_random_lights()
	level.spawn_monster_far_from_player()
	await get_tree().create_timer(1.0).timeout
	current_state = DollState1.ROAM

#roaming state
func _pick_new_roam_target() -> void:
	if roam1_locations.is_empty():
		return

	var tries := 8
	var picked := last_roam_target
	while tries > 0:
		var number = randi_range(0, roam1_locations.size() - 1)
		var p = roam1_locations[number].global_position
		# Avoid picking the exact same spot or too-close neighbors.
		if last_roam_target == Vector3.INF or p.distance_to(last_roam_target) > 1.5:
			chosen = number
			picked = p
			break
		tries -= 1
	last_roam_target = picked

func _on_navigation_agent_3d_target_reached() -> void:
	if current_state == DollState1.ROAM:
		roam_waiting = true
		await get_tree().create_timer(randf_range(6.0, 12.0)).timeout
		_pick_new_roam_target()
		roam_waiting = false
	elif current_state == DollState1.CHASE:
		pass
