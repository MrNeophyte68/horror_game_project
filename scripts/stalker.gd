extends CharacterBody3D

# This enum lists all the possible states the character can be in.
enum States {ROAMING, STALKING, CHASING, SEARCHING}

# This variable keeps track of the character's current state.
var state: States = States.ROAMING

@export var patrol_destinations: Array[Node3D]
@onready var player = get_tree().current_scene.get_node("player")
var speed = 3.0
@onready var rng = RandomNumberGenerator.new()
var destination
var chasing = false
var destination_value

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
