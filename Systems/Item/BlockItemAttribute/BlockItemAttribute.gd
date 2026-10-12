extends ItemAttribute

## 方块物品属性
class_name BlockItemAttribute

func _init(new_id: int, new_stack: int = DEFAULT_STACK) -> void:
	super._init(new_id, new_stack)
	type = ItemAttribute.ItemType.BLOCK
