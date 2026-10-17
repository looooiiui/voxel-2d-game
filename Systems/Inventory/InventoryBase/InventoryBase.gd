extends RefCounted
## 物品栏类父类，存储 Item 类，保存实体身上的物品
## 其他背包，快捷栏可继承物品栏类
## 需要注意的是，背包使用的查找坐标为 列 + 行
class_name InventoryBase

# 物品发生变更时触发
signal inventory_changed()

## 容器大小，供给外部获取(列，行)
var inventory_size: Vector2i = Vector2i(0, 0)
## 实际容器，存储物品槽
var slot_storage: Array[ItemSlot] = []

func _init(size: Vector2i) -> void:
	inventory_size = size
	## 构建容器
	var container_size = inventory_size.x * inventory_size.y
	slot_storage.resize(container_size)
	for i in range(slot_storage.size()):
		slot_storage[i] = ItemSlot.new()

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
	emit_signal("inventory_changed")
	return true

# 清空指定索引槽
func clear_slot(idx:int) -> bool:
	var slot = get_slot_by_index(idx)
	if slot == null:
		return false
	slot.clear()
	emit_signal("inventory_changed")
	return true
