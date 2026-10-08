extends CharacterBody2D

# ===== 信号 =====
signal health_changed(current: int, max_health: int)
signal ammo_changed(current: int, max_ammo: int)

# ===== 可调参数 =====
@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var max_health: int = 3
@export var invincible_time: float = 1.0
@export var fire_rate: float = 0.2

@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

# ===== 弹匣设置 =====
@export var mag_size: int = 30
@export var reload_time: float = 1.5

# ===== 节点引用 =====
@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle

# ===== 状态 =====
var health: int = 3
var is_invincible: bool = false
var facing: int = 1
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var fire_timer: float = 0.0
var gravity_scale: float = 1.0

# ===== 弹匣状态（旧）=====
var current_ammo: int = 0
var is_reloading: bool = false
var reload_timer: float = 0.0

# ===== 弹匣格数据（新）=====
var magazine_item: Item = null    # 弹匣格里的物品，只接受子弹类
var magazine_count: int = 0       # 弹匣格里的子弹数量

# ===== 常量 =====
const BULLET_SCENE = preload("res://scenes/player_bullet.tscn")
const AMMO_NAME = "子弹"

func _ready() -> void:
	health = max_health
	current_ammo = 0
	add_to_group("player")
	health_changed.emit(health, max_health)
	ammo_changed.emit(current_ammo, mag_size)

func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	handle_jump(delta)
	handle_movement(delta)
	handle_shoot(delta)
	move_and_slide()

# ===== 重力 =====
func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * gravity_scale * delta
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time

# ===== 跳跃 =====
func handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0
		coyote_timer = 0

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

# ===== 移动 =====
func handle_movement(_delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0:
		velocity.x = direction * speed
		facing = sign(direction)
		sprite.flip_h = facing < 0
		muzzle.position.x = abs(muzzle.position.x) * facing
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

# ===== 射击 =====
func handle_shoot(delta: float) -> void:
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			finish_reload()
		return

	if Input.is_action_just_pressed("reload") and not is_reloading:
		start_reload()
		return

	fire_timer -= delta
	if Input.is_action_pressed("shoot") and fire_timer <= 0:
		if shoot():
			fire_timer = fire_rate

	if current_ammo <= 0 and not is_reloading:
		start_reload()

func shoot() -> bool:
	if current_ammo <= 0:
		return false

	current_ammo -= 1

	if BULLET_SCENE == null:
		return false

	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	if bullet.has_method("set_direction"):
		bullet.set_direction(facing)
	get_tree().current_scene.add_child(bullet)

	ammo_changed.emit(current_ammo, mag_size)
	return true

# ===== 换弹 =====
func start_reload() -> void:
	if is_reloading:
		return
	if not Inventory.has_item(AMMO_NAME, 1):
		return
	is_reloading = true
	reload_timer = reload_time

func finish_reload() -> void:
	is_reloading = false

	var need = mag_size - current_ammo

	var available = 0
	for slot in Inventory.items:
		if slot.item != null and slot.item.item_name == AMMO_NAME:
			available += slot.count

	var to_load = min(need, available)

	if to_load <= 0:
		return

	Inventory.remove_item(AMMO_NAME, to_load)
	current_ammo += to_load

	ammo_changed.emit(current_ammo, mag_size)

# ===== 受伤 =====
func take_damage(amount: int = 1) -> void:
	if is_invincible:
		return

	health -= amount
	health_changed.emit(health, max_health)
	is_invincible = true

	var tween = create_tween()
	tween.set_loops(5)
	tween.tween_property(sprite, "modulate:a", 0.2, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)

	await get_tree().create_timer(invincible_time).timeout
	sprite.modulate.a = 1.0
	is_invincible = false

	if health <= 0:
		die()

# ===== 死亡 =====
func die() -> void:
	get_tree().paused = true

	var canvas = CanvasLayer.new()
	get_tree().current_scene.add_child(canvas)

	var screen = load("res://scenes/result_screen.tscn").instantiate()
	canvas.add_child(screen)
	screen.setup(false, "res://scenes/level_0.tscn")

# ===== 弹匣格操作 =====
# 往弹匣格里加子弹，返回实际加进去的数量
func add_to_magazine(item: Item, amount: int) -> int:
	if item == null or item.item_type != "ammo":
		return 0

	if magazine_item == null:
		magazine_item = item
	elif magazine_item.item_name != item.item_name:
		return 0

	var space = mag_size - magazine_count
	var to_add = min(space, amount)
	magazine_count += to_add
	ammo_changed.emit(magazine_count, mag_size)
	return to_add

# 从弹匣格取走子弹，返回实际取走的数量
func remove_from_magazine(amount: int) -> int:
	var to_remove = min(magazine_count, amount)
	magazine_count -= to_remove
	if magazine_count <= 0:
		magazine_item = null
		magazine_count = 0
	ammo_changed.emit(magazine_count, mag_size)
	return to_remove

# 清空弹匣格
func clear_magazine() -> void:
	magazine_item = null
	magazine_count = 0
	ammo_changed.emit(magazine_count, mag_size)
