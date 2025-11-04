extends Node

class_name PlayerInventory

var inventory := [
	null,
	preload("res://level/Items/saw.tscn"),
	preload("res://level/Items/saw.tscn")
]

func get_item(slot: int):
	if slot >= 0 and slot < inventory.size():
		return inventory[slot]
	return null
