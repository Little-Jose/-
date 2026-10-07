extends Node

signal inventory_changed

@export var max_slots: int = 20
var items: Array[Dictionary] = []

func _ready() -> void:
	_ensure_slots()

func _ensure_slots() -> void:
	while items.size() < max_slots:
		items.append({"item": null, "count": 0})

func add_item(new_item: Item, amount: int = 1) -> bool:
	# 先堆叠到已有同类物品上
	for slot in items:
		if slot.item == null:
			continue
		if slot.item.item_name == new_item.item_name and slot.count < new_item.max_stack:
			var to_add = min(new_item.max_stack - slot.count, amount)
			slot.count += to_add
			amount -= to_add
			if amount <= 0:
				inventory_changed.emit()
				return true

	# 再找空格
	for i in range(items.size()):
		if items[i].item == null:
			var to_add = min(new_item.max_stack, amount)
			items[i] = {"item": new_item, "count": to_add}
			amount -= to_add
			if amount <= 0:
				inventory_changed.emit()
				return true

	inventory_changed.emit()
	return amount <= 0

func remove_item(item_name: String, amount: int = 1) -> bool:
	for i in range(items.size()):
		if items[i].item == null:
			continue
		if items[i].item.item_name == item_name:
			var to_remove = min(items[i].count, amount)
			items[i].count -= to_remove
			amount -= to_remove
			if items[i].count <= 0:
				items[i] = {"item": null, "count": 0}
			if amount <= 0:
				inventory_changed.emit()
				return true
	inventory_changed.emit()
	return false

func has_item(item_name: String, amount: int = 1) -> bool:
	var total = 0
	for slot in items:
		if slot.item == null:
			continue
		if slot.item.item_name == item_name:
			total += slot.count
	return total >= amount

func remove_at(index: int, amount: int) -> int:
	if index < 0 or index >= items.size():
		return 0
	if items[index].item == null:
		return 0
	var to_remove = min(items[index].count, amount)
	items[index].count -= to_remove
	if items[index].count <= 0:
		items[index] = {"item": null, "count": 0}
	inventory_changed.emit()
	return to_remove

func set_slot(index: int, new_item: Item, new_count: int) -> void:
	if index < 0 or index >= items.size():
		return
	if new_item == null or new_count <= 0:
		items[index] = {"item": null, "count": 0}
	else:
		items[index] = {"item": new_item, "count": new_count}
	inventory_changed.emit()
