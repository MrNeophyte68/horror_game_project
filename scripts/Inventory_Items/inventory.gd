extends Node

class_name PlayerInventory

var inventory := [
	preload("res://level/Items/lighter.tscn"),
	null,
	null
]

func get_item(slot: int):
	if slot >= 0 and slot < inventory.size():
		return inventory[slot]
	return null
