extends Control

@onready var grid: GridContainer = $Panel/GridContainer

const SLOT_SCENE = preload("res://scenes/inventory_slot.tscn")

var current_inventory: Inventory = null

func show_inventory(inv: Inventory) -> void:
	current_inventory = inv
	visible = true
	refresh()

func hide_inventory() -> void:
	visible = false
	current_inventory = null

func refresh() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	if current_inventory == null:
		return

	for i in range(current_inventory.items.size()):
		var slot_data = current_inventory.items[i]
		var slot_ui = SLOT_SCENE.instantiate()
		grid.add_child(slot_ui)
		if slot_data.item == null:
			slot_ui.setup_empty(current_inventory, i)
		else:
			slot_ui.setup(slot_data.item, slot_data.count, current_inventory, i)
