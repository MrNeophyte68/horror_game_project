extends Node3D

@onready var fusebox = get_tree().root.get_node("Level/map/Puzzle/fusebox")
@onready var player = get_tree().root.get_node("Level/Player")
@onready var colorRect = $CanvasLayer/ColorRect
var reading: bool = false
var can_modify_stamina: bool = false

func _ready() -> void:
	colorRect.modulate.a = 0.7

func read():
	reading = !reading
	player.raycast.reading = !player.raycast.reading
	
	if reading:
		colorRect.visible = true
		player.can_move = false
		player.ui.stamina.modulate.a = 0.0
		can_modify_stamina = true
		player.ui.score.visible = false
		$CanvasLayer/exit_message.visible = true
		
		if fusebox.set_fuse_comb == 1:
			$CanvasLayer/riddle1.visible = true
		elif fusebox.set_fuse_comb == 2:
			$CanvasLayer/riddle2.visible = true
		elif fusebox.set_fuse_comb == 3:
			$CanvasLayer/riddle3.visible = true
		elif fusebox.set_fuse_comb == 4:
			$CanvasLayer/riddle4.visible = true
		
	else:
		colorRect.visible = false
		player.can_move = true
		player.ui.score.visible = true
		$CanvasLayer/exit_message.visible = false
		if can_modify_stamina:
			player.ui.stamina.modulate.a = 0.2
		if fusebox.set_fuse_comb == 1:
			$CanvasLayer/riddle1.visible = false
		elif fusebox.set_fuse_comb == 2:
			$CanvasLayer/riddle2.visible = false
		elif fusebox.set_fuse_comb == 3:
			$CanvasLayer/riddle3.visible = false
		elif fusebox.set_fuse_comb == 4:
			$CanvasLayer/riddle4.visible = false
