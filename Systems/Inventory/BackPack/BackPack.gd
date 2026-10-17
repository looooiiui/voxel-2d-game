extends InventoryBase
## 背包子类，玩家背包
class_name BackPack
## 背包初始化
func _init(size: Vector2i = Vector2i(4, 8)) -> void:
	DebugSystem.console_common_log("背包", "创建新背包，尺寸: %s" % size)
	super(size)

## 尝试往背包里面添加物品，支持堆叠
## 返回true成功；false背包已满无法放入
func try_add_item(new_item: Item) -> bool:
	# 第一步：优先寻找【同物品且还有堆叠空位】的槽位
	for index in range(slot_storage.size()):
		var slot = slot_storage[index]
		var slot_item = slot.get_item()
		# 槽位有物品，并且是同一种物品
		if slot_item != null and slot_item.is_same_item(new_item):
			var max_stack_num = slot_item.get_item_attribute().get_max_stack_num()
			var remain_stack = max_stack_num - slot_item.get_current_stack_num()
			if remain_stack > 0:
				# 可以堆叠，直接叠加数量
				var add_count = min(new_item.get_current_stack_num(), remain_stack)
				slot_item.change_stack_num(slot_item.get_current_stack_num() + add_count)
				new_item.change_stack_num(new_item.get_current_stack_num() - add_count) 
				DebugSystem.console_common_log("背包", "物品堆叠， 槽位%d， 叠加%d个， 总共堆叠: %d, 剩余待放:%d" % [index, add_count, slot_item.get_current_stack_num(), new_item.current_stack_num])
				# 待放入物品已经全部塞完，直接返回成功
				if new_item.current_stack_num <= 0:
					return true
	
	# 第二步：没有可堆叠槽位，寻找空槽位放入新物品
	for index in range(slot_storage.size()):
		var slot = slot_storage[index]
		var slot_item = slot.get_item()
		if slot_item == null:
			slot.add_item(new_item)
			DebugSystem.console_common_log("背包", "空槽放入物品(槽位%s): %s" % [index, new_item])
			return true
	
	# 没有可堆叠位置、也没有空槽 → 背包满
	DebugSystem.console_common_log("背包", "背包已满，无法放入物品")
	return false
