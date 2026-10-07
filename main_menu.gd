extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	start_button.pressed.connect(on_start)
	settings_button.pressed.connect(on_settings)
	quit_button.pressed.connect(on_quit)

func on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func on_settings() -> void:
	# 暂时先打印，以后再接设置界面
	print("设置按钮按下")

func on_quit() -> void:
	get_tree().quit()
