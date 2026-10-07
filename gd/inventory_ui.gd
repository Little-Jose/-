extends Control

@onready var grid: GridContainer = $Panel/GridContainer
@onready var value_label: Label = $Panel/ValueLabel

const SLOT_SCENE = preload("res://scenes/inventory_slot.tscn")

func _ready() -> void:
	Inventory.inventory_changed.connect(refresh)

func refresh() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	for i in range(Inventory.items.size()):
		var slot_data = Inventory.items[i]
		var slot_ui = SLOT_SCENE.instantiate()
		grid.add_child(slot_ui)
		if slot_data.item == null:
			slot_ui.setup_empty(Inventory, i)
		else:
			slot_ui.setup(slot_data.item, slot_data.count, Inventory, i)

	# 更新总价值
	var total = 0
	for slot in Inventory.items:
		if slot.item != null:
			total += slot.item.value * slot.count
	value_label.text = "物品总价值: %d" % total
