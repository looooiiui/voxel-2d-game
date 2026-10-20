extends RefCounted

## 瓦片实例，包含名字，以及属性
class_name TileCellInstance

var name: String = ""
## drop_item 类型为 String，通过这个直接查找对应物品实例表内的实例
var drop_item = null
var attribute: TileCellAttribute

## 初始化完整方块，需要
func _init(new_name: String, newAttribute: TileCellAttribute, new_drop_item) -> void:
	name = new_name
	attribute = newAttribute
	drop_item = new_drop_item

## 更改瓦片属性
func change_cell_attribute(newAttribute: TileCellAttribute) -> void:
	attribute = newAttribute

## 获得瓦片属性
func get_cell_attribute() -> TileCellAttribute:
	return attribute

## 获得瓦片掉落物映射
func get_tile_drop_item() -> String:
	return drop_item
	
## 克隆方法，返回克隆属性方块
func copy() -> TileCellInstance:
	var new_cell = TileCellInstance.new(name, attribute, drop_item)
	return new_cell
