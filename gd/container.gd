@tool
extends CharacterBody2D

@export var loot_items: Array[Item] = []
@export var loot_amounts: Array[int] = []

@export var container_texture: Texture2D:
	set(value):
		container_texture = value
		if sprite:
			sprite.texture = value

@export var sprite_scale: Vector2 = Vector2.ONE:
	set(value):
		sprite_scale = value
		if sprite:
			sprite.scale = value

@export var collision_scale: Vector2 = Vector2.ONE:
	set(value):
		collision_scale = value
		if collision:
			collision.scale = value

@export var detect_scale: Vector2 = Vector2.ONE:
	set(value):
		detect_scale = value
		if detect_area:
			var col = detect_area.get_node_or_null("CollisionShape2D")
			if col:
				col.scale = value

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var detect_area: Area2D = $DetectArea
@onready var container_inventory: Inventory = $Inventory

var player_inside: Node2D = null
var is_open: bool = false

func _ready() -> void:
	# 重新应用一次，防止 @onready 变量还没准备好
	if container_texture:
		sprite.texture = container_texture
	sprite.scale = sprite_scale
	collision.scale = collision_scale
	var col = detect_area.get_node_or_null("CollisionShape2D")
	if col:
		col.scale = detect_scale

	detect_area.body_entered.connect(_on_body_entered)
	detect_area.body_exited.connect(_on_body_exited)

	if not Engine.is_editor_hint():
		fill_loot()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func fill_loot() -> void:
	var inv = container_inventory
	inv.items.clear()
	inv._ensure_slots()

	var slot_index = 0
	for i in range(loot_items.size()):
		if loot_items[i] == null:
			continue
		var amount = 1
		if i < loot_amounts.size():
			amount = loot_amounts[i]
		var item = loot_items[i]
		var max_per = item.max_stack
		while amount > 0 and slot_index < inv.max_slots:
			var put = min(max_per, amount)
			inv.set_slot(slot_index, item, put)
			amount -= put
			slot_index += 1

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_inside:
		player_inside = null
		if is_open:
			close_container()

func _input(event):
	if Engine.is_editor_hint():
		return
	if player_inside and event.is_action_pressed("interact"):
		if is_open:
			close_container()
		else:
			open_container()

func open_container() -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.open_container(container_inventory)
		is_open = true

func close_container() -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.close_container()
		is_open = false
