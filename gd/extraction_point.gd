extends Area2D

@export var countdown_time: float = 10.0   # 倒计时秒数

var player_inside: bool = false
var counting: bool = false
var timer: float = 0.0

# 延迟结算，用于让 0 显示出来
var finishing: bool = false
var finish_delay: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		start_countdown()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		cancel_countdown()

func start_countdown() -> void:
	if counting:
		return
	counting = true
	finishing = false
	timer = countdown_time
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.show_extraction_timer(countdown_time)

func cancel_countdown() -> void:
	if not counting:
		return
	counting = false
	finishing = false
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.hide_extraction_timer()

func _process(delta: float) -> void:
	if not counting:
		return

	# 等待显示 0 的延迟
	if finishing:
		finish_delay -= delta
		if finish_delay <= 0:
			finish_extraction()
		return

	timer -= delta
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.update_extraction_timer(timer)

	if timer <= 0:
		finishing = true
		finish_delay = 0.5
		if hud:
			hud.update_extraction_timer(0)

func finish_extraction() -> void:
	counting = false
	finishing = false
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.hide_extraction_timer()
		hud.on_extraction_success()
