extends Control

@onready var grid: GridContainer = $CenterContainer/GridContainer
@onready var back_button: Button = $BackButton

# 关卡总数，比如 0、1、2、3 共 4 关就填 4
const TOTAL_LEVELS = 4

func _ready() -> void:
	# 动态生成关卡按钮
	for i in range(0, TOTAL_LEVELS):
		var btn = Button.new()

		if i == 0:
			btn.text = "教学关"
		else:
			btn.text = "第 %d 关" % i

		btn.custom_minimum_size = Vector2(120, 80)

		var level_num = i
		btn.pressed.connect(func(): start_level(level_num))

		grid.add_child(btn)

	back_button.pressed.connect(go_back)

func start_level(level_num: int) -> void:
	var path = "res://scenes/level_%d.tscn" % level_num
	get_tree().change_scene_to_file(path)

func go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
