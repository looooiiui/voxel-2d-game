extends RefCounted
class_name World

# 方块数据发生变更时触发，携带修改的全局方块坐标
signal tile_cell_updated(global_tile_pos:Vector2i)

var seed: int
var terrain_generator: TerrainGenerator
## 已加载的区块 Key: 区块坐标Vector2i, value: Chunk
var loaded_chunks: Dictionary[Vector2i, Chunk] = {}
var data_unload_radius: int =5
# 玩家区块坐标，由外部每一帧写入World（World本身不持有player节点）
var player_chunk_pos:Vector2i = Vector2i.ZERO
# 保存当前已经绘制在TileMap上的区块
var rendered_chunks:Dictionary = {}

func _init(p_seed) -> void:
	seed = p_seed
	terrain_generator = TerrainGenerator.new(seed)
	
## 【全局读方块入口】整个游戏读取方块统一调用这个
## world_tile_pos：全局瓦片坐标（一格=32像素）
## 这里用区块算的
func get_tile(world_tile_pos: Vector2i) -> TileCell:
	# 1. 全局瓦片坐标 → 换算成【区块坐标】+【区块内局部坐标】
	var cx:int = int( floor( float(world_tile_pos.x) / Chunk.CHUNK_SIZE_X ) )
	var cy:int = int( floor( float(world_tile_pos.y) / Chunk.CHUNK_SIZE_Y ) )
	var chunk_pos: Vector2i = Vector2i(cx, cy)
	
	##if world_tile_pos.x < 0:
	##	DebugSystem.console_common_log("TEST", "%s" % chunk_pos)
		
	# cx,cy 是已经用floor算出来的chunk坐标
	var lx = world_tile_pos.x - cx * Chunk.CHUNK_SIZE_X
	var ly = world_tile_pos.y - cy * Chunk.CHUNK_SIZE_Y
	var local_pos = Vector2i(lx, ly)
	
	# 2. 如果区块还没加载，新建+生成原生地形
	if not loaded_chunks.has(chunk_pos):
		var new_chunk: Chunk = Chunk.new()
		new_chunk.world_chunk_pos = chunk_pos
		# 调用地形生成器，生成本区块原始地形
		var raw_terrain:Dictionary = terrain_generator.generate_chunk(chunk_pos, Chunk.CHUNK_SIZE_X, Chunk.CHUNK_SIZE_Y)
		new_chunk.original_cache = raw_terrain
		loaded_chunks[chunk_pos] = new_chunk
	
	var chunk: Chunk = loaded_chunks[chunk_pos]
	return chunk.get_cell(local_pos)

## 【全局写方块入口】挖方块、放置方块统一调用
func set_tile(world_tile_pos: Vector2i, new_cell: TileCell):
	var cx:int = int( floor( float(world_tile_pos.x) / Chunk.CHUNK_SIZE_X ) )
	var cy:int = int( floor( float(world_tile_pos.y) / Chunk.CHUNK_SIZE_Y ) )
	var chunk_pos: Vector2i = Vector2i(cx, cy)
	
	# cx,cy 是已经用floor算出来的chunk坐标
	var lx = world_tile_pos.x - cx * Chunk.CHUNK_SIZE_X
	var ly = world_tile_pos.y - cy * Chunk.CHUNK_SIZE_Y
	var local_pos = Vector2i(lx, ly)

	# 不存在这个区块，先加载生成
	if not loaded_chunks.has(chunk_pos):
		var new_chunk: Chunk = Chunk.new()
		new_chunk.world_chunk_pos = chunk_pos
		var raw_terrain:Dictionary = terrain_generator.generate_chunk(chunk_pos, Chunk.CHUNK_SIZE_X, Chunk.CHUNK_SIZE_Y)
		new_chunk.original_cache = raw_terrain
		loaded_chunks[chunk_pos] = new_chunk
	
	var chunk: Chunk = loaded_chunks[chunk_pos]
	chunk.set_cell(local_pos, new_cell)

## 直接破坏方块
func try_destroy_tile_dir(world_tile_pos: Vector2i) -> void:
	set_tile(world_tile_pos, TileCell.new(TileCellInstances.OriginalInstancesType.get("air")))
	emit_signal("tile_cell_updated", world_tile_pos)
	DebugSystem.console_common_log("世界", "方块销毁成功 %s" % str(world_tile_pos))

## 放置方块
func try_place_tile(global_tile:Vector2i, tile_cell: TileCell = TileCell.new(TileCellInstances.OriginalInstancesType.get("stone"))) -> void:
	var cell:TileCell = self.get_tile(global_tile)
	# 不能在已有固体方块上放置
	if cell != null and cell.get_cell_attribute().is_solid:
		DebugSystem.console_common_log("世界", "该位置已有方块，无法放置 %s" % str(global_tile))
		return	
	# 放置方块
	if (!tile_cell.get_cell_attribute().is_solid):
		DebugSystem.console_error_log("世界", "此类方块无法放置： 非固体")
		return 
		
	self.set_tile(global_tile, tile_cell)
	# 放置成功，发出更新信号（复用原来的tile_cell_updated）
	emit_signal("tile_cell_updated", global_tile)
	DebugSystem.console_common_log("World", "方块放置成功 %s" % global_tile)
	
## 区块卸载：远离玩家的时候调用，释放内存
func unload_chunk(chunk_pos:Vector2i):
	if loaded_chunks.has(chunk_pos):
		var chunk:Chunk = loaded_chunks[chunk_pos]
		chunk.clear_original_cache() #清空原生地形缓存，释放TileCell
		loaded_chunks.erase(chunk_pos)
		
## 批量获取区块内全部方块（给RenderBridge渲染TileMap用）
func get_chunk_all_tiles(chunk_pos:Vector2i) -> Dictionary:
	if not loaded_chunks.has(chunk_pos):
		var new_chunk: Chunk = Chunk.new()
		new_chunk.world_chunk_pos = chunk_pos
		var raw_terrain:Dictionary = terrain_generator.generate_chunk(chunk_pos, Chunk.CHUNK_SIZE_X, Chunk.CHUNK_SIZE_Y)
		new_chunk.original_cache = raw_terrain
		loaded_chunks[chunk_pos] = new_chunk
	var chunk:Chunk = loaded_chunks[chunk_pos]
	# 返回合并后的方块字典（modified覆盖original）
	var output:Dictionary = {}
	for local_x in range(Chunk.CHUNK_SIZE_X):
		for local_y in range(Chunk.CHUNK_SIZE_Y):
			var lp = Vector2i(local_x, local_y)
			output[lp] = chunk.get_cell(lp)
	return output

## 统一清理超出距离的区块数据
func prune_out_of_range_chunks():
	var to_remove:Array[Vector2i] = []
	# 遍历所有已经加载在内存的区块
	for chunk_pos in loaded_chunks:
		# 曼哈顿距离，区块坐标之间，计算距离
		var dist:int = max(abs(chunk_pos.x - player_chunk_pos.x), abs(chunk_pos.y - player_chunk_pos.y))
		if dist > data_unload_radius:
			to_remove.append(chunk_pos)
	
	# 遍历待删除列表，执行卸载
	for pos in to_remove:
		unload_chunk(pos)
