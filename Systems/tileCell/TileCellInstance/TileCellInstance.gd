extends RefCounted

## 瓦片实例，包含名字，以及属性
class_name TileCellInstance

var name: String = ""
var attrubute: TileCellAttribute

## 初始化完整方块，需要
func _init(new_name: String, newAttrubute: TileCellAttribute) -> void:
	name = new_name
	attrubute = newAttrubute

## 更改瓦片属性
func change_cell_attribute(newAttribute: TileCellAttribute) -> void:
	attrubute = newAttribute

## 获得瓦片属性
func get_cell_attribute() -> TileCellAttribute:
	return attrubute

## 克隆方法，返回克隆属性方块
func copy() -> TileCellInstance:
	var new_cell = TileCellInstance.new(name, attrubute)
	return new_cell
