## tileCell 单个方块属性
extends RefCounted
class_name TileCell

var tile_cell_ins: TileCellInstance

## 初始化完整方块，需要
func _init(new_tile_cell_ins: TileCellInstance) -> void:
	tile_cell_ins = new_tile_cell_ins

## 更改瓦片对应实例
func change_cell_instance(new_tile_cell_ins: TileCellInstance) -> void:
	tile_cell_ins = new_tile_cell_ins
	
## 获得瓦片属性
func get_cell_attribute() -> TileCellAttribute:
	if tile_cell_ins == null:
		return TileCellAttributes.OriginalBlockType.get("AIR")
	return tile_cell_ins.get_cell_attribute()

## 获得方块实例
func get_cell_instance() -> TileCellInstance:
	return tile_cell_ins

## 克隆方法，返回克隆属性方块
func copy() -> TileCell:
	var new_cell = TileCell.new(tile_cell_ins)
	return new_cell
