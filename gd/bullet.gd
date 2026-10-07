extends Area2D

# ===== 可调参数 =====
@export var speed: float = 600.0        # 子弹飞行速度
@export var damage: int = 1             # 伤害值
@export var lifetime: float = 2.0       # 存活时间（秒），超时自动销毁
@export var direction: int = 1          # 1 = 右，-1 = 左

func _ready() -> void:
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# 超时自动销毁
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# 沿水平方向飞行
	position.x += direction * speed * delta

# ===== 设置方向（由发射者调用）=====
func set_direction(dir: int) -> void:
	direction = dir
	# 翻转子弹贴图，让它朝向正确
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = dir < 0

# ===== 碰撞处理 =====
func _on_body_entered(body: Node2D) -> void:
	# 碰到地形或其他物理体，销毁子弹
	# 如果碰到的是有 take_damage 方法的对象，造成伤害
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	# 碰到 Area2D 类型的受击区域
	if area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
