extends Resource
class_name Item

@export var item_name: String = "物品"
@export var icon: Texture2D
@export var max_stack: int = 60
@export var description: String = ""
@export var value: int = 0
@export var item_type: String = "misc"   # 物品类型：ammo / medkit / keycard ...
