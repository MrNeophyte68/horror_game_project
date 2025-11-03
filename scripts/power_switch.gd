extends Node3D

@onready var switch = $lever_etx_2/lever_etx_2_child2
var activate:bool = false
var play_once:bool = true
@onready var staticbody = $lever_etx_2/power_switch

func _ready():
	$GPUParticles3D.emitting = false

func _physics_process(delta: float):
	if Input.is_action_just_released("interact") and $lever_etx_2/lever_etx_2_child.rotation_degrees.x != 0.0 and !activate:
		$lever_etx_2/lever_etx_2_child2.rotation_degrees.x = 0.0
		var tween = create_tween()
		tween.tween_property($lever_etx_2/lever_etx_2_child, "rotation_degrees:x", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	if $lever_etx_2/lever_etx_2_child2.rotation_degrees.x == 0.0 and !activate:
		$lever_etx_2/screen_etx_1_partial/SubViewport/CanvasLayer2/TextureProgressBar.value -= delta * 40.0
	
	if $lever_etx_2/screen_etx_1_partial/SubViewport/CanvasLayer2/TextureProgressBar.value == 2000:
		activate = true
		
	if activate:
		$lever_etx_2/lamp_2_on.visible = true
		$lever_etx_2/lamp_2_off.visible = false
		staticbody.name = "turnedON"
		if play_once:
			$GPUParticles3D.restart()
			$lever_etx_2/lever_etx_2_child2.rotation_degrees.x = 0.0
			var tween = create_tween()
			tween.tween_property($lever_etx_2/lever_etx_2_child, "rotation_degrees:x", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			play_once = false
			await get_tree().create_timer(1.0).timeout
			$GPUParticles3D.emitting = false
		
	else:
		staticbody.name = "power_switch"
		$lever_etx_2/lamp_2_on.visible = false
		$lever_etx_2/lamp_2_off.visible = true
		play_once = true
		
func turn_on():
	$lever_etx_2/lever_etx_2_child2.rotation_degrees.x = 90.0
	var tween = create_tween()
	tween.tween_property($lever_etx_2/lever_etx_2_child, "rotation_degrees:x", 90.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func activating(delta):
	$lever_etx_2/screen_etx_1_partial/SubViewport/CanvasLayer2/TextureProgressBar.value += delta * 80.0

func reset():
	$lever_etx_2/screen_etx_1_partial/SubViewport/CanvasLayer2/TextureProgressBar.value = 0
