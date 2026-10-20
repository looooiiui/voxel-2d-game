extends InventoryBase
## 背包子类，玩家背包
class_name BackPack
## 背包初始化
func _init(size: Vector2i = Vector2i(9, 4)) -> void:
	inventory_type = InventoryType.BACKPACK
	DebugSystem.console_common_log("背包", "创建新背包，尺寸: %s" % size)
	super(size)
