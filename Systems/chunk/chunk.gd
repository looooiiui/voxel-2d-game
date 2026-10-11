# 区块类 Chunk
extends RefCounted
class_name Chunk

## 这里是网格坐标的32个格子，默认网格坐标为 Godot 32 像素距离为 1 格
const CHUNK_SIZE_X = 32
const CHUNK_SIZE_Y = 32

## 世界区块坐标再次从网格坐标上除以 CHUNK_SIZE_X, 模板默认 Vector2i(0, 0)
var world_chunk_pos:Vector2i = Vector2i(0, 0)
## 区块是否需要保存,以及区块保存的数据
var is_dirty:bool = false
var modified_cells: Dictionary = {}
# 临时原生地形缓存，不写入存档
var original_cache: Dictionary = {}

## 获取区块内方块相对坐标, 范围应为 0 到 31
func get_cell(local_pos: Vector2i) -> TileCell:
	if not check_pos_range(local_pos):
		return null
	# 存在修改过的则返回修改状态
	if modified_cells.has(local_pos):
		return modified_cells[local_pos]
	if original_cache.has(local_pos):
		return original_cache[local_pos]
	return null

## 向区块内存入新的修改方块	
func set_cell(local_pos: Vector2i, new_cell: TileCell):
	# 边界校验
	if not check_pos_range(local_pos):
		return
	modified_cells[local_pos] = new_cell
	is_dirty = true
	
## 删除，去除更改后的方块为原方块
func revert_cell(local_pos: Vector2i):
	if modified_cells.has(local_pos):
		modified_cells.erase(local_pos)
		is_dirty = true
		
func clear_original_cache():
	original_cache.clear()

## 坐标范围检查
func check_pos_range(local_pos: Vector2i) -> bool:
	if local_pos.x < 0 or local_pos.x >= CHUNK_SIZE_X or local_pos.y <0 or local_pos.y >= CHUNK_SIZE_Y:
		return false
	return true
