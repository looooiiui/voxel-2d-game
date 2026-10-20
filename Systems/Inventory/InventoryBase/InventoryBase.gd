extends RefCounted
## 物品栏类父类，存储 Item 类，保存实体身上的物品
## 其他背包，快捷栏可继承物品栏类
## 需要注意的是，背包使用的查找坐标为 列 + 行
class_name InventoryBase
## 区分当前物品栏种类
enum InventoryType {
	BACKPACK,
	QUICK_BAR,
	EQUIPMENT, # 预留装备栏，以后直接扩展
	STORAGE_BOX # 预留储物箱
}
## 物品发生变更时触发
## 参数：变更坐标、物品名称、物品数量、容器类型
signal inventory_changed(
	change_pos: Vector2i, 
	new_item_name: String, 
	new_item_num: int,
	inv_type: InventoryType
	)
## 容器大小，供给外部获取(列，行)
var inventory_size: Vector2i = Vector2i(0, 0)
## 实际容器，存储物品槽
var slot_storage: Array[ItemSlot] = []
var inventory_type: InventoryType

func _init(size: Vector2i) -> void:
	inventory_size = size
	## 构建容器
	var container_size = inventory_size.x * inventory_size.y
	slot_storage.resize(container_size)
	for i in range(slot_storage.size()):
		slot_storage[i] = ItemSlot.new()

## 获得背包尺寸
func get_inventory_size() -> Vector2i:
	return inventory_size
		
## 尝试往物品栏里面添加物品，支持堆叠
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
				# 发生堆叠则发射信号 ( 位置: 列 + 行 )
				var emit_pos: Vector2i = index_to_grid(index)
				var slot_item_name: String = slot_item.get_item_instance().get_item_name()
				var slot_num: int = slot_item.get_current_stack_num()
				# 发送信号
				inventory_changed.emit(emit_pos, slot_item_name, slot_num, inventory_type)
				DebugSystem.console_common_log("物品栏", "物品堆叠， 槽位%d， 叠加%d个， 总共堆叠: %d, 剩余待放:%d" % [index, add_count, slot_item.get_current_stack_num(), remain_stack])
				# 待放入物品已经全部塞完，直接返回成功
				if new_item.current_stack_num <= 0:
					return true
	
	# 第二步：没有可堆叠槽位，寻找空槽位放入新物品
	for index in range(slot_storage.size()):
		var slot = slot_storage[index]
		var slot_item = slot.get_item()
		if slot_item == null:
			slot.add_item(new_item)
			DebugSystem.console_common_log("物品栏", "空槽放入物品(槽位%s): %s" % [index, new_item])
			var emit_pos: Vector2i = index_to_grid(index)
			var slot_item_name: String = new_item.get_item_instance().get_item_name()
			var slot_num: int = new_item.get_current_stack_num()
			# 发送信号
			inventory_changed.emit(emit_pos, slot_item_name, slot_num, inventory_type)
			return true
	
	# 没有可堆叠位置、也没有空槽 → 背包满
	DebugSystem.console_common_log("物品栏", "物品栏已满，无法放入物品")
	return false

## 将本容器idx的物品移动到目标inventory的target_idx槽
func try_move_to_other_inventory(target_inv: InventoryBase, from_idx: int, target_idx: int) -> bool:
	var source_slot = get_slot_by_index(from_idx)
	var dest_slot = target_inv.get_slot_by_index(target_idx)
	if source_slot == null or dest_slot == null:
		return false
	
	var move_item = source_slot.get_item()
	if move_item == null:
		return false
	# 目标槽已有物品，不能直接覆盖，走swap逻辑
	if dest_slot.get_item() != null:
		# 取出目标槽物品，互换
		var dest_item = dest_slot.get_item()
		source_slot.set_item(dest_item)
		dest_slot.set_item(move_item)
	else:
		# 目标是空槽，直接移过去，原槽清空
		dest_slot.set_item(move_item)
		source_slot.clear()
	
	# ========== 修改：分别发送源槽、目标槽更新信号 ==========
	var src_pos = index_to_grid(from_idx)
	var dst_pos = target_inv.index_to_grid(target_idx)
	# 源容器源槽
	_emit_slot_update(src_pos, source_slot)
	# 目标容器目标槽
	target_inv._emit_slot_update(dst_pos, dest_slot)

	DebugSystem.console_common_log("物品栏", "跨容器移动：源槽%d → 目标槽%d" % [from_idx, target_idx])
	return true

## 将本容器(col,row)的物品移动到目标容器的(t_col,t_row)网格位置
func try_move_to_other_inventory_grid(target_inv: InventoryBase, col: int, row: int, t_col: int, t_row: int) -> bool:
	var from_idx = grid_to_index(col, row)
	var target_idx = target_inv.grid_to_index(t_col, t_row)
	if from_idx == -1 or target_idx == -1:
		return false
	return try_move_to_other_inventory(target_inv, from_idx, target_idx)

## 尝试交换当前容器内两个槽位物品
## @param idx_a 源槽索引
## @param idx_b 目标槽索引
## @return true 交换成功，false 交换失败
func try_swap_slot(idx_a: int, idx_b: int) -> bool:
	# 同一个槽，无需操作
	if idx_a == idx_b:
		return true
	
	var slot_a = get_slot_by_index(idx_a)
	var slot_b = get_slot_by_index(idx_b)
	# 索引非法
	if slot_a == null or slot_b == null:
		return false
	# 取出两个槽里面当前物品
	var item_a: Item = slot_a.get_item()
	var item_b: Item = slot_b.get_item()
	# 互换
	slot_a.set_item(item_b)
	slot_b.set_item(item_a)
	DebugSystem.console_common_log("物品栏", "交换槽位 %d <-> %d" % [idx_a, idx_b])

	# ========== 修改：交换两个槽，分别触发两次更新信号 ==========
	var pos_a = index_to_grid(idx_a)
	var pos_b = index_to_grid(idx_b)
	_emit_slot_update(pos_a, slot_a)
	_emit_slot_update(pos_b, slot_b)
	return true
	
## 尝试交换当前容器内两个网格位置的物品（列+行形式）
## @param col_a, row_a 源槽：列、行
## @param col_b, row_b 目标槽：列、行
## @return true交换成功；false失败（越界等）
func try_swap_slot_grid(col_a: int, row_a: int, col_b: int, row_b: int) -> bool:
	# 网格转一维索引
	var idx_a = grid_to_index(col_a, row_a)
	var idx_b = grid_to_index(col_b, row_b)
	
	# 越界检查
	if idx_a == -1 or idx_b == -1:
		return false
	
	# 调用已经写好的一维索引交换函数
	return try_swap_slot(idx_a, idx_b)

# 网格坐标(col列,row行) → 一维索引
func grid_to_index(col: int, row: int) -> int:
	# 边界检查，超出范围直接返回 -1
	if col < 0 or col >= inventory_size.x or row <0 or row >= inventory_size.y:
		return -1
	return row * inventory_size.x + col

# 一维索引 → 网格坐标 (col, row)
func index_to_grid(idx: int) -> Vector2i:
	if idx < 0 or idx >= slot_storage.size():
		return Vector2i(-1,-1)
	var row: int = idx / inventory_size.x
	var col: int = idx % inventory_size.x
	return Vector2i(col, row)

# 通过索引获取槽，自带越界保护
func get_slot_by_index(idx: int) -> ItemSlot:
	if idx < 0 or idx >= slot_storage.size():
		return null
	return slot_storage[idx]

# 通过网格坐标获取槽
func get_slot_by_grid(col: int, row: int) -> ItemSlot:
	var idx = grid_to_index(col, row)
	if idx == -1:
		return null
	return get_slot_by_index(idx)

# 设置指定索引槽内物品，自动触发信号
func set_slot_item(idx:int, new_item:Item) -> bool:
	var slot = get_slot_by_index(idx)
	if slot == null:
		return false
	slot.set_item(new_item)
	var pos = index_to_grid(idx)
	_emit_slot_update(pos, slot)
	return true

# 清空指定索引槽
func clear_slot(idx:int) -> bool:
	var slot = get_slot_by_index(idx)
	if slot == null:
		return false
	slot.clear()
	var pos = index_to_grid(idx)
	_emit_slot_update(pos, slot)
	return true

## 【私有辅助函数】统一发射槽更新信号
## 读取槽内当前物品信息，填充参数发送 inventory_changed
func _emit_slot_update(grid_pos:Vector2i, slot:ItemSlot) -> void:
	var item = slot.get_item()
	var item_name:String
	var item_count:int
	if item == null:
		# 空槽：名字为空字符串，数量0
		item_name = ""
		item_count = 0
	else:
		item_name = item.get_item_instance().get_item_name()
		item_count = item.get_current_stack_num()
	inventory_changed.emit(grid_pos, item_name, item_count, inventory_type)
