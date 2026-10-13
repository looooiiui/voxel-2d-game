extends RefCounted

## 瓦片区块工具
class_name ChunkCoordinateUtils

## 全局瓦片坐标 → 区块坐标
static func grid_to_chunk(grid_x: int, grid_y: int, chunk_size_x: int, chunk_size_y: int) -> Vector2i:
	var cx = int( floor( float(grid_x) / chunk_size_x ) )
	var cy = int( floor( float(grid_y) / chunk_size_y ) )
	return Vector2i(cx, cy)

## 全局瓦片坐标 → 区块坐标 + 区块内局部坐标
static func grid_to_chunk_and_local(grid_x: int, grid_y: int, chunk_size_x: int, chunk_size_y: int) -> Dictionary:
	var chunk_pos:Vector2i = grid_to_chunk(grid_x, grid_y, chunk_size_x, chunk_size_y)
	var lx = grid_x - chunk_pos.x * chunk_size_x
	var ly = grid_y - chunk_pos.y * chunk_size_y
	var local_pos:Vector2i = Vector2i(lx, ly)
	return {
		"chunk": chunk_pos,
		"local": local_pos
	}
