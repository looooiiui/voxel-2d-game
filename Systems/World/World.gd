extends RefCounted
class_name World

## 方块数据发生变更时触发，携带修改的全局方块坐标
signal tile_cell_updated(global_tile_pos:Vector2i)
## 世界数据变更
signal gravity_updated(new_gravity:float)
# World对外暴露信号，DropBridge监听这一组
signal drop_added(new_drop:DropItemInstance)
signal drop_removed(uid:int)
signal drop_apply_force(uid:int, absorb_force: Vector2)

## 世界属性
var seed: int
var gravity:float = 980
var world_time:float = 0.0
var drop_manager:DropManager
# 区块清理
var chunk_prune_timer:float = 0.0
const PRUNE_INTERVAL:float = 2 # 2秒扫描一次区块，可调整

## 区块生成器 
var terrain_generator: TerrainGenerator
## 已加载的区块 Key: 区块坐标Vector2i, value: Chunk
var loaded_chunks: Dictionary[Vector2i, Chunk] = {}
var data_unload_radius: int = 5
# 玩家区块坐标，由外部每一帧写入World（World本身不持有player节点）
var player_chunk_pos:Vector2i = Vector2i.ZERO
# 保存当前已经绘制在TileMap上的区块
var rendered_chunks:Dictionary = {}

func _init(p_seed) -> void:
	seed = p_seed
	terrain_generator = TerrainGenerator.new(seed)
	DebugSystem.console_common_log("世界", "创建世界,种子: %s" % seed)

	# 创建掉落物
	drop_manager = DropManager.new()
	DebugSystem.console_common_log("世界", "生成掉落物管理器: %s" % drop_manager)
	# 注入回调：DropManager内部事件，调用World的信号发射
	drop_manager.on_drop_added = drop_added.emit
	drop_manager.on_drop_removed = drop_removed.emit
	drop_manager.on_drop_apply_force = drop_apply_force.emit
	
## 世界数据需要外接的计时器，本框架对接核心脚本
func tick_world(delta:float, player_grid_pos:Vector2i, player_pixel_pos:Vector2) -> void:
	world_time += delta
	drop_manager.tick(delta, world_time, player_pixel_pos)
	chunk_prune_timer += delta
	
	if chunk_prune_timer >= PRUNE_INTERVAL:
		prune_out_of_range_chunks()
		chunk_prune_timer = 0.0
		DebugSystem.console_common_log("世界", "当前时间: %s" % world_time)
	
# 设置重力,通知外部世界重力发生改变
func set_gravity(new_val:float):
	if new_val < 0: return
	gravity = new_val
	DebugSystem.console_common_log("世界", "设置重力: %s" % gravity)
	emit_signal("gravity_updated", gravity)	
	
	
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

## 直接破坏方块(传入瓦片网格坐标)
func try_destroy_tile_dir(world_tile_pos: Vector2i) -> void:
	var target_tile_cell: TileCell = get_tile(world_tile_pos)
	# 没有方块或者是空气，则不销毁不返回
	if target_tile_cell == null or target_tile_cell.get_cell_attribute().tile_type_id == 0:
		DebugSystem.console_common_log("世界", "该位置无方块，无需销毁 %s" % str(world_tile_pos))
		return
		
	# 第一层，破坏方块
	set_tile(world_tile_pos, TileCell.new(TileCellInstances.OriginalInstancesType.get("air")))
	DebugSystem.console_common_log("世界", "方块销毁成功 %s" % str(world_tile_pos))
	emit_signal("tile_cell_updated", world_tile_pos)
	# 第二层，生成掉落物
	var grid_distance = CoordinateAttributes.get_coordinate_distance()	
	var tile_center = Vector2(
		world_tile_pos.x * grid_distance + grid_distance/2,
		world_tile_pos.y * grid_distance + grid_distance/2
		)
	var spawn_velocity = Vector2(0, -80)
	# 获取挖掘方块对应的物品实例
	var drop_item: Item = MappingTool.tile_instance_to_item(target_tile_cell.get_cell_instance())
	# drop_manager由World持有，只有World能调用spawn
	drop_manager.spawn(drop_item, tile_center, world_time, spawn_velocity)
	
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
	DebugSystem.console_common_log("World", "方块放置成功 %s" % global_tile)
	emit_signal("tile_cell_updated", global_tile)

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
