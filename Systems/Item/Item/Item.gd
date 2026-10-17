extends RefCounted
## 运行时物品对象，存入背包 / 世界掉落物
## 持有静态模板 ItemInstance（来自注册表）
class_name Item
## 物品静态模板
var item_instance: ItemInstance
var current_stack_num: int = 1

## 初始化：绑定物品模板
func _init(new_instance: ItemInstance) -> void:
	item_instance = new_instance

## 更换物品模板
func change_cell_instance(new_item_instance: ItemInstance) -> void:
	item_instance = new_item_instance
	
## 获取物品属性模板
func get_item_attribute() -> ItemAttribute:
	if item_instance == null:
		# 兜底默认，防止空引用报错
		return ItemAttributes.OriginalAttrType.get("STONE")
	return item_instance.get_item_attribute()

## 获取物品实例模板
func get_item_instance() -> ItemInstance:
	return item_instance

## 克隆：生成一份新的Item（共用同一个ItemInstance模板引用，浅拷贝）
func copy() -> Item:
	var new_item = Item.new(item_instance)
	return new_item

## 判断是否是同一种物品：比对 ItemInstance 引用，只有完全相同实例才能堆叠
func is_same_item(other: Item) -> bool:
	if other == null:
		return false
	# 直接对比ItemInstance引用，这才是物品/方块的本体模板
	return self.item_instance == other.item_instance

## 获得当前堆叠数量
func get_current_stack_num() -> int:
	return current_stack_num
	
## 更改堆叠数量
func change_stack_num(new_stack: int) -> void:
	current_stack_num = new_stack
