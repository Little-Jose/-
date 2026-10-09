extends Area2D

@export var target_hint: Node = null
@export var show_on_enter: bool = true   # true = 进入时显示，false = 进入时隐藏

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if target_hint != null:
			target_hint.visible = show_on_enter
