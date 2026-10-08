extends Control

# ===== 节点引用 =====
@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $CountLabel

# ===== 拖拽状态 =====
var press_position: Vector2 = Vector2.ZERO
var is_pressing: bool = false
var is_dragging: bool = false
const DRAG_THRESHOLD := 8.0
var drag_preview: Control = null

func _ready() -> void:
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.ammo_changed.connect(_on_ammo_changed)
		_on_ammo_changed(player.magazine_count, player.mag_size)

# ===== 弹匣格数据变化时刷新 UI =====
func _on_ammo_changed(_count: int, _max_count: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	if player.magazine_item != null and player.magazine_count > 0:
		icon.texture = player.magazine_item.icon
		count_label.text = str(player.magazine_count)
		tooltip_text = "%s\n单价: %d" % [player.magazine_item.item_name, player.magazine_item.value]
	else:
		icon.texture = null
		count_label.text = ""
		tooltip_text = ""

# ===== 鼠标按下 =====
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		press_position = event.position
		is_pressing = true
		is_dragging = false

# ===== 全局输入：松手 + 拖拽 =====
func _input(event):
	# 松手
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if is_pressing:
			if is_dragging:
				attempt_drop()
			is_pressing = false
			is_dragging = false

	# 鼠标移动启动拖拽
	if event is InputEventMouseMotion and is_pressing and not is_dragging:
		var player = get_tree().get_first_node_in_group("player")
		if player == null or player.magazine_item == null:
			return
		if event.position.distance_to(press_position) > DRAG_THRESHOLD:
			is_dragging = true
			create_drag_preview(player.magazine_item.icon)

func _process(_delta):
	if drag_preview != null:
		drag_preview.global_position = get_global_mouse_position() - Vector2(32, 32)

# ===== 拖拽预览 =====
func create_drag_preview(tex: Texture2D) -> void:
	remove_drag_preview()
	drag_preview = TextureRect.new()
	drag_preview.texture = tex
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview.stretch_mode = TextureRect.STRETCH_SCALE
	drag_preview.size = Vector2(64, 64)
	drag_preview.modulate = Color(1, 1, 1, 0.7)
	drag_preview.z_index = 100

	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.add_child(drag_preview)

func remove_drag_preview():
	if drag_preview != null:
		drag_preview.queue_free()
		drag_preview = null

func attempt_drop() -> void:
	remove_drag_preview()

	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.magazine_item == null:
		return

	var mouse_pos = get_global_mouse_position()
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud == null:
		return

	# 1. 先找鼠标下有没有背包格
	var slots = hud.inventory_ui.grid.get_children()
	for slot in slots:
		if slot.get_global_rect().has_point(mouse_pos):
			drop_to_inventory(player, Inventory)
			return

	# 2. 再找鼠标下有没有容器格
	if hud.container_ui.visible and hud.container_ui.current_inventory != null:
		var container_slots = hud.container_ui.grid.get_children()
		for slot in container_slots:
			if slot.get_global_rect().has_point(mouse_pos):
				drop_to_inventory(player, hud.container_ui.current_inventory)
				return

# 把弹匣格里的子弹全部放回指定背包
func drop_to_inventory(player: Node, target_inv: Inventory) -> void:
	var item = player.magazine_item
	var count = player.magazine_count
	player.clear_magazine()
	target_inv.add_item(item, count)
	refresh_all()

# ===== 刷新 UI =====
func refresh_all() -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.inventory_ui.call_deferred("refresh")
		if hud.container_ui.visible:
			hud.container_ui.call_deferred("refresh")
