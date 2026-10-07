extends CharacterBody2D

# ===== 可调参数 =====
@export var patrol_speed: float = 60.0
@export var chase_speed: float = 120.0
@export var detect_range: float = 1200.0
@export var stop_distance: float = 200.0
@export var fire_rate: float = 1.0

# ===== 掉落配置 =====
@export var drop_items: Array[Item] = []
@export var drop_amounts: Array[int] = []
@export var drop_container_texture: Texture2D
@export var drop_sprite_scale: Vector2 = Vector2.ONE
@export var drop_collision_scale: Vector2 = Vector2.ONE

# ===== 血量 =====
@export var max_health: int = 3
var health: int = 3

# ===== 节点引用 =====
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var muzzle: Marker2D = $Muzzle
@onready var wall_ray: RayCast2D = $WallRay
@onready var edge_ray: RayCast2D = $EdgeRay
@onready var detect_ray: RayCast2D = $DetectRay

# ===== 状态 =====
var direction: int = 1
var player: Node2D = null
var fire_timer: float = 0.0
var turn_cooldown: float = 0.0

const BULLET_SCENE = preload("res://scenes/enemy_bullet.tscn")
const CONTAINER_SCENE = preload("res://scenes/container.tscn")

func _ready() -> void:
	health = max_health
	player = get_tree().get_first_node_in_group("player")
	detect_ray.target_position = Vector2(detect_range, 0)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if player == null:
		patrol(delta)
		move_and_slide()
		return

	var can_see = detect_ray.is_colliding() and detect_ray.get_collider() == player

	if can_see:
		var dx = player.global_position.x - global_position.x
		var distance = abs(dx)

		if distance > 20.0:
			direction = sign(dx)

		if distance > stop_distance:
			velocity.x = direction * chase_speed
		else:
			velocity.x = 0
			try_shoot(delta)
	else:
		patrol(delta)

	update_visual_direction()
	move_and_slide()

func patrol(delta: float) -> void:
	turn_cooldown -= delta
	if turn_cooldown > 0:
		velocity.x = direction * patrol_speed
		return

	if is_on_wall() or not edge_ray.is_colliding():
		direction *= -1
		turn_cooldown = 0.3

	velocity.x = direction * patrol_speed

func try_shoot(delta: float) -> void:
	fire_timer -= delta
	if fire_timer <= 0:
		shoot()
		fire_timer = fire_rate

func shoot() -> void:
	if BULLET_SCENE == null:
		return
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	if bullet.has_method("set_direction"):
		bullet.set_direction(direction)
	get_tree().current_scene.add_child(bullet)

func update_visual_direction() -> void:
	if direction > 0:
		sprite.flip_h = false
		collision.position.x = abs(collision.position.x)
		muzzle.position.x = abs(muzzle.position.x)
		wall_ray.position.x = abs(wall_ray.position.x)
		edge_ray.position.x = abs(edge_ray.position.x)
		detect_ray.position.x = abs(detect_ray.position.x)
		detect_ray.target_position = Vector2(detect_range, 0)
	else:
		sprite.flip_h = true
		collision.position.x = -abs(collision.position.x)
		muzzle.position.x = -abs(muzzle.position.x)
		wall_ray.position.x = -abs(wall_ray.position.x)
		edge_ray.position.x = -abs(edge_ray.position.x)
		detect_ray.position.x = -abs(detect_ray.position.x)
		detect_ray.target_position = Vector2(-detect_range, 0)

# ===== 受伤与死亡 =====
func take_damage(amount: int = 1) -> void:
	health -= amount
	if health <= 0:
		drop_loot()
		queue_free()

func drop_loot() -> void:
	if CONTAINER_SCENE == null:
		return
	var container = CONTAINER_SCENE.instantiate()
	# 从小兵位置稍微抬高一点生成，让容器自由落体
	container.global_position = global_position + Vector2(0, -32)
	get_tree().current_scene.add_child(container)

	# 应用贴图和缩放
	if drop_container_texture:
		container.sprite.texture = drop_container_texture
	container.sprite.scale = drop_sprite_scale
	container.collision.scale = drop_collision_scale

	# 加战利品
	for i in range(drop_items.size()):
		if drop_items[i] == null:
			continue
		var amount = 1
		if i < drop_amounts.size():
			amount = drop_amounts[i]
		container.container_inventory.add_item(drop_items[i], amount)
