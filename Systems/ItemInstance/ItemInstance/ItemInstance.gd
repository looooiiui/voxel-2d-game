extends RefCounted

## 物品实体父类
class_name ItemInstance

var attribute: ItemAttribute
var name: String

## 初始化物品实体
func _init(new_name: String, new_attribute: ItemAttribute) -> void:
	name = new_name
	attribute = new_attribute
	
## 更改物品属性
func change_item_attribute(newAttribute: ItemAttribute) -> void:
	attribute = newAttribute

## 获得物品属性
func get_item_attribute() -> ItemAttribute:
	return attribute

## 获得物品名字
func get_item_name() -> String:
	return name

## 克隆方法，返回克隆属性物品
func copy() -> ItemInstance:
	var new_cell = ItemInstance.new(name, attribute)
	return new_cell
