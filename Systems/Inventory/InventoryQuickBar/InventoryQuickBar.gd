extends InventoryBase

## 快捷栏(玩家手持物品栏)
class_name InventoryQuickBar

## 快捷栏默认 9 列 一行
func _init(size: Vector2i = Vector2i(9, 1)) -> void:
	inventory_type = InventoryType.QUICK_BAR
	DebugSystem.console_common_log("快捷栏", "创建新快捷栏，尺寸: %s" % size)
	super(size)
