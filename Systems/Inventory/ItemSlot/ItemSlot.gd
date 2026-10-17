extends RefCounted

## 物品栏槽位，存储一个物品格子，内含 Item
class_name ItemSlot

## 槽位存储的实际物品
var item: Item = null
## 槽位锁定标志
var locked: bool = false

## 设置槽内物品
func set_item(new_item: Item) -> void:
	item = new_item
	
## 清空槽
func clear() -> void:
	item = null
	
## 获取当前物品
func get_item() -> Item:
	return item

## 增加堆叠数量
## 返回实际成功增加的数量（受物品模板最大堆叠限制）
func add_stack(amount: int) -> int:
	if item == null or amount <= 0:
		return 0
	var max_stack = item.item_instance.get_item_attribute().max_stack
	var can_add = min(amount, max_stack - item.current_stack_num)
	item.current_stack_num += can_add
	return can_add

## 减少堆叠数量
## 返回实际扣除数量；扣到0自动清空槽
func subtract_stack(amount: int) -> int:
	if item == null or amount <= 0:
		return 0
	var reduce = min(amount, item.current_stack_num)
	item.current_stack_num -= reduce
	if item.current_stack_num <= 0:
		clear()
	return reduce

## 判断槽是否为空
func is_empty() -> bool:
	return item == null
	
 ## 添加对应物品
func add_item(new_item: Item):
	item = new_item
