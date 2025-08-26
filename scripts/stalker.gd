extends CharacterBody3D

# This enum lists all the possible states the character can be in.
enum States {ROAMING, STALKING, CHASING, SEARCHING}

# This variable keeps track of the character's current state.
var state: States = States.ROAMING

@export var patrol_destinations: Array[Node3D]
@onready var player: CharacterBody3D = $"../Player"
@onready var detection_area = $DetectionArea
@onready var detection_cast = $DetectionCast
@onready var rng = RandomNumberGenerator.new()
var speed = 3.0
var destination
var destination_value
var spotted = false

func _ready() -> void:
	pick_destination()

func pick_destination(dont_choose = null):
	var num = rng.randi_range(0, patrol_destinations.size() - 1)
	destination_value = num
	destination = patrol_destinations[num]
	if destination != null and dont_choose != null and destination == patrol_destinations[dont_choose]:
		if dont_choose < 1:
			destination = patrol_destinations[dont_choose + 1]
		if dont_choose > 0 and dont_choose <= patrol_destinations.size() - 1:
			destination = patrol_destinations[dont_choose - 1]

func update_target_location():
	$NavigationAgent3D.target_position = destination.global_transform.origin

func _process(delta: float) -> void:
	if state == States.ROAMING:
		if destination != null:
			var look_dir = lerp_angle(deg_to_rad(global_rotation_degrees.y), atan2(-velocity.x, -velocity.z), 0.5)
			global_rotation_degrees.y = rad_to_deg(look_dir)
			update_target_location()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if state == States.ROAMING:
		if destination != null:
			var current_location = global_transform.origin
			var next_location = $NavigationAgent3D.get_next_path_position()
			var new_velocity = (next_location - current_location).normalized() * speed
			velocity = velocity.move_toward(new_velocity, 0.25)
			move_and_slide()
			
	if state == States.STALKING:
		if spotted == true:
			velocity = Vector3.ZERO
			# Face the player
			var target_pos = player.global_position
			look_at(target_pos, Vector3.UP)
		
		#detection_cast.look_at(player.global_transform.origin, Vector3.UP)
		#if detection_cast.is_colliding():
			#var collider = detection_cast.get_collider()
		
		
	if state == States.CHASING:
		# Move towards player
		$NavigationAgent3D.set_target_position(player.global_position)
		var next_pos = $NavigationAgent3D.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		
		# Face the player
		var target_pos = player.global_position
		target_pos.y = global_position.y
		look_at(target_pos, Vector3.UP)
		velocity = direction * speed
		move_and_slide()

func _on_detection_timer_timeout() -> void:
	var overlaps = detection_area.get_overlapping_bodies()
	if overlaps.size() > 0:
		for body in overlaps:
			if body == player:
				detection_cast.look_at(player.global_transform.origin, Vector3.UP)
				detection_cast.force_raycast_update()
				
				if detection_cast.is_colliding():
					var collider = detection_cast.get_collider()
					if collider == player:
						detection_cast.debug_shape_custom_color = Color(174,0,0)
						state = States.STALKING
						spotted = true
					else:
						spotted = false
				
				else:
					detection_cast.debug_shape_custom_color = Color(0,255,0)
