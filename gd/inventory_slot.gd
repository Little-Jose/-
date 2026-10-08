extends Control

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $CountLabel

var item: Item = null
var count: int = 0
var source_inventory: Inventory = null
var slot_index: int = -1

# ===== 点选选中记录 =====
static var selected_slot: Control = null

# ===== 手动拖拽状态 =====
static var dragging_slot: Control = null
static var drag_preview: Control = null

# ===== 拖拽起始检测 =====
var press_position: Vector2 = Vector2.ZERO
var is_pressing: bool = false
var is_dragging: bool = false
const DRAG_THRESHOLD := 8.0

# ===== 双击检测 =====
var last_click_time: float = 0.0
const DOUBLE_CLICK_TIME := 0.3

func setup(new_item: Item, new_count: int, inv: Inventory, index: int) -> void:
	item = new_item
	count = new_count
	source_inventory = inv
	slot_index = index
	icon.texture = item.icon if item else null
	count_label.text = str(count) if count > 1 else ""
	custom_minimum_size = Vector2(64, 64)

	if item:
		tooltip_text = "%s\n%s\n单价: %d" % [item.item_name, item.description, item.value]
	else:
		tooltip_text = ""

func setup_empty(inv: Inventory, index: int) -> void:
	item = null
	count = 0
	source_inventory = inv
	slot_index = index
	icon.texture = null
	count_label.text = ""
	custom_minimum_size = Vector2(64, 64)
	tooltip_text = ""

# ===== 鼠标按下 =====
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var now = Time.get_ticks_msec() / 1000.0
			if now - last_click_time < DOUBLE_CLICK_TIME:
				handle_double_click()
				last_click_time = 0.0
				is_pressing = false
				return
			last_click_time = now

			press_position = event.position
			is_pressing = true
			is_dragging = false

# ===== 全局输入：松手 + 拖拽 =====
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if is_pressing:
			if is_dragging:
				attempt_drop()
				remove_drag_preview()
				dragging_slot = null
			else:
				handle_click_press()
			is_pressing = false
			is_dragging = false

	if event is InputEventMouseMotion and is_pressing and not is_dragging:
		if item == null:
			return
		if event.position.distance_to(press_position) > DRAG_THRESHOLD:
			is_dragging = true
			dragging_slot = self
			create_drag_preview()

func _process(_delta):
	if drag_preview != null:
		drag_preview.global_position = get_global_mouse_position() - Vector2(32, 32)

# ===== 点选逻辑 =====
func handle_click_press():
	if selected_slot == null:
		if item != null:
			selected_slot = self
			modulate = Color(1, 1, 0.5)
		return

	if selected_slot == self:
		modulate = Color.WHITE
		selected_slot = null
		return

	swap_with(selected_slot)
	selected_slot.modulate = Color.WHITE
	selected_slot = null

# ===== 双击：自动转移 =====
func handle_double_click():
	if item == null:
		return

	var main_loop = Engine.get_main_loop()
	if main_loop == null:
		return
	var scene = main_loop.current_scene
	if scene == null:
		return
	var hud = scene.get_node_or_null("HUD")
	if hud == null:
		return

	var my_inv = source_inventory
	var target_inv: Inventory = null

	if my_inv == Inventory:
		if hud.container_ui.visible and hud.container_ui.current_inventory:
			target_inv = hud.container_ui.current_inventory
	else:
		target_inv = Inventory

	if target_inv == null or target_inv == my_inv:
		return

	if not my_inv.remove_item(item.item_name, count):
		return
	target_inv.add_item(item, count)

	refresh_all_uis()

# ===== 拖拽预览 =====
func create_drag_preview():
	remove_drag_preview()
	drag_preview = TextureRect.new()
	drag_preview.texture = icon.texture
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview.stretch_mode = TextureRect.STRETCH_SCALE
	drag_preview.size = Vector2(64, 64)
	drag_preview.modulate = Color(1, 1, 1, 0.7)
	drag_preview.z_index = 100

	var main_loop = Engine.get_main_loop()
	var scene = main_loop.current_scene
	var hud = scene.get_node_or_null("HUD")
	if hud:
		hud.add_child(drag_preview)

func remove_drag_preview():
	if drag_preview != null:
		drag_preview.queue_free()
		drag_preview = null

# ===== 放下 =====
func attempt_drop():
	# 1. 先看鼠标下是不是弹匣格
	var mag_slot = find_magazine_slot_under_mouse()
	if mag_slot != null:
		if item == null or item.item_type != "ammo":
			return
		var player = get_tree().get_first_node_in_group("player")
		if player == null:
			return

		var space = player.mag_size - player.magazine_count
		var to_add = min(space, count)
		if to_add <= 0:
			return

		var removed = source_inventory.remove_at(slot_index, to_add)
		if removed <= 0:
			return

		player.add_to_magazine(item, removed)
		refresh_all_uis()
		return

	# 2. 看鼠标下是不是背包格
	var target = find_slot_under_mouse()
	if target == null or target == self:
		return
	swap_with(target)

# ===== 找鼠标下的弹匣格 =====
func find_magazine_slot_under_mouse():
	var mouse_pos = get_global_mouse_position()
	var main_loop = Engine.get_main_loop()
	if main_loop == null:
		return null
	var scene = main_loop.current_scene
	if scene == null:
		return null
	var hud = scene.get_node_or_null("HUD")
	if hud == null:
		return null

	# MagazineSlot 挂在 Panel 下面
	var mag_slot = hud.inventory_ui.get_node_or_null("Panel/MagazineSlot")
	if mag_slot != null and mag_slot.get_global_rect().has_point(mouse_pos):
		return mag_slot
	return null

# ===== 找鼠标下的背包格 =====
func find_slot_under_mouse():
	var mouse_pos = get_global_mouse_position()
	var main_loop = Engine.get_main_loop()
	if main_loop == null:
		return null
	var scene = main_loop.current_scene
	if scene == null:
		return null
	var hud = scene.get_node_or_null("HUD")
	if hud == null:
		return null

	var slots = []
	slots += hud.inventory_ui.grid.get_children()
	if hud.container_ui.visible:
		slots += hud.container_ui.grid.get_children()

	for slot in slots:
		if slot.get_global_rect().has_point(mouse_pos):
			return slot
	return null

# ===== 交换数据 =====
func swap_with(other: Control):
	if source_inventory == null or other.source_inventory == null:
		return

	if other.item == null:
		other.source_inventory.set_slot(other.slot_index, item, count)
		source_inventory.set_slot(slot_index, null, 0)
		refresh_all_uis()
		return

	if item != null and item.item_name == other.item.item_name:
		var space = other.item.max_stack - other.count
		var to_add = min(space, count)
		if to_add <= 0:
			return
		other.source_inventory.set_slot(other.slot_index, other.item, other.count + to_add)
		source_inventory.set_slot(slot_index, item, count - to_add)
		refresh_all_uis()
		return

	var my_item = item
	var my_count = count
	source_inventory.set_slot(slot_index, other.item, other.count)
	other.source_inventory.set_slot(other.slot_index, my_item, my_count)
	refresh_all_uis()

func refresh_all_uis():
	var main_loop = Engine.get_main_loop()
	if main_loop == null:
		return
	var scene = main_loop.current_scene
	if scene == null:
		return
	var hud = scene.get_node_or_null("HUD")
	if hud:
		hud.inventory_ui.call_deferred("refresh")
		if hud.container_ui.visible:
			hud.container_ui.call_deferred("refresh")
