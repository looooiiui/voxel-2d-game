extends RefCounted
class_name World
## 方块数据发生变更时触发，携带修改的全局方块坐标
signal tile_cell_updated(global_tile_pos:Vector2i)
## 世界数据变更
signal gravity_updated(new_gravity:float)
# World对外暴露信号，DropBridge监听这一组
signal drop_added(new_drop:DropItemData)
signal drop_removed(uid:int, item: Item, remove_reason: DropManager.DropDestroyReason)
signal drop_apply_force(uid:int, absorb_force: Vector2)
signal drop_info_updated(uid: int, new_position: Vector2, linear_velocity: Vector2)
signal control_player_uid_changed(uid: int)
signal spawn_player_data(player_data: PlayerData)
## 世界属性
var seed: int
var gravity:float = 980
var world_time:float = 0.0
var drop_manager:DropManager
var entity_storage: EntityStorage
## 区块清理
var chunk_prune_timer:float = 0.0
const PRUNE_INTERVAL:float = 2 # 2秒扫描一次区块，可调整
## 区块生成器 
var terrain_generator: TerrainGenerator
## 已加载的区块 Key: 区块坐标Vector2i, value: Chunk
var loaded_chunks: Dictionary[Vector2i, Chunk] = {}
var data_unload_radius: int = 5
## 玩家区块坐标，由外部每一帧写入玩家网格坐标后计算（World本身不持有player节点）
var player_chunk_pos: Vector2i = Vector2i.ZERO
## 当前玩家控制角色uid,由世界创建给予或者网络传输赋予
var control_player_uid: int = -1

func _init(p_seed) -> void:
	seed = p_seed
	terrain_generator = TerrainGenerator.new(seed)
	DebugSystem.console_common_log("世界", "创建世界,种子: %s" % seed)
	# 创建掉落物与实例查询分配器
	drop_manager = DropManager.new()
	entity_storage = EntityStorage.new()
	DebugSystem.console_common_log("世界", "生成掉落物管理器: %s" % drop_manager)
	DebugSystem.console_common_log("世界", "生成实体分配器: %s" % entity_storage)
	
	## 内部管理器连接
	drop_info_updated.connect(drop_manager.updated_drop_info)
	_connect_inner_signal()
	
## 世界数据需要外接的计时器，本框架对接核心脚本
func tick_world(delta:float) -> void:
	var player_dict = entity_storage.get_all_players()
	# 所有玩家网格位置坐标数组
	# 所有玩家区块坐标数组
	var all_player_grid_positions:Array[Vector2i] = []
	var all_player_chunk_pos:Array[Vector2i] = []
	
	# 遍历全部玩家，收集网格坐标 + 区块坐标
	for uid in player_dict:
		var player_entity_data = player_dict[uid] as PlayerData
		var grid_pos = player_entity_data.get_player_grid_pos()
		all_player_grid_positions.append(grid_pos)
		# 算出该玩家所在区块坐标
		var chunk_pos = ChunkCoordinateUtils.grid_to_chunk(grid_pos.x, grid_pos.y, Chunk.CHUNK_SIZE_X, Chunk.CHUNK_SIZE_Y)
		all_player_chunk_pos.append(chunk_pos)
		
	drop_manager.tick(delta, world_time, player_dict)
	# ========= 区块清理计时器，现在传入【全部玩家区块数组】 =========
	chunk_prune_timer += delta
	if chunk_prune_timer >= PRUNE_INTERVAL:
		prune_out_of_range_chunks(all_player_chunk_pos)
		chunk_prune_timer = 0.0
		DebugSystem.console_common_log("世界", "执行区块卸载，世界时间: %s" % world_time)
	
	world_time += delta

## 获得新的实体 uid
func get_new_uid() -> int:
	return entity_storage.allocate_uid()	
## 添加新的实体
func add_new_entity(new_entity: EntityBase) -> void:
	entity_storage.add_entity(new_entity)
## 去除实体
func despawn_entity(uid:int, type:EntityBase.EntityType):
	entity_storage.remove_entity(uid, type)
## 返回玩家实体表
func get_player_entity_dict() -> Dictionary:
	return entity_storage.get_all_players()
## 生成玩家
func spawn_new_player() -> void:
	# 申请创建实体
	var new_uid = get_new_uid()
	var new_player_data = EntitySpawner.spawn_player(new_uid)
	add_new_entity(new_player_data)
	DebugSystem.console_common_log("世界", "创建玩家数据: %s, uid: %s" % [new_player_data, new_uid])
	# 创建玩家数据发送给外部(信号)
	if control_player_uid == -1:
		control_player_uid = new_uid
		DebugSystem.console_common_log("世界", "当前创建为本地控制玩家uid: %s, uid: %s" % [new_player_data, new_uid])
		spawn_player_data.emit(new_player_data)
		emit_signal("control_player_uid_changed", control_player_uid)
	else:
		spawn_player_data.emit(new_player_data)

## 获得当前控制玩家 Uid
func get_control_player_uid() -> int:
	return control_player_uid

func set_control_player_uid(uid:int):
	# 简单校验：实体存在才允许设置
	if entity_storage.has_player(uid):
		DebugSystem.console_common_log("世界", "修改主玩家 uid: %s 存在对应数据实体, 修改控制数据" % uid)
		control_player_uid = uid
		# 发送新控制玩家 uid 请求
		emit_signal("control_player_uid_changed", control_player_uid)
	else:
		DebugSystem.console_common_log("世界", "修改主玩家 uid: %s 不存在对应数据实体" % uid)
		
## 设置重力,通知外部世界重力发生改变
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
	var result = ChunkCoordinateUtils.grid_to_chunk_and_local(world_tile_pos.x, world_tile_pos.y, Chunk.CHUNK_SIZE_X, Chunk.CHUNK_SIZE_Y)
	var chunk_pos: Vector2i = result.chunk
	var local_pos: Vector2i = result.local
	
	##if world_tile_pos.x < 0:
	##	DebugSystem.console_common_log("TEST", "%s" % chunk_pos)
	
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
	var result = ChunkCoordinateUtils.grid_to_chunk_and_local(world_tile_pos.x, world_tile_pos.y, Chunk.CHUNK_SIZE_X, Chunk.CHUNK_SIZE_Y)
	var chunk_pos: Vector2i = result.chunk
	var local_pos: Vector2i = result.local
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
	if drop_item == null:
		return
	# drop_manager由World持有，只有World能调用spawn
	drop_manager.spawn(entity_storage.allocate_uid(), drop_item, tile_center, world_time, spawn_velocity)
	
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
	
## 统一清理超出距离的区块数据，多人位置数组
func prune_out_of_range_chunks(player_chunk_pos_list:Array[Vector2i]):
	var to_remove:Array[Vector2i] = []
	# 遍历所有已经加载在内存的逻辑区块
	for loaded_chunk_pos in loaded_chunks:
		var keep_chunk:bool = false
		# 判断：只要距离任意一名玩家在卸载半径内 → 保留区块
		for p_chunk in player_chunk_pos_list:
			var dist:int = max(abs(loaded_chunk_pos.x - p_chunk.x), abs(loaded_chunk_pos.y - p_chunk.y))
			if dist <= data_unload_radius:
				keep_chunk = true
				break
		# 所有玩家都离这个区块很远 → 标记卸载
		if not keep_chunk:
			to_remove.append(loaded_chunk_pos)
	
	# 执行卸载
	for pos in to_remove:
		unload_chunk(pos)

## 外部信号: 更新掉落物信息
func receive_drop_updated_info(in_uid: int, in_new_position: Vector2, in_linear_velocity: Vector2) -> void:
	# DebugSystem.console_common_log("世界", "收到掉落物信息: %s %s %s" % [in_uid, in_new_position, in_linear_velocity])
	drop_info_updated.emit(in_uid, in_new_position, in_linear_velocity)

## 内部信号连接
func _connect_inner_signal() -> void:
	# 注入回调：DropManager内部事件，调用World的信号发射
	drop_manager.on_drop_added.connect(_drop_added_connect)
	drop_manager.on_drop_removed.connect(_drop_removed_connect)
	drop_manager.on_drop_apply_force.connect(_drop_apply_force_connect)
	drop_manager.on_entity_add.connect(_add_drop_entity_connect)
	drop_manager.on_entity_destroy.connect(_despawn_entity_connect)
	
## World内部信号转发以及通讯
## 掉落物信号添加连接
func _drop_added_connect(new_drop:DropItemData) -> void:
	drop_added.emit(new_drop)
## 掉落物信号移除连接
func _drop_removed_connect(uid:int, item: Item, remove_reason: DropManager.DropDestroyReason) -> void:
	drop_removed.emit(uid, item, remove_reason)
## 掉落物添加力的连接
func _drop_apply_force_connect(uid:int, absorb_force: Vector2) -> void:
	drop_apply_force.emit(uid, absorb_force)
## 掉落物实体添加，由内置掉落物管理器请求
func _add_drop_entity_connect(new_drop: DropItemData) -> void:
	add_new_entity(new_drop)
## 掉落物
func _despawn_entity_connect(uid:int, type:EntityBase.EntityType) -> void:
	despawn_entity(uid, type)
