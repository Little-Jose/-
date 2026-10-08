extends Control

@onready var result_label: Label = $ResultLabel
@onready var retry_button: Button = $RetryButton
@onready var menu_button: Button = $MenuButton
@onready var value_label: Label = $ValueLabel

var is_win: bool = false
var current_level_path: String = ""

func _ready() -> void:
	retry_button.pressed.connect(on_retry)
	menu_button.pressed.connect(on_menu)

func setup(win: bool, level_path: String, total_value: int = 0) -> void:
	is_win = win
	current_level_path = level_path

	if win:
		result_label.text = "撤离成功"
		result_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
		value_label.text = "带出总价值: %d" % total_value

		retry_button.visible = false
		retry_button.disabled = true
		retry_button.modulate.a = 0.0
		retry_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		result_label.text = "任务失败"
		result_label.add_theme_color_override("font_color", Color.RED)
		value_label.text = ""

		retry_button.visible = true
		retry_button.disabled = false
		retry_button.modulate.a = 1.0
		retry_button.mouse_filter = Control.MOUSE_FILTER_STOP

func on_retry() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(current_level_path)

func on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
