extends RefCounted

## 方块注册表类，用于注册方块
class_name TileCellAttribute

static var current_num: int = 0

func _init(new_hp: int = -1, new_solid_state:bool = true, new_light: int = 0, new_id: int = -1) -> void:
	if new_id >= 0:
		# 使用数据表中显式指定的ID，保证重复加载时ID稳定
		tile_type_id = new_id
		if current_num <= new_id:
			current_num = new_id + 1
	else:
		# 未指定ID时自动增长
		tile_type_id = current_num
		current_num = current_num + 1
	# 填入原版状态
	hp = new_hp
	is_solid = new_solid_state
	light_emission = new_light

## 重置注册表ID
static func reset_counter():
	current_num = 0

## 这里是方块的基本属性
## id : 0 默认空气
## hp : -1 不可破坏
## solid: 方块类型
## light_emission 照明强度
var tile_type_id: int = 0 
var hp: int = -1
var is_solid: bool = false
var light_emission: int = 0
