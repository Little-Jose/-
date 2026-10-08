extends CanvasLayer

# ===== 节点引用 =====
@onready var health_label: Label = $HealthLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var inventory_ui: Control = $InventoryUI
@onready var container_ui: Control = $ContainerUI
@onready var pause_menu: Control = $PauseMenu
@onready var extraction_label: Label = $ExtractionLabel

func _ready() -> void:
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(update_health)
		player.ammo_changed.connect(update_ammo)
		update_health(player.health, player.max_health)
		update_ammo(player.magazine_count, player.mag_size)

	Inventory.inventory_changed.connect(_on_inventory_changed)

	inventory_ui.visible = false
	container_ui.visible = false
	pause_menu.visible = false
	extraction_label.visible = false

	$PauseMenu/VBoxContainer/ResumeButton.pressed.connect(resume_game)
	$PauseMenu/VBoxContainer/MenuButton.pressed.connect(go_to_main_menu)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

	if event.is_action_pressed("inventory") and not get_tree().paused:
		inventory_ui.visible = not inventory_ui.visible
		if inventory_ui.visible:
			inventory_ui.refresh()

# ===== 血量与弹药 =====
func update_health(current: int, max_health: int) -> void:
	health_label.text = "HP: %d / %d" % [current, max_health]

func update_ammo(current: int, max_ammo: int) -> void:
	var total_ammo = 0
	for slot in Inventory.items:
		if slot.item != null and slot.item.item_name == "子弹":
			total_ammo += slot.count
	ammo_label.text = "弹药: %d / %d" % [current, total_ammo]

func _on_inventory_changed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		update_ammo(player.magazine_count, player.mag_size)

# ===== 容器 =====
func open_container(inv: Inventory) -> void:
	container_ui.show_inventory(inv)
	inventory_ui.visible = true
	inventory_ui.refresh()

func close_container() -> void:
	container_ui.hide_inventory()
	inventory_ui.visible = false

# ===== 暂停 =====
func toggle_pause() -> void:
	var paused = not get_tree().paused
	get_tree().paused = paused
	pause_menu.visible = paused

func resume_game() -> void:
	get_tree().paused = false
	pause_menu.visible = false

func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ===== 撤离倒计时 =====
func show_extraction_timer(_total_time: float) -> void:
	extraction_label.visible = true
	extraction_label.text = "等待撤离..."

func update_extraction_timer(remain: float) -> void:
	var seconds = int(ceil(remain))
	extraction_label.text = "等待撤离...\n%d" % max(seconds, 0)

func hide_extraction_timer() -> void:
	extraction_label.visible = false

# ===== 撤离成功 =====
func on_extraction_success() -> void:
	get_tree().paused = true

	# 算背包 + 弹匣格的总价值
	var total_value = 0
	for slot in Inventory.items:
		if slot.item != null:
			total_value += slot.item.value * slot.count

	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.magazine_item != null:
		total_value += player.magazine_item.value * player.magazine_count

	var canvas = CanvasLayer.new()
	get_tree().current_scene.add_child(canvas)
	var screen = load("res://scenes/result_screen.tscn").instantiate()
	canvas.add_child(screen)
	screen.setup(true, "res://scenes/level_0.tscn", total_value)
