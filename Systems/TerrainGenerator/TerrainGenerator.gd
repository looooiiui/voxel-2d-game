extends RefCounted
class_name TerrainGenerator

var seed: int
var noise:Noise

## 初始化地图生成器的种子与噪声生成器
func _init(p_seed: int) -> void:
	seed = p_seed
	noise = FastNoiseLite.new()
	noise.seed = seed
	# 被推荐的 2D Simplex 噪声，地形生成
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.45
	noise.fractal_lacunarity = 2.0
	noise.frequency = 0.025
	
## 完整原始地形(完整区块)
func generate_chunk(chunk_world_pos: Vector2i, chunk_size_x: int, chunk_size_y: int) -> Dictionary:
	var result:Dictionary = {}
	for local_x in range(chunk_size_x):
		for local_y in range(chunk_size_y):
			var local_pos = Vector2i(local_x, local_y)
			# 计算全局瓦片坐标，保证跨区块连续
			var global_tile_x = chunk_world_pos.x * chunk_size_x + local_x
			var global_tile_y = chunk_world_pos.y * chunk_size_y + local_y
			var tile = _generate_single_tile(global_tile_x, global_tile_y)
			
			##if chunk_world_pos.x < 0:
			##	DebugSystem.console_common_log("生成器", "当前生成坐标x: %s %s" % [global_tile_x, global_tile_y])
			##	DebugSystem.console_common_log("生成器生成", "当前生成对应物品ID: %s" % tile.tile_type_id)
			result[local_pos] = tile
	return result
	
## 单个方块生成
func _generate_single_tile(gx:int, gy:int) -> TileCell:
	# FastNoiseLite.Get_noise_2d，输入浮点数
	var n_val = noise.get_noise_2d(float(gx), float(gy))
	var cell = TileCell.new(TileCellInstances.OriginalInstancesType.get("air"))
	# n_val范围 -1 ~ 1
	if n_val > 0.1:
		cell.change_cell_instance(TileCellInstances.OriginalInstancesType.get("stone"))
	else:
		cell.change_cell_instance(TileCellInstances.OriginalInstancesType.get("air"))
	return cell
