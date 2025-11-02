extends Node3D

@onready var player = get_tree().root.get_node("Level/Player")
@onready var lighter = preload("res://level/Items/lighter.tscn")

func equip_lighter():
	player.add_item_to_inventory(lighter)
	
