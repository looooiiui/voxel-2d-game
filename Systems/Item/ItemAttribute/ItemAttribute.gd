extends RefCounted
class_name ItemAttribute

static var current_num: int = 0

enum ItemType {
	BLOCK = 0,
	TOOL = 1,
}

const DEFAULT_STACK: int = 64

## 物品属性，与方块类似，同框架
var item_id: int
var max_stack: int = DEFAULT_STACK
var type: ItemType = ItemType.BLOCK

## 初始化父类模板
func _init(new_id: int, new_stack: int = DEFAULT_STACK) -> void:
	if new_id >= 0:
		# 使用数据表中显式指定的ID，保证重复加载时ID稳定
		item_id = new_id
		if current_num <= new_id:
			current_num = new_id + 1
	else:
		# 未指定ID时自动增长
		item_id = current_num
		current_num = current_num + 1
	
	max_stack = new_stack

## 重置注册表ID
static func reset_counter():
	current_num = 0
