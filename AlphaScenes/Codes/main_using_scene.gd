extends Node2D

# 主节点
@export var player_instance: PlayerEntity
@export var tile_map_layer: TileMapLayer
@export var player_input_control: InputController
@export var drop_bridge: DropBridge
@export var camera: Camera2D
## 核心类(渲染器，世界)
var render_bridge: RenderBridge
var world: World
var player_chunk_pos:Vector2i
var render_distance: int = 1   # 1 = 3x3 区域，2 = 5x5 区域
## 玩家
var player_data: PlayerData
## 玩家所在区块
var is_render_ready: bool = true

# 保存当前已经绘制在TileMap上的区块
var rendered_chunks:Dictionary = {}

## 启动检查
func _ready() -> void:
	# 加载资源
	# 先加载属性再加载实例最后图集贴图
	_tile_cell_load()
	_item_load()
	TileSetBuilder.build_tileset()
	# 加载图集
	tile_map_layer.tile_set = TileSetBuilder.built_tileset
	# 创建世界
	render_bridge = RenderBridge.new(tile_map_layer)
	_load_world()
	DebugSystem.console_common_log("核心节点", "创建世界: %s" % world)
	# 注入节点给玩家控制
	player_input_control.camera = camera
	# 生成玩家
	_create_player()
	# 测试所需核心是否加载
	_debug_start()
	render_bridge.world = world
	if is_render_ready:
		_connect_signals()
		_render_around_player()
		_set_world()
		
## 瓦片加载
func _tile_cell_load() -> void:
	TileCellAttribute.reset_counter()
	TileCellAttributes.load_mapping_attributes()
	TileCellInstances.load_mapping_instance()
	
## 物品加载
func _item_load() -> void:
	ItemAttribute.reset_counter()
	ItemAttributes.load_mapping_attributes()
	ItemInstances.load_mapping_instance()

## 创建并加入玩家
func _create_player() -> void:
	# 申请世界创建实体
	var new_uid = world.get_new_uid()
	player_data = EntitySpawner.spawn_player(new_uid)
	world.add_new_entity(player_data)
	DebugSystem.console_common_log("核心节点", "创建玩家数据: %s" % player_data)
	# 同步玩家实体与数据
	player_instance.setup(player_data)
	DebugSystem.console_common_log("核心节点", "同步玩家数据: %s 到 %s" % [player_data, player_instance])

## 世界加载
func _load_world() -> void:
	world = World.new(54213)

## 世界属性设置
func _set_world() -> void:
	world.set_gravity(980.665)

## 连接信号
func _connect_signals() -> void:
	# 方块破坏
	player_input_control.block_destroy_request.connect(world.try_destroy_tile_dir)
	# 方块放置
	player_input_control.block_place_request.connect(world.try_place_tile)	
	# 信号转发(更改通知渲染)
	world.tile_cell_updated.connect(render_bridge.refresh_single_tile)
	world.gravity_updated.connect(_on_gravity_change)	
	# 连接掉落物信号
	world.drop_added.connect(drop_bridge.on_drop_added)
	world.drop_removed.connect(drop_bridge.on_drop_removed)
	world.drop_apply_force.connect(drop_bridge.on_drop_apply_force)
	drop_bridge.drop_position_updated.connect(world.receive_drop_updated_info)
	
func _physics_process(delta: float) -> void:
	if !is_render_ready:
		return
	_render_map()
	
	# 向世界提供主循环
	world.tick_world(delta, player_data.get_player_grid_pos(), player_data.get_player_global_pos())
		
## 获取玩家坐标
func get_player_global_tile_pos() -> Vector2i:
	return player_data.get_player_grid_pos()

func _render_map() -> void:
	# 1. 拿到玩家所在全局方块坐标
	var player_global_tile:Vector2i = get_player_global_tile_pos()
	var cx:int = int( floor( float(player_global_tile.x) / Chunk.CHUNK_SIZE_X ) )
	var cy:int = int( floor( float(player_global_tile.y) / Chunk.CHUNK_SIZE_Y ) )
	var new_chunk_pos = Vector2i(cx, cy)

	# 玩家区块生成
	if new_chunk_pos != player_chunk_pos:
		player_chunk_pos = new_chunk_pos
		_render_around_player()

## 渲染玩家周围的方块(范围渲染)
func _render_around_player():
	var target_chunks:Dictionary = {}
	# 1. 先算出这一帧需要的所有目标区块
	for dx in range(-render_distance, render_distance + 1):
		for dy in range(-render_distance, render_distance + 1):
			var chunk_pos = Vector2i(
				player_chunk_pos.x + dx,
				player_chunk_pos.y + dy
			)
			target_chunks[chunk_pos] = true
	
	# 2. 清除【旧有，但不在新列表】的区块
	for old_chunk in rendered_chunks:
		if !target_chunks.has(old_chunk):
			render_bridge.clear_chunk_render(old_chunk)
			rendered_chunks.erase(old_chunk)
	
	# 3. 绘制【新列表里面还没渲染的区块】
	for new_chunk in target_chunks:
		if !rendered_chunks.has(new_chunk):
			render_bridge.render_chunk(new_chunk)
			rendered_chunks[new_chunk] = true
	
	## 维护区块输出
	## DebugSystem.console_common_log("测试世界", "当前维护区块: %s" % rendered_chunks)

## 检查各项参数
func _debug_start() -> void:
	# 检查渲染桥
	if render_bridge != null:
		DebugSystem.console_common_log("核心节点", "渲染搭桥存在")
	else:
		DebugSystem.console_error_log("核心节点", "渲染搭桥不存在")
		is_render_ready = false
	if world != null:
		DebugSystem.console_common_log("核心节点", "世界本体存在")
	else:
		DebugSystem.console_error_log("核心节点", "世界本体不存在")
		is_render_ready = false
	if player_data != null:
		DebugSystem.console_common_log("核心节点", "玩家存在")
	else:
		DebugSystem.console_error_log("核心节点", "玩家不存在")
		is_render_ready = false
	## 显示渲染状态
	DebugSystem.console_common_log("核心节点", "渲染状态: %s" % is_render_ready)
		
## ========================= 核心 DI 容器全局信号 ======================
## 重力数据变更 → 调用引擎物理服务器
func _on_gravity_change(new_g:float):
	var world_2d = get_world_2d()
	if world_2d == null:
		DebugSystem.console_warn_log("核心节点: 重力", "无法获取2D世界空间")
		return
	var space_rid = world_2d.space
	PhysicsServer2D.area_set_param(space_rid, PhysicsServer2D.AREA_PARAM_GRAVITY, new_g)
	PhysicsServer2D.area_set_param(space_rid, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR, Vector2(0, 1))
	DebugSystem.console_common_log("核心节点: 重力", "设置重力: %s" % new_g)
